module EX(
    input clk,
    input rst,
    // From ID
    input [31:0] pc,
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [31:0] imm,
    input [4:0] rd,
    input [31:0] instruction,
    input [3:0] alu_op,
    input alu_src,
    input reg_write,
    input mem_read,
    input mem_write,
    input mem_reg,
    // To MEM
    output [31:0] ex_alu_result,
    output [31:0] ex_rs2_data,
    output [4:0]  ex_rd,
    output        ex_reg_write,
    output        ex_mem_read,
    output        ex_mem_write,
    output        ex_mem_reg,
    output [31:0] ex_mem_instruction
);


endmodule