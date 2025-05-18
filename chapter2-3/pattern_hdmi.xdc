## EBAZ4205 constraints file
## chapter: 2
## project: pattern_hdmi

# Clock signal
set_property PACKAGE_PIN N18     [get_ports { CLK }]
set_property IOSTANDARD LVCMOS33 [get_ports { CLK }]
create_clock -add -name sys_clk_pin -period 20.000 \
        -waveform {0 10} [get_ports { CLK }]

# Reset K3
set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33 } \
        [get_ports { RST }]; 

# speed change K1
set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } \
        [get_ports { BTN }]; 

# LED123
set_property -dict { PACKAGE_PIN H18   IOSTANDARD LVCMOS33 } \
        [get_ports { LED_123[2] }]; # LED3
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } \
        [get_ports { LED_123[1] }]; # LED2
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } \
        [get_ports { LED_123[0] }]; # LED1

#HDMI TX
set_property -dict { PACKAGE_PIN F20   IOSTANDARD TMDS_33  } [get_ports { HDMI_CLK_N }];
set_property -dict { PACKAGE_PIN F19   IOSTANDARD TMDS_33  } [get_ports { HDMI_CLK_P }];
set_property -dict { PACKAGE_PIN D20   IOSTANDARD TMDS_33  } [get_ports { HDMI_N[0] }];
set_property -dict { PACKAGE_PIN D19   IOSTANDARD TMDS_33  } [get_ports { HDMI_P[0] }];
set_property -dict { PACKAGE_PIN B20   IOSTANDARD TMDS_33  } [get_ports { HDMI_N[1] }];
set_property -dict { PACKAGE_PIN C20   IOSTANDARD TMDS_33  } [get_ports { HDMI_P[1] }];
set_property -dict { PACKAGE_PIN A20   IOSTANDARD TMDS_33  } [get_ports { HDMI_N[2] }];
set_property -dict { PACKAGE_PIN B19   IOSTANDARD TMDS_33  } [get_ports { HDMI_P[2] }];
