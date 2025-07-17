// tx.sv (改善版)
// UART送信モジュール
// 機能: 8N1フォーマット（8データビット、パリティなし、1ストップビット）でデータを送信
module tx #(
    parameter int div_ratio = 434 // ボーレート分周比 (例: 50MHz / 115200bps = 434.02...)
)(
    input  logic       clk,     // システムクロック
    input  logic       rst,     // 非同期リセット（アクティブハイ）
    input  logic       act,     // 送信開始トリガー（1クロックパルス）
    input  logic [7:0] tx_data, // 送信する8bitデータ
    output logic       tx_line, // UART TX出力ライン
    output logic       busy     // 送信中状態信号（1=送信中、0=アイドル）
);

    // ステート定義
    typedef enum logic [2:0] {
        IDLE    = 3'd0,  // アイドル状態（送信待機）
        START   = 3'd1,  // スタートビット送信
        DATA    = 3'd2,  // データビット送信
        STOP    = 3'd3,  // ストップビット送信
        FINISH  = 3'd4   // 送信完了（busyクリア用）
    } state_t;

    // 内部信号定義
    state_t state;                      // 現在のステート
    logic [3:0] bit_cnt;                // ビットカウンタ（0:Start, 1-8:Data, 9:Stop）
    logic [$clog2(div_ratio):0] div_cnt; // ボーレート分周カウンタ
    logic [7:0] s_tx_data;              // シフトレジスタ（送信データ）
    logic       tx_line_reg;            // tx_line出力用レジスタ
    logic       busy_reg;               // busy信号用レジスタ

    // ボーレート分周カウンタの最大値
    localparam logic [$clog2(div_ratio):0] DIV_MAX = div_ratio - 1;

    // busy信号制御ロジック
    // 送信開始時にセット、送信完了時にクリア
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            busy_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (act) begin
                        busy_reg <= 1'b1;  // 送信開始でビジー状態セット
                    end
                end
                FINISH: begin
                    busy_reg <= 1'b0;      // 送信完了でビジー状態クリア
                end
                default: begin
                    // その他のステートでは値を保持
                end
            endcase
        end
    end
    assign busy = busy_reg;

    // メインステートマシン
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // リセット時の初期化
            state       <= IDLE;
            bit_cnt     <= 4'd0;
            div_cnt     <= DIV_MAX;
            s_tx_data   <= 8'd0;
            tx_line_reg <= 1'b1;           // UARTアイドル状態はHigh
        end else begin
            case (state)
                IDLE: begin
                    // アイドル状態：送信待機
                    tx_line_reg <= 1'b1;   // アイドル状態はHigh
                    if (act) begin
                        // 送信開始要求を受信
                        state     <= START;
                        bit_cnt   <= 4'd0;
                        div_cnt   <= DIV_MAX;
                        s_tx_data <= tx_data; // 送信データをラッチ
                    end
                end

                START: begin
                    // スタートビット送信（Low出力）
                    tx_line_reg <= 1'b0;
                    if (div_cnt == 0) begin
                        // 1ビット期間経過：データビット送信へ遷移
                        state   <= DATA;
                        bit_cnt <= 4'd1;      // 最初のデータビット
                        div_cnt <= DIV_MAX;
                    end else begin
                        div_cnt <= div_cnt - 1;
                    end
                end

                DATA: begin
                    // データビット送信（LSBファースト）
                    tx_line_reg <= s_tx_data[0];
                    if (div_cnt == 0) begin
                        // 1ビット期間経過
                        s_tx_data <= s_tx_data >> 1; // 次のビットへシフト
                        bit_cnt   <= bit_cnt + 1;
                        div_cnt   <= DIV_MAX;
                        
                        if (bit_cnt == 4'd8) begin
                            // 8ビット全て送信完了：ストップビットへ
                            state <= STOP;
                        end
                    end else begin
                        div_cnt <= div_cnt - 1;
                    end
                end

                STOP: begin
                    // ストップビット送信（High出力）
                    tx_line_reg <= 1'b1;
                    if (div_cnt == 0) begin
                        // 1ビット期間経過：送信完了
                        state   <= FINISH;
                        div_cnt <= DIV_MAX;
                    end else begin
                        div_cnt <= div_cnt - 1;
                    end
                end

                FINISH: begin
                    // 送信完了状態：すぐにアイドルに戻る
                    tx_line_reg <= 1'b1;
                    state       <= IDLE;
                    bit_cnt     <= 4'd0;
                end

                default: begin
                    // 未定義ステート：安全のためアイドルに戻る
                    state       <= IDLE;
                    tx_line_reg <= 1'b1;
                    bit_cnt     <= 4'd0;
                    div_cnt     <= DIV_MAX;
                end
            endcase
        end
    end

    // 出力ポートへの接続
    assign tx_line = tx_line_reg;

    // アサーション（シミュレーション用）
    `ifdef SIMULATION
        // 送信中はactが再度アサートされないことを確認
        assert property (@(posedge clk) disable iff (rst)
            busy |-> !act) else $error("Act asserted while busy");
            
        // div_ratioが正の値であることを確認
        initial begin
            assert (div_ratio > 0) else $fatal("div_ratio must be positive");
        end
    `endif

endmodule