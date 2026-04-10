## Basys3 + PetGame_SoC + SSD1306 (SPI, via PMOD JA)
## Top module: PetGame_SoC
## Notes:
## - This project currently exposes 4-wire SPI only:
##   screen_sclk, screen_mosi, screen_dc, screen_cs
## - SSD1306 power pins (VCC/GND) are wired directly, not constrained in XDC.
## - If your OLED module has RES pin, tie RES to 3.3V (or extend RTL to add a reset pin).

## --------------------------------------------------------------------
## System clock (100 MHz on Basys3)
## --------------------------------------------------------------------
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## --------------------------------------------------------------------
## Reset / buttons
## --------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset]         ;# BTNC
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports {buttons[0]}]  ;# BTNU
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports {buttons[1]}]  ;# BTNL
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports {buttons[2]}]  ;# BTNR

## --------------------------------------------------------------------
## LEDs
## --------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {leds[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {leds[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {leds[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {leds[3]}]

## --------------------------------------------------------------------
## SSD1306 SPI on PMOD JA
## PMOD JA pins on Basys3:
##   JA1 = J1, JA2 = L2, JA3 = J2, JA4 = G2
## --------------------------------------------------------------------
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports screen_sclk]    ;# JA1 -> SSD1306 D0/SCLK
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports screen_mosi]    ;# JA2 -> SSD1306 D1/MOSI
set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 } [get_ports screen_dc]      ;# JA3 -> SSD1306 D/C
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports screen_cs]      ;# JA4 -> SSD1306 CS
