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
    input alu_src1,
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

wire is_lui = (instruction[6:0] == 7'b0110111);
wire [31:0] rs1_or_zero = is_lui ? 32'b0 : rs1_data;
wire [31:0] alu_a = (alu_src1) ? pc : rs1_or_zero;
wire [31:0] alu_b = (alu_src) ? imm : rs2_data;

wire zero;
wire signed [31:0] alu_result;
wire overflow;

ALU alu_unit(
    .rs1_data(alu_a),
    .rs2_data(alu_b),
    .alu_op(alu_op),
    .zero(zero),
    .alu_result(alu_result),
    .overflow(overflow)
);

assign ex_alu_result = alu_result;
assign ex_rs2_data = rs2_data;
assign ex_rd = rd;
assign ex_reg_write = reg_write;
assign ex_mem_read = mem_read;
assign ex_mem_write = mem_write;
assign ex_mem_reg = mem_reg;
assign ex_mem_instruction = instruction;

endmodule
