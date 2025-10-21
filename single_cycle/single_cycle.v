`timescale 1ns / 1ps

module SingleCycle_RISCV (
    input wire clk,  // System clock
    input wire rst   // Global reset
  );
  // PC
  wire [31:0] next_pc;
  wire [31:0] pc_address;
  wire [31:0] rs1_data;
  wire jump;
  wire jalr_enable;
  wire branch;
  wire [31:0] imm;
  wire zero;
  wire [31:0] instruction;
  wire mem_read;
  wire mem_write;
  wire [31:0] rs2_data;
  wire [31:0] alu_result;
  wire [31:0] data_mem_data;
  wire reg_write;
  wire mem_to_reg;
  wire alu_src;
  wire [3:0] alu_op;
  wire [11:0] csr_addr;
  wire csr_write_enable;
  wire [1:0] csr_op;
  wire [4:0] csr_imm;
  wire [2:0] csr_funct3;
  wire [31:0] csr_rdata;
  wire overflow;
  wire [31:0]wirteback_data;



  pc  pc_inst (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc_address(pc_address)
      );

  PC_update  PC_update_inst (
               .rs1_data(rs1_data),
               .jump(jump),
               .jalr_enable(jalr_enable),
               .branch(branch),
               .pc_address(pc_address),
               .imm(imm),
               .zero(zero),
               .next_pc(next_pc)
             );

  mux  mux_alu(
         .in0(rs2_data),
         .in1(imm),
         .ctrl(alu_src),
         .out(wirteback_data)
       );


//     inst_mem  inst_mem_inst (
//                 .pc_address(pc_address),
//                 .clk(clk),
//                 .instruction(instruction)
//               );

  blk_mem_gen_0 instruction_memory (
                  .clka  (clk),       // 时钟信号，与CPU时钟同步
                  .ena   (1'b1),      // 使能信号：始终有效（1'b1）
                  .addra ({2'b0,pc_address[31:2]}),        // 地址输入：连接程序计数器PC
                  .douta (instruction)// 指令输出：连接到CPU的指令译码模块
                );

  imm_generator  imm_generator_inst (
                   .instruction(instruction),
                   .imm(imm)
                 );

  Data_Memory  Data_Memory_inst (
                 .clk(clk),
                 .mem_read(mem_read),
                 .mem_write(mem_write),
                 .rs2_data(rs2_data),
                 .alu_result(alu_result),
                 .instruction(instruction),
                 .data_mem_data(data_mem_data)
               );

  CU  CU_inst (
        .instruction(instruction),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .branch(branch),
        .jalr_enable(jalr_enable),
        .jump(jump),
        .csr_addr(csr_addr),
        .csr_write_enable(csr_write_enable),
        .csr_op(csr_op),
        .csr_imm(csr_imm),
        .csr_funct3(csr_funct3)
      );

  csr_reg  csr_reg_inst (
             .clk(clk),
             .rst(rst),
             .csr_addr(csr_addr),
             .csr_write_enable(csr_write_enable),
             .csr_op(csr_op),
             .csr_funct3(csr_funct3),
             .rs1_data(rs1_data),
             .csr_imm(csr_imm),
             .csr_rdata(csr_rdata)
           );

  ALU  ALU_inst (
         .rs1_data(rs1_data),
         .rs2_data(wirteback_data),
         .alu_op(alu_op),
         .zero(zero),
         .alu_result(alu_result),
         .overflow(overflow)
       );

  Reg_File  Reg_File_inst (
              .clk(clk),
              .rst(rst),
              .reg_write(reg_write),
              .instruction(instruction),
              .alu_result(alu_result),
              .mem_to_reg(mem_to_reg),
              .data_mem_data(data_mem_data),
              .rs1_data(rs1_data),
              .rs2_data(rs2_data)
            );
endmodule
/**
`timescale 1ns / 1ps
 
module SingleCycle_RISCV (
    input wire clk,  // System clock 
    input wire rst   // Global reset 
);
 
wire [31:0] pc_address;   // Current PC (from pc module)
wire [31:0] next_pc;      // Next PC (from PC_update)
wire [31:0] instruction;  // Current instruction (from inst_mem)
wire [31:0] imm;          // Extended immediate (from imm_generator)
wire reg_write;           // Reg_File write enable
wire mem_to_reg;          // Writeback: 1=DRAM data, 0=ALU data
wire mem_write;           // Data_Memory write enable
wire mem_read;            // Data_Memory read enable
wire alu_src;             // ALU 2nd operand: 1=imm, 0=rs2_data
wire [3:0] alu_op;        // ALU operation code
wire branch;              // Branch instruction flag
wire jump;                // Jump instruction flag
wire jalr_enable;         // JALR enable (distinguish from JAL)
wire [11:0] csr_addr;     // CSR address
wire csr_write_enable;    // CSR write enable
wire [1:0] csr_op;        // CSR operation type
wire [4:0] csr_imm;       // CSR 5-bit immediate
wire [2:0] csr_funct3;    // CSR funct3 (for immediate variants)
wire [31:0] rs1_data;     // rs1 data (from Reg_File)
wire [31:0] rs2_data;     // rs2 data (from Reg_File)
wire [31:0] writeback_data;// Data to write to Reg_File (from writeback_mux)
wire [31:0] alu_operand2; // ALU 2nd operand (from alu_mux)
wire [31:0] alu_result;   // ALU computation result
wire zero;                // ALU zero flag (for branch condition)
wire [31:0] data_mem_data;// Data read from Data_Memory
wire [31:0] csr_rdata;    // Data read from CSR (for writeback)
 
pc u_pc (
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .pc_address(pc_address)
);
 
inst_mem u_inst_mem (
    .pc_address(pc_address),
    .clk(clk),
    .instruction(instruction)
);
 
imm_generator u_imm_generator (
    .instruction(instruction),
    .imm(imm)
);
 
CU uuu_cu (
    .instruction(instruction),
    .reg_write(reg_write),
    .mem_to_reg(mem_to_reg),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .alu_src(alu_src),
    .alu_op(alu_op),
    .branch(branch),
    .jump(jump),
    .jalr_enable(jalr_enable),  // Connect JALR enable
    .csr_addr(csr_addr),
    .csr_write_enable(csr_write_enable),
    .csr_op(csr_op),
    .csr_imm(csr_imm),
    .csr_funct3(csr_funct3)
);
 
Reg_File uuu_reg_file (
    .clk(clk),
    .rst(rst),
    .reg_write(reg_write),
    .instruction(instruction),
    .writeback_data(writeback_data),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);
 
mux uuu_alu_mux (
    .in0(rs2_data),
    .in1(imm),
    .ctrl(alu_src),
    .out(alu_operand2)
);
 
ALU uuu_alu (
    .rs1_data(rs1_data),
    .rs2_data(alu_operand2),  // Connect to mux output
    .alu_op(alu_op),
    .zero(zero),
    .alu_result(alu_result),
    .overflow()  // Unused in basic design
);
 
Data_Memory uuu_data_mem (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .rs2_data(rs2_data),  // Data to write to DRAM
    .alu_result(alu_result),  // DRAM address (from ALU)
    .instruction(instruction),  // For funct3 (LB/LH/LW/SB/SH/SW)
    .data_mem_data(data_mem_data)
);
 
csr_reg uuu_csr_reg (
    .clk(clk),
    .rst(rst),
    .csr_addr(csr_addr),
    .csr_write_enable(csr_write_enable),
    .csr_op(csr_op),
    .csr_funct3(csr_funct3),
    .rs1_data(rs1_data),
    .csr_imm(csr_imm),
    .csr_rdata(csr_rdata)
);
 
 
reg [31:0] wb_mux_out;
always @(*) begin
    if (csr_write_enable) begin
        wb_mux_out = csr_rdata;  // CSR result has highest priority
    end else if (mem_to_reg) begin
        wb_mux_out = data_mem_data;  
    end else begin
        wb_mux_out = alu_result;  // ALU result 
    end
end
assign writeback_data = wb_mux_out;
 
PC_update uuu_pc_update (
    .rs1_data(rs1_data),
    .jump(jump),
    .jalr_enable(jalr_enable),
    .branch(branch),
    .pc_address(pc_address),
    .imm(imm),
    .zero(zero),
    .next_pc(next_pc)
);
 
 
endmodule
**/
