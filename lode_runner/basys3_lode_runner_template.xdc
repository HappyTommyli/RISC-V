## Basys3 constraints template for lode_runner_basys3_top
## Update OLED pin locations according to your actual wiring.

set_property PACKAGE_PIN W5 [get_ports clk100]
set_property IOSTANDARD LVCMOS33 [get_ports clk100]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk100]

set_property PACKAGE_PIN U17 [get_ports btnC]
set_property PACKAGE_PIN T18 [get_ports btnU]
set_property PACKAGE_PIN W19 [get_ports btnL]
set_property PACKAGE_PIN T17 [get_ports btnR]
set_property PACKAGE_PIN U18 [get_ports btnD]
set_property IOSTANDARD LVCMOS33 [get_ports {btnC btnU btnD btnL btnR}]

## Example: map OLED signals to PMOD JA pins (edit these as needed)
## JA1/J1, JA2/L2, JA3/J2, JA4/G2 on many Basys3 pin maps
set_property PACKAGE_PIN J1 [get_ports oled_sclk]
set_property PACKAGE_PIN L2 [get_ports oled_mosi]
set_property PACKAGE_PIN J2 [get_ports oled_dc]
set_property PACKAGE_PIN G2 [get_ports oled_cs]
set_property IOSTANDARD LVCMOS33 [get_ports {oled_sclk oled_mosi oled_dc oled_cs}]
