/* Copyright(C) 2020 Cobac.Net All Rights Reserved.   */
/* chapter: 第3章                                     */
/* project: pattern                                   */
/* outline: パターン表示回路のSim結果をファイルに出力 */

module pattern_tb2;

/* クロック周期とSimクロック数を定義 */
localparam STEP = 8;
localparam CLKNUM = (800*525+12000)*5;

/* 接続信号の宣言 */
reg             CLK;
reg             RST;
wire    [7:0]   VGA_R,  VGA_G,  VGA_B;
wire            VGA_HS, VGA_VS, VGA_DE;
wire            PCK;

/* パターン表示回路を接続 */
pattern pattern(
    .CLK    (CLK),
    .RST    (RST),
    .VGA_R  (VGA_R),
    .VGA_G  (VGA_G),
    .VGA_B  (VGA_B),
    .VGA_HS (VGA_HS),
    .VGA_VS (VGA_VS),
    .VGA_DE (VGA_DE),
    .PCK    (PCK)
);

/* クロックの生成 */
always begin
    CLK = 0; #(STEP/2);
    CLK = 1; #(STEP/2);
end

integer fd;  /* ファイル変数 */

/* 検証対象への入力を作成 */
initial begin
                RST = 0;
    fd = $fopen("imagedata.raw", "wb");
    #(STEP*600) RST = 1;
    #(STEP*20)  RST = 0;
    #(STEP*CLKNUM);
    $fclose(fd);
    $stop;
end

/* ファイル出力 */
always @(posedge PCK) begin
    if ( VGA_DE ) begin
        $fwrite(fd, "%c", VGA_R);
        $fwrite(fd, "%c", VGA_G);
        $fwrite(fd, "%c", VGA_B);
    end
end

endmodule
