/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第2章                                   */
/* project: debounce                                */
/* outline: プッシュスイッチ入力のチャタリング除去  */

module debounce (
    input       CLK,
    input       RST,
    input       BTNIN,
    output  reg BTNOUT
);

// 負論理 RST を正論理に変換 @yaku EBAZ4205
wire rstn = ~RST;

/* 125MHzを分周し40Hzを作成 */
reg [21:0] cnt22;

wire en40hz = (cnt22==22'd3125000-1);

always @( posedge CLK ) begin
    if ( rstn )
        cnt22 <= 22'h0;
    else if ( en40hz )
        cnt22 <= 22'h0;
    else
        cnt22 <= cnt22 + 22'h1;
end

/* スイッチ入力をFF2個で受ける */
reg ff1, ff2;

always @( posedge CLK ) begin
    if ( rstn ) begin
        ff1 <= 1'b0;
        ff2 <= 1'b0;
    end
    else if ( en40hz ) begin
        ff2 <= ff1;
        ff1 <= BTNIN;
    end
end

/* 立ち上がり検出し、FFで受ける */
wire temp = ff1 & ~ff2 & en40hz;

always @( posedge CLK ) begin
    if ( rstn )
        BTNOUT <= 1'b0;
    else
        BTNOUT <= temp;
end

endmodule
