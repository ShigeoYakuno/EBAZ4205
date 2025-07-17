module rx #(parameter div_ratio=868)(   // 100MHz/115.2kHz=868 (クロック分周比)
    input clk,                      // システムクロック
    input rst,                      // リセット信号（アクティブハイ）
    input rx_line,                  // UART RX入力ライン
    output logic [7:0]rx_data,      // 受信データ（8ビット）
    output logic busy,              // 受信中フラグ
    output logic valid,             // 受信データ有効フラグ
    output logic err                // エラーフラグ（ストップビットエラー）
    );
    
    // ============================================================================
    // 入力信号の2段フリップフロップ同期（メタステーブル対策とグリッチ抑制）
    // ============================================================================
    logic [1:0]rx_latch;
    always_ff@(posedge clk)begin
        if(rst)begin
            rx_latch <= 2'b11;         // リセット時はアイドル状態（High）
        end else begin
            rx_latch <= {rx_latch[0], rx_line};    // 2段ラッチでメタステーブル対策
        end
    end
    
    // ============================================================================
    // 受信クロック生成（ボーレート生成）
    // ============================================================================
    // 分周カウンタのビット幅を適切に設定
    // div_ratio=868の場合、0〜867をカウントするため10ビット必要
    logic [$clog2(div_ratio)-1:0] div;  // 修正：+1を削除してビット幅を適正化
    logic rx_clk;
    
    always_ff@(posedge clk) begin
        if(rst) begin               // リセット時の初期化を追加
            div <= 0;
            rx_clk <= 0;
        end else if(!busy) begin    // 受信中でない場合は分周カウンタをリセット
            div <= 0;
            rx_clk <= 0;
        end else begin
            if(div == div_ratio/2) begin        // 半周期でHigh
                rx_clk <= 1;
                div <= div + 1;
            end else if(div == div_ratio-1) begin   // 1周期でLow、カウンタリセット
                rx_clk <= 0;
                div <= 0;
            end else begin
                rx_clk <= 0;
                div <= div + 1;
            end       
        end
    end
    
    // ============================================================================
    // UART受信ステートマシン
    // ============================================================================
    logic [2:0] bitcnt;             // ビットカウンタ（0-7）
    logic [7:0] rx_buf;             // 受信バッファ
    
    // 受信ステート定義
    enum logic [1:0] {
        START,      // スタートビット検出・処理
        RECEIVE,    // データビット受信（8ビット）
        STOP        // ストップビット検証
    } state;
    
    always_ff@(posedge clk) begin
        if(rst) begin
            // リセット時の初期化
            busy <= 0;
            valid <= 0;
            err <= 0;
            rx_data <= 0;
            state <= START;
            bitcnt <= 0;            // ビットカウンタも初期化
            rx_buf <= 0;            // 受信バッファも初期化
        end else begin
            // スタートビット検出（アイドル状態でLowを検出）
            if(!busy && rx_latch[1] == 0) begin
                busy <= 1;          // 受信開始
                valid <= 0;         // 前回の有効フラグクリア
                err <= 0;           // 前回のエラーフラグクリア
            end else begin
                // 受信中かつ受信クロックの立ち上がりでステート処理
                if(busy && rx_clk) begin
                    case(state)
                        START: begin
                            // スタートビット確認（念のため再チェック）
                            if(rx_latch[1] == 0) begin
                                bitcnt <= 0;        // ビットカウンタクリア
                                state <= RECEIVE;   // データ受信ステートへ
                            end else begin
                                // スタートビットが正しくない場合（ノイズの可能性）
                                busy <= 0;
                                err <= 1;
                                state <= START;
                            end
                        end
                        
                        RECEIVE: begin
                            // データビット受信（LSBファースト）
                            rx_buf[bitcnt] <= rx_latch[1];
                            bitcnt <= bitcnt + 1;
                            
                            if(bitcnt == 7) begin   // 8ビット目（最後のビット）
                                state <= STOP;     // ストップビット検証へ
                            end
                        end
                        
                        STOP: begin
                            // ストップビット検証
                            state <= START;         // 次の受信に備えてスタートステートに戻る
                            busy <= 0;             // 受信完了
                            
                            if(rx_latch[1]) begin   // ストップビットが正しい（High）
                                valid <= 1;        // データ有効
                                err <= 0;
                                rx_data <= rx_buf;  // 受信データ出力
                            end else begin          // ストップビットエラー
                                valid <= 0;        // データ無効
                                err <= 1;          // エラー発生
                            end
                        end
                        
                        default: begin
                            // 予期しないステート（安全対策）
                            busy <= 0;
                            state <= START;
                            err <= 1;
                        end
                    endcase
                end else begin
                    // 受信クロックが立ち上がっていない場合、valid/errフラグをクリア
                    // （1クロックだけパルス出力するため）
                    valid <= 0;
                    err <= 0;
                end
            end
        end
    end
endmodule