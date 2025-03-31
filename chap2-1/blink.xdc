## EBAZ4205 constraints file
## chapter: 2
## project: blink

# Clock signal
set_property PACKAGE_PIN N18     [get_ports { CLK }]
set_property IOSTANDARD LVCMOS33 [get_ports { CLK }]
create_clock -add -name sys_clk_pin -period 20.000 \
        -waveform {0 10} [get_ports { CLK }]

# Reset
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } \
        [get_ports { RST }]; # BTN[3]

# RGB LED
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } \
        [get_ports { LED_RGB[2] }]; # Red
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } \
        [get_ports { LED_RGB[1] }]; # Green
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } \
        [get_ports { LED_RGB[0] }]; # Blue
