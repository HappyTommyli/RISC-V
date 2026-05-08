## Basys3 constraints for Tetris (pipeline_lut_opt UART version)
## Update port names if your top module uses different names.

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset button (BTNC)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst]

## USB-UART (onboard FT2232)
## PC -> FPGA (RX into FPGA)
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports uart_rx]
## FPGA -> PC (TX out of FPGA)
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports uart_tx]

## Optional debug LED: game_over or heartbeat
## set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports led0]

## Optional: if you keep uart signals as valid/data/we (not serial tx/rx),
## then you still need a UART TX/RX module in top-level and map only serial pins
## (uart_rx, uart_tx) to A18/B18.
