module Reg_File (
input wire clk,
input wire rst,

// read ports (ID stage)
input wire [4:0] rs1_addr,
input wire [4:0] rs2_addr,
output reg [31:0] rs1_data,
output reg [31:0] rs2_data,

// write port (WB stage)
input wire reg_write,
input wire [4:0] rd_addr,
input wire [31:0] write_data,

);
endmodule