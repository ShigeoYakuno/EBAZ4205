/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第2章課題                            */
/* project: blinkpat                             */
/* outline: プッシュSWでLEDパターンを切り替える */

module blinkpat (
    input               CLK,
    input               RST,
    input       [0:0]   BTN,
    output  reg [2:0]   LED_123
);

// @yaku EBAZ4205 負論理 RST を正論理に変換
wire rstn = ~RST;

/* チャタリング除去回路を接続 */
wire btnon;
debounce d0 (.CLK(CLK), .RST(RST), .BTNIN(BTN), .BTNOUT(btnon));

/* LEDパターン切り替え信号 */
reg colpat;

always @( posedge CLK ) begin
    if ( rstn )
        colpat <= 1'b0;
    else if ( btnon )
        colpat <= ~colpat;
end

/* システムクロックを分周 */
reg [25:0] cnt26;

always @( posedge CLK ) begin
    if ( rstn )
        cnt26 <= 26'h0;
    else
        cnt26 <= cnt26 + 26'h1;
end

wire ledcnten = (cnt26==26'h3ffffff);

/* LED用7進カウンタ */
reg [2:0] cnt3;

always @( posedge CLK ) begin
    if ( rstn )
        cnt3 <= 3'h0;
    else if ( ledcnten )
        if ( cnt3==3'd7)
            cnt3 <=3'h0;
        else
            cnt3 <= cnt3 + 3'h1;
end

/* LEDパターンを切り替え */
wire [2:0] col0 = (colpat==1'b0) ? 3'b010: 3'b011;
wire [2:0] col1 = (colpat==1'b0) ? 3'b011: 3'b010;
wire [2:0] col2 = (colpat==1'b0) ? 3'b100: 3'b110;
wire [2:0] col3 = (colpat==1'b0) ? 3'b101: 3'b111;
wire [2:0] col4 = (colpat==1'b0) ? 3'b110: 3'b101;
wire [2:0] col5 = (colpat==1'b0) ? 3'b111: 3'b100;

/* LEDデコーダ */
always @* begin
    case ( cnt3 )
        3'd0:   LED_123 = 3'b000;
        3'd1:   LED_123 = 3'b001;
        3'd2:   LED_123 = col0;
        3'd3:   LED_123 = col1;
        3'd4:   LED_123 = col2;
        3'd5:   LED_123 = col3;
        3'd6:   LED_123 = col4;
        3'd7:   LED_123 = col5; 
        default:LED_123 = 3'b000;
    endcase
end

endmodule
