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
  wire [31:0]writeback_data;



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
         .out(writeback_data)
       );


//     inst_mem  inst_mem_inst (
//                 .pc_address(pc_address),
//                 .clk(clk),
//                 .instruction(instruction)
//               );

  blk_mem_gen_0 instruction_memory (
                  .clka  (clk),       // 时钟信号，与CPU时钟同步
              // 使能信号：始终有效（1'b1）
                  .addra (pc_address[14:2]),        // 地址输入：连接程序计数器PC
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
         .rs2_data(writeback_data),
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
