# 50 MHz Clock definition
set_property -dict { PACKAGE_PIN M21   IOSTANDARD LVCMOS33 } [get_ports { CLOCK_50 }]; 
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# HDMI
set_property -dict { PACKAGE_PIN G2   IOSTANDARD TMDS_33 } [get_ports { HDMI_TX[2]   }];
set_property -dict { PACKAGE_PIN G1   IOSTANDARD TMDS_33 } [get_ports { HDMI_TX_N[2] }];

set_property -dict { PACKAGE_PIN F2   IOSTANDARD TMDS_33 } [get_ports { HDMI_TX[1]   }];
set_property -dict { PACKAGE_PIN E2   IOSTANDARD TMDS_33 } [get_ports { HDMI_TX_N[1] }];

set_property -dict { PACKAGE_PIN E1   IOSTANDARD TMDS_33 } [get_ports { HDMI_TX[0]   }];
set_property -dict { PACKAGE_PIN D1   IOSTANDARD TMDS_33 } [get_ports { HDMI_TX_N[0] }];

set_property -dict { PACKAGE_PIN D4   IOSTANDARD TMDS_33 } [get_ports { HDMI_CLK     }];
set_property -dict { PACKAGE_PIN C4   IOSTANDARD TMDS_33 } [get_ports { HDMI_CLK_N   }];

# Keyboard
set_property -dict { PACKAGE_PIN AC26   IOSTANDARD LVCMOS33 } [get_ports { PS2_CLOCK   }];
set_property -dict { PACKAGE_PIN AB26   IOSTANDARD LVCMOS33 } [get_ports { PS2_DATA    }];
