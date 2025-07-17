// uart_controller.sv (改善版：'A'受信で文字列送信)
module uart_controller #(
    parameter CLK_FREQ = 50_000_000,  // システムクロック周波数 (Hz)
    parameter BAUD_RATE = 115200      // ボーレート (bps)
) (
    input  logic        clk,
    input  logic        rst,

    // UART RX側インターフェース
    input  logic [7:0]  rx_data_in,
    input  logic        rx_valid_in,

    // UART TX側インターフェース
    output logic [7:0]  tx_data_out,
    output logic        tx_act_out,
    input  logic        tx_busy_in,

    // ユーザーインターフェース
    input  logic        btn1_in,    // SW1入力
    output logic        led1_out,   // PCからのコマンド制御用LED

    // デバッグ用LED出力
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

    // 送信文字列の定義
    localparam TX_STRING_LENGTH = 8;  // 送信文字列の長さ
    logic [7:0] tx_string [TX_STRING_LENGTH-1:0]; // 送信文字列の配列

    // 送信文字列を初期化（デバッグしやすい文字に変更）
    initial begin
        tx_string[0] = 8'h48;  // 'H'
        tx_string[1] = 8'h65;  // 'e'
        tx_string[2] = 8'h6C;  // 'l'
        tx_string[3] = 8'h6C;  // 'l'
        tx_string[4] = 8'h6F;  // 'o'
        tx_string[5] = 8'h0D;  // CR
        tx_string[6] = 8'h0A;  // LF
        tx_string[7] = 8'h00;  // NULL（または別の文字）
    end

    // --- PCからのコマンド処理とイベント検出 ---
    
    // RX validの立ち上がりエッジ検出
    logic rx_valid_in_q;
    logic rx_valid_posedge;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_valid_in_q <= 1'b0;
        end else begin
            rx_valid_in_q <= rx_valid_in;
        end
    end
    assign rx_valid_posedge = rx_valid_in && !rx_valid_in_q;

    // LED制御と送信トリガー生成
    logic tx_start_trigger;  // 送信開始トリガー
    logic tx_start_trigger_q; // 送信トリガーを1クロック延長
    logic tx_start_request;   // 送信要求フラグ（ラッチ）
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            led1_out <= 1'b0;
            tx_start_trigger <= 1'b0;
            tx_start_trigger_q <= 1'b0;
            tx_start_request <= 1'b0;
        end else begin
            tx_start_trigger <= 1'b0;  // デフォルトでクリア
            tx_start_trigger_q <= tx_start_trigger; // 1クロック遅延
            
            if (rx_valid_posedge) begin
                case (rx_data_in)
                    8'h41: begin  // 'A' (ASCII 65)
                        led1_out <= 1'b1;
                        tx_start_trigger <= 1'b1;  // 文字列送信開始
                        tx_start_request <= 1'b1;  // 送信要求をラッチ
                    end
                    8'h61: begin  // 'a' (ASCII 97)
                        led1_out <= 1'b0;
                    end
                    default: ;
                endcase
            end
            
            // 送信が開始されたらリクエストフラグをクリア
            if (tx_fsm_state != STATE_IDLE) begin
                tx_start_request <= 1'b0;
            end
        end
    end
    
    // --- SW1のチャタリング除去ロジック ---
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

    // --- 送信FSMのステート定義 ---
    typedef enum logic [2:0] {
        STATE_IDLE       = 3'd0, // アイドル状態
        STATE_SET_DATA   = 3'd1, // TXモジュールにデータを与える
        STATE_ACTIVATE_TX= 3'd2, // TXモジュールに送信をトリガー
        STATE_WAIT_TX    = 3'd3, // TXモジュールが1文字送信を終えるのを待つ
        STATE_DONE       = 3'd4  // 全文字送信完了後のアイドル前ステート
    } tx_fsm_state_t;

    tx_fsm_state_t tx_fsm_state; // FSMステート
    logic [2:0] tx_char_index;   // 送信する文字のインデックス (8文字なので3ビット)
    logic [WAIT_COUNTER_WIDTH:0] tx_wait_counter; // 待機カウンタ

    // 送信データの選択（combinational logic）
    logic [7:0] tx_char_data_to_send_comb;
    always_comb begin
        if (tx_char_index < TX_STRING_LENGTH) begin
            tx_char_data_to_send_comb = tx_string[tx_char_index];
        end else begin
            tx_char_data_to_send_comb = 8'b0;
        end
    end

    // --- 送信FSMのメインロジック ---
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
                    
                    // 送信開始条件：SW1押下またはPCから'A'受信
                    // 送信中でない場合のみ新しい送信を開始
                    // 複数の条件でトリガーを検出
                    if ((btn1_posedge || tx_start_trigger || tx_start_trigger_q || tx_start_request) && !tx_busy_in) begin
                        tx_char_index <= 3'd0;           // 最初の文字から開始
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
                    tx_act_out  <= 1'b1;                     // 送信トリガーをアサート (1クロックパルス)

                    // 送信トリガー後、強制待機ステートへ遷移
                    tx_fsm_state <= STATE_WAIT_TX;
                    tx_wait_counter <= LONG_WAIT_CLKS - 1; // 待機カウンタ初期化
                end

                STATE_WAIT_TX: begin
                    tx_data_out <= tx_char_data_to_send_comb; // データはTXモジュールに保持させ続ける
                    if (tx_wait_counter == '0) begin // 指定されたクロック期間待機が完了
                        // 次の文字へ進むか、全文字送信完了か
                        if (tx_char_index == TX_STRING_LENGTH - 1) begin // 最後の文字を送信したので完了
                            tx_fsm_state  <= STATE_DONE;    // 送信完了待ちステートへ
                            tx_char_index <= 3'd0;          // インデックスをリセット
                        end else begin
                            tx_char_index <= tx_char_index + 3'd1; // 次の文字へ
                            tx_fsm_state  <= STATE_SET_DATA;       // 次の文字をセットするステートへ
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

    // --- デバッグ用LEDの駆動 ---
    assign led_tx_idle   = (tx_fsm_state == STATE_IDLE);
    // 送信処理全体で点灯
    assign led_tx_send   = (tx_fsm_state == STATE_SET_DATA || 
                            tx_fsm_state == STATE_ACTIVATE_TX || 
                            tx_fsm_state == STATE_WAIT_TX); 
    assign led_tx_done   = (tx_fsm_state == STATE_DONE);

endmodule