/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第2章課題              */
/* project: gradation              */
/* outline: グラデーション表示回路 */

module gradation(
    input               CLK,
    input               RST,
    output  reg  [7:0]  VGA_R,
    output  reg  [7:0]  VGA_G,
    output  reg  [7:0]  VGA_B,
    output              VGA_HS,
    output              VGA_VS,
    output  reg         VGA_DE,
    output              PCK
);

/* VGA(640×480)用パラメータ読み込み */
`include "vga_param.vh"

localparam HSIZE = 10'd64;
localparam VSIZE = 10'd120;

/* 同期信号作成回路の接続 */
wire    [9:0]   HCNT, VCNT;

syncgen syncgen(
    .CLK    (CLK),
    .RST    (RST),
    .PCK    (PCK),
    .VGA_HS (VGA_HS),
    .VGA_VS (VGA_VS),
    .HCNT   (HCNT),
    .VCNT   (VCNT)
);

/* RGB出力を作成 */
wire [9:0] HBLANK = HFRONT + HWIDTH + HBACK;
wire [9:0] VBLANK = VFRONT + VWIDTH + VBACK;

wire disp_enable = (HBLANK-10'd1 <= HCNT) && (HCNT < HPERIOD-10'd1)
                && (VBLANK <= VCNT);
wire [9:0] hcounter = HCNT-HBLANK+10'd1;
wire [3:0] pattern  = hcounter[5:2];
wire [9:0] vcounter = (VCNT-VBLANK)/VSIZE;

reg [3:0] R, G, B;
always @* begin
    case ( vcounter )
        3'd0:   begin R = pattern; G = pattern; B = pattern; end
        3'd1:   begin R = pattern; G = 4'd0;    B = 4'd0;    end
        3'd2:   begin R = 4'd0;    G = pattern; B = 4'd0;    end
        3'd3:   begin R = 4'd0;    G = 4'd0;    B = pattern; end
        default:begin R = 4'd0;    G = 4'd0;    B = 4'd0;    end
    endcase
end

always @( posedge PCK ) begin
    if ( RST )
        {VGA_R, VGA_G, VGA_B} <= 24'h0;
    else if ( disp_enable )
        {VGA_R, VGA_G, VGA_B} <= {R, R, G, G, B, B};
    else
        {VGA_R, VGA_G, VGA_B} <= 24'h0;
end

/* disp_enableを1クロック遅らせてVGA_DEを作成 */
always @( posedge PCK ) begin
    if ( RST )
        VGA_DE <= 1'b0;
    else
        VGA_DE <= disp_enable;
end

endmodule
