## Basys3 constraints template for lode_runner_basys3_top
## Configured for the on-board USB-UART bridge plus the five pushbuttons.

set_property PACKAGE_PIN W5 [get_ports clk100]
set_property IOSTANDARD LVCMOS33 [get_ports clk100]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk100]

set_property PACKAGE_PIN U17 [get_ports btnC]
set_property PACKAGE_PIN T18 [get_ports btnU]
set_property PACKAGE_PIN W19 [get_ports btnL]
set_property PACKAGE_PIN T17 [get_ports btnR]
set_property PACKAGE_PIN U18 [get_ports btnD]
set_property IOSTANDARD LVCMOS33 [get_ports {btnC btnU btnD btnL btnR}]

## Basys 3 USB-UART bridge
## `uart_tx` goes to the PC terminal, `uart_rx` is reserved for future use.
set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property PACKAGE_PIN B18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_tx uart_rx}]

## Basys3 on-board LEDs (led[15:0])
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# 啟用 Bitstream 壓縮
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# 設置 SPI Flash 加載頻率為 33MHz (加快開機速度)
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

# 設置 SPI 模式為 4 線模式 (Basys 3 支援 QSPI x4 加速)
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
