/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 2-2                           */
/* project: blinkspeed                      */

module blinkspeed (
    input               CLK,
    input               RST,
    input       [0:0]   BTN,
    output  reg [1:0]   LED_RGB
);

/* Chattering elimination */
wire btnon;

debounce d0 (.CLK(CLK), .RST(RST), .BTNIN(BTN), .BTNOUT(btnon));

/* Speed ??setting counter */
reg [1:0] speed;

always @( posedge CLK ) begin
    if ( RST )
        speed <= 2'h0;
    else if ( btnon )
        speed <= speed + 2'h1;
end

/* Divide the system clock */
reg [26:0] cnt27;

always @( posedge CLK ) begin
    if ( RST )
        cnt27 <= 27'h0;
    else
        cnt27 <= cnt27 + 27'h1;
end

/* Create an LED counter */
reg ledcnten;

always @* begin
    case ( speed )
        2'h0:   ledcnten = (cnt27      ==27'h7ffffff);
        2'h1:   ledcnten = (cnt27[25:0]==26'h3ffffff);
        2'h2:   ledcnten = (cnt27[24:0]==25'h1ffffff);
        2'h3:   ledcnten = (cnt27[23:0]==24'hffffff);
        default ledcnten = 1'b0;
    endcase
end

/* 5-ary counter for LED */
reg [2:0] cnt3;

always @( posedge CLK ) begin
    if ( RST )
        cnt3 <= 3'h0;
    else if ( ledcnten )
        if ( cnt3==3'd5)
            cnt3 <=3'h0;
        else
            cnt3 <= cnt3 + 3'h1;
end

/* LED Decoder */
always @* begin
    case ( cnt3 )
        3'd0:   LED_RGB = ~2'b01;//G
        3'd1:   LED_RGB = ~2'b10;//R
        3'd2:   LED_RGB = ~2'b01;//G
        3'd3:   LED_RGB = ~2'b10;//R
        3'd4:   LED_RGB = ~2'b11;//GR
        3'd5:   LED_RGB = ~2'b00;//off
        default:LED_RGB = ~2'b00;
    endcase
end

endmodule
