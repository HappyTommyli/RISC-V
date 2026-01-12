`timescale 1ns / 1ps
module ID(
input clk,
input rst,

// From IF/ID
input [31:0] if_id_pc,
input [31:0] if_id_instr,

// From MEM/WB (for writeback to Reg_File)
input wb_regwrite,
input [4:0]  wb_rd,
input [31:0] wb_data,

// Control outputs to EX/MEM/WB (from CU)
output [3:0] alu_op,
output id_alu_src,
output id_reg_write,
output id_mem_read,
output id_mem_write,
output id_mem_reg,     // mem_to_reg
//output id_branch,
//output id_jump,
//output id_jalr_enable,

output [31:0] id_ex_pc,
output [31:0] id_ex_rs1_data,
output [31:0] id_ex_rs2_data,
output [31:0] id_ex_imm,
output [4:0]  id_ex_rd,
output [31:0] id_ex_instr
);
wire [4:0] rs1_addr = if_id_instr[19:15];
wire [4:0] rs2_addr = if_id_instr[24:20];
wire [4:0] rd_addr  = if_id_instr[11:7];

//Imm
wire [31:0] imm;
imm_generator imm_gen_inst (
    .instruction(if_id_instr),
    .imm        (imm)
);

//RegFile
//CU

endmodule