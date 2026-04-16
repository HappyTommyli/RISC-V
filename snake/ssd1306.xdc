## Clock signal (100MHz)
set_property PACKAGE_PIN W5 [get_ports clk]							
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 5} [get_ports clk]
 
## Switches
# sw0: 開始遊戲 (V17)
set_property PACKAGE_PIN V17 [get_ports sw0]					
set_property IOSTANDARD LVCMOS33 [get_ports sw0]
# rst_n: 硬體重置 (V16) - 建議往上撥為工作，往下撥為重置
set_property PACKAGE_PIN V16 [get_ports rst]					
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## Buttons (方向鍵，對應組合語言中的 bit 0~3)
# btns[0] -> Up (T18)
set_property PACKAGE_PIN T18 [get_ports {btns[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {btns[0]}]
# btns[1] -> Down (U18)
set_property PACKAGE_PIN U18 [get_ports {btns[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {btns[1]}]
# btns[2] -> Left (W19)
set_property PACKAGE_PIN W19 [get_ports {btns[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {btns[2]}]
# btns[3] -> Right (U17)
set_property PACKAGE_PIN U17 [get_ports {btns[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {btns[3]}]

## Pmod Header JA (用於 SSD1306 OLED 7-pin 介面)
## 假設你接在 JA 接口 (靠近電感那側)
# JA1 (J1) -> D0 (oled_sclk)
set_property PACKAGE_PIN J1 [get_ports oled_sclk]					
set_property IOSTANDARD LVCMOS33 [get_ports oled_sclk]
# JA2 (L2) -> D1 (oled_sdin)
set_property PACKAGE_PIN L2 [get_ports oled_sdin]					
set_property IOSTANDARD LVCMOS33 [get_ports oled_sdin]
# JA3 (J2) -> DC (oled_dc)
set_property PACKAGE_PIN J2 [get_ports oled_dc]					
set_property IOSTANDARD LVCMOS33 [get_ports oled_dc]
# JA4 (G2) -> RES (oled_res)
set_property PACKAGE_PIN G2 [get_ports oled_res]					
set_property IOSTANDARD LVCMOS33 [get_ports oled_res]
# JA7 (H1) -> CS (oled_cs) - 這是下排的第一個孔
set_property PACKAGE_PIN H1 [get_ports oled_cs]					
set_property IOSTANDARD LVCMOS33 [get_ports oled_cs]

## Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]