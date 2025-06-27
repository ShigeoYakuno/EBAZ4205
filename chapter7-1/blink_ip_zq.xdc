## EBAZ4205 constraints file
## chapter: 2
## project: ebaz4205_taizen

# Clock signal
set_property PACKAGE_PIN N18     [get_ports { CLK }]
set_property IOSTANDARD LVCMOS33 [get_ports { CLK }]
create_clock -add -name sys_clk_pin -period 20.000 \
        -waveform {0 10} [get_ports { CLK }]


# Reset
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { RST }]; # BTN[1]

# RGB LEDs
set_property -dict { PACKAGE_PIN H18   IOSTANDARD LVCMOS33 } [get_ports { LED_RGB[2]  }]; # Red
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { LED_RGB[1]  }]; # Green
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports { LED_RGB[0]  }]; # Blue

# Buttons
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { BTN[0] }];

# 25MHz Out
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { FCLK_CLK3 }];

# EMIO PHY
set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_RX_CLK_0]
set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_TX_CLK_0]
set_property PACKAGE_PIN U14 [get_ports ENET0_GMII_RX_CLK_0]
set_property PACKAGE_PIN U15 [get_ports ENET0_GMII_TX_CLK_0]

set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_RXD_0[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_RXD_0[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_RXD_0[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_RXD_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TX_EN_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TXD_0[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TXD_0[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TXD_0[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TXD_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_RX_DV_0]
set_property IOSTANDARD LVCMOS33 [get_ports MDIO_ETHERNET_0_0_mdc]
set_property IOSTANDARD LVCMOS33 [get_ports MDIO_ETHERNET_0_0_mdio_io]
set_property PACKAGE_PIN Y17 [get_ports {ENET0_GMII_RXD_0[3]}]
set_property PACKAGE_PIN V17 [get_ports {ENET0_GMII_RXD_0[2]}]
set_property PACKAGE_PIN V16 [get_ports {ENET0_GMII_RXD_0[1]}]
set_property PACKAGE_PIN Y16 [get_ports {ENET0_GMII_RXD_0[0]}]
set_property PACKAGE_PIN W19 [get_ports {ENET0_GMII_TX_EN_0[0]}]
set_property PACKAGE_PIN W18 [get_ports {ENET0_GMII_TXD_0[0]}]
set_property PACKAGE_PIN Y18 [get_ports {ENET0_GMII_TXD_0[1]}]
set_property PACKAGE_PIN V18 [get_ports {ENET0_GMII_TXD_0[2]}]
set_property PACKAGE_PIN Y19 [get_ports {ENET0_GMII_TXD_0[3]}]
set_property PACKAGE_PIN W15 [get_ports MDIO_ETHERNET_0_0_mdc]
set_property PACKAGE_PIN Y14 [get_ports MDIO_ETHERNET_0_0_mdio_io]
set_property PACKAGE_PIN W16 [get_ports ENET0_GMII_RX_DV_0]

