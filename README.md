# RISC-V

``
https://ieeexplore.ieee.org/document/9751566
``
# pipeline_fmax.xdc
create_clock -period 10.000 -name clk [get_ports clk]   ;# 100 MHz
set_false_path -from [get_ports rst]
