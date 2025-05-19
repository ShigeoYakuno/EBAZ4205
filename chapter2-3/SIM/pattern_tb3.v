/* Copyright(C) 2020 Cobac.Net All Rights Reserved.        */
/* chapter: 第3章                                          */
/* project: pattern                                        */
/* outline: パターン表示回路のタイミング検証用テストベンチ */
/*          Cora Z7用                                      */

`timescale 1ns/1fs

module pattern_tb3;

/* クロック周期とSimクロック数を定義 */
localparam STEP = 8;
localparam CLKNUM = (800*525+12000)*5;

/* 接続信号の宣言 */
reg             CLK;
reg             RST;
wire    [3:0]   VGA_R,  VGA_G,  VGA_B;
wire            VGA_HS, VGA_VS;

/* パターン表示回路の最上位階層を接続 */
pattern_vga pattern_vga(
    .CLK    (CLK),
    .RST    (RST),
    .VGA_R  (VGA_R),
    .VGA_G  (VGA_G),
    .VGA_B  (VGA_B),
    .VGA_HS (VGA_HS),
    .VGA_VS (VGA_VS)
);

/* クロックの生成 */
always begin
    CLK = 0; #(STEP/2);
    CLK = 1; #(STEP/2);
end

/* 検証対象への入力を作成 */
initial begin
                RST = 0;
    #(STEP*600) RST = 1;
    #(STEP*20)  RST = 0;
    #(STEP*CLKNUM);
    $stop;
end

endmodule
