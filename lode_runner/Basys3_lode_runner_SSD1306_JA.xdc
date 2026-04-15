## Basys3 constraints for top_lode_runner_basys3

## Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 5} [get_ports CLK100MHZ]

## Buttons
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports BTN_C] ;# BTNC
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports BTN_U] ;# BTNU
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports BTN_D] ;# BTND
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports BTN_L] ;# BTNL
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports BTN_R] ;# BTNR

## LEDs
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {LED[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {LED[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {LED[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {LED[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {LED[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {LED[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {LED[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {LED[7]}]
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {LED[8]}]
set_property -dict { PACKAGE_PIN V3 IOSTANDARD LVCMOS33 } [get_ports {LED[9]}]
set_property -dict { PACKAGE_PIN W3 IOSTANDARD LVCMOS33 } [get_ports {LED[10]}]
set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports {LED[11]}]
set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS33 } [get_ports {LED[12]}]
set_property -dict { PACKAGE_PIN N3 IOSTANDARD LVCMOS33 } [get_ports {LED[13]}]
set_property -dict { PACKAGE_PIN P1 IOSTANDARD LVCMOS33 } [get_ports {LED[14]}]
set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS33 } [get_ports {LED[15]}]

## PMOD JA (SSD1306)
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports OLED_SCLK]
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports OLED_MOSI]
set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 } [get_ports OLED_DC]
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports OLED_CS]
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports OLED_RES]
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports OLED_VBAT]
set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 } [get_ports OLED_VDD]
