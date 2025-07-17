// tx.sv (推奨修正版)
module tx #(
    parameter div_ratio = 434 // クロック周波数 / ボーレート (例: 50MHz / 115200bps = 434.02...)
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       act,     // 送信開始トリガー (1クロックパルス)
    input  logic [7:0] tx_data, // 送信する8bitデータ
    output logic       tx_line, // UART TX出力ライン

    output logic       busy     // TXが送信中かどうかを示す信号
);

    // ステート定義
    localparam IDLE    = 3'd0;
    localparam START   = 3'd1;
    localparam DATA    = 3'd2;
    localparam STOP    = 3'd3;
    localparam FINISH  = 3'd4; // 送信完了（busyをクリアするステート）

    logic [2:0] state;
    logic [9:0] bit_cnt; // ビットカウンタ (0:Start, 1-8:Data, 9:Stop)
    logic [9:0] div_cnt; // ボーレート分周カウンタ (0からdiv_ratio-1までカウント)
    logic [7:0] s_tx_data; // シフトレジスタとして使う送信データ

    logic       tx_line_reg; // tx_lineの内部レジスタ

    // ★ busy 信号の制御ロジックを修正 (これが肝です)
    logic busy_reg; // busy信号を格納するレジスタ
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            busy_reg <= 1'b0;
        end else begin
            if (state == IDLE && act) begin // IDLEでactが来たら、送信シーケンス開始 -> busy_reg = 1
                busy_reg <= 1'b1;
            end else if (state == FINISH) begin // FINISHステートに到達したら、送信完了 -> busy_reg = 0
                busy_reg <= 1'b0;
            end
            // それ以外のステートでは busy_reg の値は変更しない (保持する)
        end
    end
    assign busy = busy_reg; // busy出力を内部レジスタに接続

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            bit_cnt     <= 10'd0;
            div_cnt     <= div_ratio - 1;
            s_tx_data   <= 8'd0;
            tx_line_reg <= 1'b1; // アイドル状態はHigh
        end else begin
            // div_cnt のデクリメントは各ステートの条件分岐内で行う
            case (state)
                IDLE: begin
                    tx_line_reg <= 1'b1; // アイドルはHigh
                    if (act) begin // actがアサートされたら送信開始
                        state     <= START;
                        bit_cnt   <= 10'd0; // スタートビットから開始
                        div_cnt   <= div_ratio - 1; // カウンタをリロード
                        s_tx_data <= tx_data; // 送信データをコピー
                    end
                end

                START: begin // スタートビット送信 (Low)
                    tx_line_reg <= 1'b0; // スタートビットはLow
                    if (div_cnt == 10'd0) begin // 1ビット期間経過
                        state   <= DATA;
                        bit_cnt <= 1; // 最初のデータビットへ (bit_cnt=0はスタートビット)
                        div_cnt <= div_ratio - 1; // カウンタをリロード
                    end else begin
                        div_cnt <= div_cnt - 1; // カウンタをデクリメント
                    end
                end

                DATA: begin // データビット送信
                    // 現在のビットを出力
                    tx_line_reg <= s_tx_data[0]; 
                    if (div_cnt == 10'd0) begin // 1ビット期間経過
                        s_tx_data <= s_tx_data >> 1; // 次のビットへシフト
                        bit_cnt   <= bit_cnt + 1; // ビットカウンタをインクリメント
                        div_cnt   <= div_ratio - 1; // カウンタをリロード
                        if (bit_cnt == 8) begin // 8ビットすべて送信済み (bit_cntは1から8まで)
                            state <= STOP; // ストップビットへ
                        end
                    end else begin
                        div_cnt <= div_cnt - 1; // カウンタをデクリメント
                    end
                end

                STOP: begin // ストップビット送信 (High)
                    tx_line_reg <= 1'b1; // ストップビットはHigh
                    if (div_cnt == 10'd0) begin // 1ビット期間経過
                        state <= FINISH; // 送信完了ステートへ
                        div_cnt <= div_ratio - 1; // カウンタをリロード
                    end else begin
                        div_cnt <= div_cnt - 1; // カウンタをデクリメント
                    end
                end

                FINISH: begin // 送信完了後の待機ステート
                    tx_line_reg <= 1'b1; // アイドル状態はHigh
                    state <= IDLE; // すぐにIDLEに戻る
                    bit_cnt <= 10'd0; // 安全対策
                end

                default: begin // 未定義ステートはIDLEへ戻す
                    state <= IDLE;
                    tx_line_reg <= 1'b1;
                    bit_cnt <= 10'd0;
                    div_cnt <= div_ratio - 1;
                end
            endcase
        end
    end

    assign tx_line = tx_line_reg; // 出力ポートに接続

endmodule