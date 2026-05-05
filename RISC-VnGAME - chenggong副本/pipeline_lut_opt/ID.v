`timescale 1ns / 1ps
module ID(
input clk,
input rst,
input flush,
input stall,

// From IF/ID
input [31:0] if_id_pc,
input [31:0] if_id_instr,

// From MEM/WB (for writeback to Reg_File)
input wb_regwrite,
input [4:0]  wb_rd,
input [31:0] wb_data,

// Control outputs to EX/MEM/WB (from CU)
output [3:0] id_alu_op,
output id_alu_src,
output id_alu_src1,
output id_reg_write,
output id_mem_read,
output id_mem_write,
output id_mem_reg,     // mem_to_reg
output id_branch,
output id_jump,
output id_jalr_enable,

output reg [31:0] id_ex_pc,
output reg [31:0] id_ex_rs1_data,
output reg [31:0] id_ex_rs2_data,
output reg [31:0] id_ex_imm,
output reg [4:0]  id_ex_rd,
output reg [31:0] id_ex_instr,
//
output wire        id_predicted_take,
output wire [31:0] id_branch_target
//
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

assign id_branch_target  = if_id_pc + imm;
assign id_predicted_take = id_jump | (id_branch & imm[31]); 
// static prediction: backward branches are taken
// static prediction:
// - JAL: always taken
// - Branch: backward (negative offset) = taken
// - JALR: never predicted here (we let EX resolve it)

//RegFile
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
Reg_File reg_file_inst (
    .clk        (clk),
    .rst        (rst),

    .rs1_addr   (rs1_addr),
    .rs2_addr   (rs2_addr),
    .rs1_data   (rs1_data),
    .rs2_data   (rs2_data),

    .reg_write  (wb_regwrite),
    .rd_addr    (wb_rd),
    .write_data (wb_data)
);

//CU
CU cu_inst (
    .instruction(if_id_instr),
    .reg_write  (id_reg_write),
    .mem_to_reg (id_mem_reg),
    .mem_write  (id_mem_write),
    .mem_read   (id_mem_read),
    .alu_src    (id_alu_src),
    .alu_src1   (id_alu_src1),
    .alu_op     (id_alu_op),
    .branch     (id_branch),
    .jump       (id_jump),
    .jalr_enable(id_jalr_enable),
    .csr_addr(),
    .csr_write_enable(),
    .csr_op(),
    .csr_imm(),
    .csr_funct3()
);

always @(posedge clk or posedge rst) begin
    if (rst || flush) begin
        id_ex_pc    <= 32'h00000000;
        id_ex_rs1_data   <= 32'h00000000;
        id_ex_rs2_data   <= 32'h00000000;
        id_ex_imm   <= 32'h00000000;
        id_ex_rd    <= 5'h00;
        id_ex_instr <= 32'h00000000;
    end else if (stall) begin
        id_ex_pc    <= id_ex_pc;
        id_ex_rs1_data   <= id_ex_rs1_data;
        id_ex_rs2_data   <= id_ex_rs2_data;
        id_ex_imm   <= id_ex_imm;
        id_ex_rd    <= id_ex_rd;
        id_ex_instr <= id_ex_instr;
    end else begin
        id_ex_pc    <= if_id_pc;
        id_ex_rs1_data   <= rs1_data;
        id_ex_rs2_data   <= rs2_data;
        id_ex_imm   <= imm;
        id_ex_rd    <= rd_addr;
        id_ex_instr <= if_id_instr;
    end
end
endmodule
