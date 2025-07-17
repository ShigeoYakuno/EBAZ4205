// uart_controller.sv (可変ボーレート対応版)
module uart_controller #(
    parameter CLK_FREQ = 50_000_000,  // システムクロック周波数 (Hz)
    parameter BAUD_RATE = 115200      // ボーレート (bps)
) (
    input  logic        clk,
    input  logic        rst,

    // UART RX側インターフェース (省略せず記述)
    input  logic [7:0]  rx_data_in,
    input  logic        rx_valid_in,

    // UART TX側インターフェース (省略せず記述)
    output logic [7:0]  tx_data_out,
    output logic        tx_act_out,
    input  logic        tx_busy_in,

    // ユーザーインターフェース (省略せず記述)
    input  logic        btn1_in,    // SW1入力
    output logic        led1_out,   // PCからのコマンド制御用LED

    // デバッグ用LED出力 (省略せず記述)
    output logic        led_tx_idle,
    output logic        led_tx_send,
    output logic        led_tx_done
);

    // ボーレート関連の定数計算
    localparam DIV_RATIO = CLK_FREQ / BAUD_RATE;
    localparam BITS_PER_CHAR = 10;  // スタートビット + 8データビット + ストップビット
    localparam CHAR_TRANSMISSION_CYCLES = DIV_RATIO * BITS_PER_CHAR;
    
    // 1文字の送信に必要な時間
    localparam LONG_WAIT_CLKS = CHAR_TRANSMISSION_CYCLES;
    localparam WAIT_COUNTER_WIDTH = $clog2(LONG_WAIT_CLKS);

    // --- PCからのコマンド処理 (led1_out 制御) ---
    logic rx_valid_in_q;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_valid_in_q <= 1'b0;
        end else begin
            rx_valid_in_q <= rx_valid_in;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            led1_out <= 1'b0;
        end else begin
            if (rx_valid_in && !rx_valid_in_q) begin
                case (rx_data_in)
                    8'h41: led1_out <= 1'b1; // 'A'
                    8'h61: led1_out <= 1'b0; // 'a'
                    default: ;
                endcase
            end
        end
    end
    
    // SW1のチャタリング除去ロジック (前回と全く同じ)
    localparam DEBOUNCE_CNT_MAX = 50_000; 
    logic [$clog2(DEBOUNCE_CNT_MAX):0] debounce_counter; 
    logic btn1_raw_q; 
    logic btn1_stable; 

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            btn1_raw_q <= 1'b0;
            debounce_counter <= '0;
            btn1_stable <= 1'b0;
        end else begin
            btn1_raw_q <= btn1_in; 
            if (btn1_in != btn1_raw_q) begin
                debounce_counter <= '0;
            end 
            else if (debounce_counter < DEBOUNCE_CNT_MAX) begin
                debounce_counter <= debounce_counter + 1;
            end
            if (debounce_counter == DEBOUNCE_CNT_MAX) begin
                btn1_stable <= btn1_in;
            end
        end
    end

    logic btn1_stable_q; 
    logic btn1_posedge;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            btn1_stable_q <= 1'b0;
        end else begin
            btn1_stable_q <= btn1_stable;
        end
    end
    assign btn1_posedge = btn1_stable && !btn1_stable_q;

    // 送信FSMのステート定義
    localparam STATE_IDLE       = 3'd0; // アイドル状態
    localparam STATE_SET_DATA   = 3'd1; // TXモジュールにデータを与える
    localparam STATE_ACTIVATE_TX= 3'd2; // TXモジュールに送信をトリガー
    localparam STATE_WAIT_TX    = 3'd3; // TXモジュールが1文字送信を終えるのを待つ
    localparam STATE_DONE       = 3'd4; // 全文字送信完了後のアイドル前ステート

    logic [2:0] tx_fsm_state; // FSMステートのビット幅を3ビットに拡張 (4ステート以上)
    logic [2:0] tx_char_index; // 送信する文字のインデックス (8文字なので3ビット)

    logic [WAIT_COUNTER_WIDTH:0] tx_wait_counter; // 待機カウンタ

    // tx_char_data_to_send_comb は combinational logic で定義
    logic [7:0] tx_char_data_to_send_comb;
    always_comb begin
        case (tx_char_index)
            3'd0: tx_char_data_to_send_comb = 8'h5A; // 0x5A (1回目)
            3'd1: tx_char_data_to_send_comb = 8'h5A; // 0x5A (2回目)
            3'd2: tx_char_data_to_send_comb = 8'h6B; // 0x6B (1回目)
            3'd3: tx_char_data_to_send_comb = 8'h6B; // 0x6B (2回目)
            3'd4: tx_char_data_to_send_comb = 8'h7C; // 0x7C (1回目)
            3'd5: tx_char_data_to_send_comb = 8'h7C; // 0x7C (2回目)
            3'd6: tx_char_data_to_send_comb = 8'h8D; // 0x8D (1回目)
            3'd7: tx_char_data_to_send_comb = 8'h8D; // 0x8D (2回目)
            default: tx_char_data_to_send_comb = 8'b0;
        endcase
    end

    // 送信FSMのメインロジック
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_fsm_state     <= STATE_IDLE;
            tx_char_index    <= 3'd0;
            tx_act_out       <= 1'b0;    
            tx_data_out      <= 8'b0;    
            tx_wait_counter  <= '0;
        end else begin
            tx_act_out <= 1'b0; // デフォルトで送信要求をデアサート

            case (tx_fsm_state)
                STATE_IDLE: begin
                    tx_data_out <= 8'b0; // アイドル時はTXデータをクリア
                    if (btn1_posedge) begin // 安定したSW1の立ち上がりエッジ検出
                        tx_char_index <= 3'd0;           // 最初の文字 0x5A (1回目) から開始
                        tx_fsm_state  <= STATE_SET_DATA; // データセットステートへ
                    end
                end

                STATE_SET_DATA: begin
                    tx_data_out <= tx_char_data_to_send_comb; // データを出力にセット
                    // データをセットしたまま1クロック待機し、TXモジュールが確実にデータを読み込む時間を与える
                    tx_fsm_state <= STATE_ACTIVATE_TX; 
                end

                STATE_ACTIVATE_TX: begin
                    tx_data_out <= tx_char_data_to_send_comb; // データは引き続きセットしておく
                    tx_act_out  <= 1'b1;                  // 送信トリガーをアサート (1クロックパルス)

                    // 送信トリガー後、強制待機ステートへ遷移
                    tx_fsm_state <= STATE_WAIT_TX;
                    tx_wait_counter <= LONG_WAIT_CLKS - 1; // 待機カウンタ初期化
                end

                STATE_WAIT_TX: begin
                    tx_data_out <= tx_char_data_to_send_comb; // データはTXモジュールに保持させ続ける
                    if (tx_wait_counter == '0) begin // 指定されたクロック期間待機が完了
                        // 次の文字へ進むか、全文字送信完了か
                        if (tx_char_index == 3'd7) begin // 最後の文字を送信したので完了
                            tx_fsm_state  <= STATE_DONE;    // 送信完了待ちステートへ
                            tx_char_index <= 3'd0;          // インデックスをリセット
                        end else begin
                            tx_char_index <= tx_char_index + 3'd1; // 次の文字へ
                            tx_fsm_state  <= STATE_SET_DATA; // 次の文字をセットするステートへ
                        end
                    end else begin
                        tx_wait_counter <= tx_wait_counter - 1; // カウンタをデクリメント
                    end
                end

                STATE_DONE: begin // 全文字の送信要求が完了し、TXモジュールが完全にアイドルになるのを待つ
                    tx_data_out <= 8'b0; // 送信データ出力をクリア (安全のため)
                    // ここで tx_busy_in を参照する (tx.sv が正しければここで0になる)
                    if (!tx_busy_in) begin 
                        tx_fsm_state <= STATE_IDLE; 
                    end
                end

                default: begin // 未定義ステートはIDLEへ戻す (安全対策)
                    tx_fsm_state <= STATE_IDLE;
                    tx_char_index <= 3'd0;
                    tx_act_out <= 1'b0;
                    tx_data_out <= 8'b0;
                    tx_wait_counter <= '0;
                end
            endcase
        end
    end

    // デバッグ用LEDの駆動
    assign led_tx_idle   = (tx_fsm_state == STATE_IDLE);
    // 送信処理全体で点灯
    assign led_tx_send   = (tx_fsm_state == STATE_SET_DATA || tx_fsm_state == STATE_ACTIVATE_TX || tx_fsm_state == STATE_WAIT_TX); 
    assign led_tx_done   = (tx_fsm_state == STATE_DONE);

endmodule