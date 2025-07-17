// uart_top.sv
module uart_top #(
    parameter CLK_FREQ_HZ = 50_000_000, // ZynqのPL部クロック (50MHz)
    parameter BAUD_RATE   = 921600       // ボーレート
)(
    input  logic clk,     // クロック入力 (ZynqのPL部クロック)
    input  logic rst,     // リセット入力 (アクティブハイ)
    input  logic rx_in,   // UART RXピン (PCからの入力)
    output logic tx_out,  // UART TXピン (PCへの出力)
    
    // 新しいポートの追加
    input  logic btn1, 
    output logic[1:0] led,
    output logic [2:0] LED_123 
);

    localparam DIV_RATIO = CLK_FREQ_HZ / BAUD_RATE;

    // RXモジュールからの信号
    logic [7:0] rx_data_from_rx;
    logic       rx_busy_from_rx;
    logic       rx_valid_from_rx;
    logic       rx_err_from_rx;

    // TXモジュールへの信号
    logic [7:0] tx_data_to_tx_internal; // uart_controllerからのデータ
    logic       tx_act_to_tx_internal;  // uart_controllerからのact信号
    logic       tx_busy_from_tx_internal; // txモジュールからのbusy信号

    // uart_controllerからのLED信号
    logic       controller_led1_out; // PCコマンドによるled[0]制御信号
    logic       controller_led_tx_idle;
    logic       controller_led_tx_send;
    logic       controller_led_tx_done;

    // RXモジュールのインスタンス化
    rx #(
        .div_ratio(DIV_RATIO)
    ) i_rx (
        .clk     (clk),
        .rst     (rst),
        .rx_line (rx_in),
        .rx_data (rx_data_from_rx),
        .busy    (rx_busy_from_rx),
        .valid   (rx_valid_from_rx),
        .err     (rx_err_from_rx)
    );

    // TXモジュールのインスタンス化
    tx #(
        .div_ratio(DIV_RATIO)
    ) i_tx (
        .clk     (clk),
        .rst     (rst),
        .act     (tx_act_to_tx_internal), // uart_controllerからのact信号を使用
        .tx_data (tx_data_to_tx_internal), // uart_controllerからのデータを使用
        .tx_line (tx_out),
        .busy    (tx_busy_from_tx_internal)
    );

    // uart_controllerモジュールのインスタンス化
    uart_controller #(
        // uart_topのパラメータをuart_controllerに渡す
        .CLK_FREQ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) i_uart_controller (
        .clk              (clk),
        .rst              (rst),
        .rx_data_in       (rx_data_from_rx),
        .rx_valid_in      (rx_valid_from_rx),
        .tx_data_out      (tx_data_to_tx_internal),
        .tx_act_out       (tx_act_to_tx_internal),
        .tx_busy_in       (tx_busy_from_tx_internal),
        .btn1_in          (btn1),
        .led1_out         (controller_led1_out),      // PCコマンド制御のLED信号
        .led_tx_idle      (controller_led_tx_idle),   // STATE_IDLE 表示用
        .led_tx_send      (controller_led_tx_send),   // 送信処理中 表示用
        .led_tx_done      (controller_led_tx_done)    // STATE_DONE 表示用
    );

    // 各LEDポートへの接続
    assign led[0] = controller_led1_out; // PCコマンドで制御するLED
    assign led[1] = 1'b0;                 // led[1]は常に消灯 (必要なら他の信号に接続可能)

    assign LED_123[0] = controller_led_tx_idle;
    assign LED_123[1] = controller_led_tx_send;
    assign LED_123[2] = controller_led_tx_done;



endmodule