## Basys3 constraints for load_runner_top
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 5} [get_ports clk]

set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset] ;# BTNC

## Buttons: [0]=UP [1]=DOWN [2]=LEFT [3]=RIGHT
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports {buttons[0]}] ;# BTNU
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports {buttons[1]}] ;# BTND
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports {buttons[2]}] ;# BTNL
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports {buttons[3]}] ;# BTNR

set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {leds[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {leds[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {leds[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {leds[3]}]

## PMOD JA: SCLK, MOSI, DC, CS
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports screen_sclk]
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports screen_mosi]
set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 } [get_ports screen_dc]
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports screen_cs]
