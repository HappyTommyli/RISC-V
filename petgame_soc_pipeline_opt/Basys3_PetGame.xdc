## Basys3 PetGame SoC constraints
## Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset button (BTNC)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset]

## Buttons (BTNU/BTNL/BTNR) -> buttons[0]/[1]/[2]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports {buttons[0]}]  ;# BTNU
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports {buttons[1]}]  ;# BTNL
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports {buttons[2]}]  ;# BTNR

## LEDs [3:0]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {leds[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {leds[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {leds[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {leds[3]}]

## Pmod JA (SPI screen)
## JA1=J1, JA2=L2, JA3=J2, JA4=G2
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports screen_sclk]
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports screen_mosi]
set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 } [get_ports screen_dc]
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports screen_cs]
