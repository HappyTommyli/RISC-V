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
output [3:0] id_alu_op,
output id_alu_src,
output id_reg_write,
output id_mem_read,
output id_mem_write,
output id_mem_reg,     // mem_to_reg
output id_branch,
output id_jump,
output id_jalr_enable,

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
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
register_file reg_file_inst (
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
    wire reg_write;
    wire mem_to_reg;
    wire mem_write;
    wire mem_read;
    wire alu_src;
    wire [3:0] alu_op;
    wire branch;
    wire jalr_enable;
    wire jump;
control_unit cu_inst (
    .instruction(if_id_instr),
    .reg_write  (reg_write),
    .mem_to_reg (id_mem_reg),
    .mem_write  (mem_write),
    .mem_read   (mem_read),
    .alu_src    (alu_src),
    .alu_op     (alu_op)
    .branch     (branch),
    .jump       (jump),
    .jalr_enable(jalr_enable),
    .csr_addr(),
    .csr_write_enable(),
    .csr_op(),
    .csr_imm(),
    .csr_funct3()
);
    assign id_reg_write = reg_write;
    assign id_mem_read = mem_read;
    assign id_mem_write = mem_write;
    assign id_mem_reg = mem_to_reg;
    assign id_alu_src = alu_src;
    assign id_alu_op = alu_op;
    assign id_branch = branch;
    assign id_jump = jump;
    assign id_jalr_enable = jalr_enable;

    reg [31:0] id_ex_pc_reg;
    reg [31:0] id_ex_rs1_reg;
    reg [31:0] id_ex_rs2_reg;
    reg [31:0] id_ex_imm_reg;
    reg [4:0] id_ex_rd_reg;
    reg [31:0] id_ex_instr_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        id_ex_pc_reg    <= 32'h00000000;
        id_ex_rs1_reg   <= 32'h00000000;
        id_ex_rs2_reg   <= 32'h00000000;
        id_ex_imm_reg   <= 32'h00000000;
        id_ex_rd_reg    <= 5'h00;
        id_ex_instr_reg <= 32'h00000000;
    end else begin
        id_ex_pc_reg    <= if_id_pc;
        id_ex_rs1_reg   <= rs1_data;
        id_ex_rs2_reg   <= rs2_data;
        id_ex_imm_reg   <= imm;
        id_ex_rd_reg    <= rd_addr;
        id_ex_instr_reg <= if_id_instr;
    end
end

    assign id_ex_pc      = id_ex_pc_reg;
    assign id_ex_rs1_data= id_ex_rs1_reg;
    assign id_ex_rs2_data= id_ex_rs2_reg;
    assign id_ex_imm     = id_ex_imm_reg;
    assign id_ex_rd      = id_ex_rd_reg;
    assign id_ex_instr   = id_ex_instr_reg;

endmodule