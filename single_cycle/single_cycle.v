// PC
reg  clk;
reg  rst;
reg [31:0] next_pc;
reg [31:0] pc_address;

//PC_Update
reg [31:0] rs1_data;
reg jump;
reg branch;
reg [31:0] pc_address;
reg [31:0] imm;
reg zero;
reg [31:0] next_pc;

//mux1&2
reg [31:0] in0;
reg [31:0] in1;
reg  ctrl;
reg [31:0] out;

//inst_mem
reg [31:0] pc_address;
reg  clk;
reg [31:0] instruction;

//imm_gen
reg [31:0] instruction;
reg [31:0] imm;

//data_mem
reg clk;
reg mem_read;
reg mem_write;
reg [31:0] rs2_data;
reg [31:0] alu_result;
reg [31:0] instruction;
reg [31:0] data_mem_data;

//cu
reg [31:0] instruction;
reg reg_write;
reg mem_to_reg;
reg mem_write;
reg mem_read;
reg alu_src;
reg [3:0] alu_op;
reg branch;
reg jump;
reg [11:0] csr_addr;
reg csr_write_enable;
reg [1:0] csr_op;
reg [4:0] csr_imm;
//csr_reg
reg  clk;
reg  rst;
reg [11:0] csr_addr;
reg  csr_write_enable;
reg [1:0] csr_op;
reg [2:0] csr_funct3;
reg [31:0] rs1_data;
reg [4:0] csr_imm;
reg [31:0] csr_rdata;


//alu
reg [31:0] rs1_data;
reg [31:0] rs2_data;
reg [3:0] alu_op;
reg  zero;
reg [31:0] alu_result;
reg overflow;



pc  pc_inst (
      .clk(clk),
      .rst(rst),
      .next_pc(next_pc),
      .pc_address(pc_address)
    );

PC_update  PC_update_inst (
             .rs1_data(rs1_data),
             .jump(jump),
             .branch(branch),
             .pc_address(pc_address),
             .imm(imm),
             .zero(zero),
             .next_pc(next_pc)
           );

mux  mux_inst_1 (
       .in0(in0),
       .in1(in1),
       .ctrl(ctrl),
       .out(out)
     );

mux  mux_inst_2 (
       .in0(in0),
       .in1(in1),
       .ctrl(ctrl),
       .out(out)
     );

inst_mem  inst_mem_inst (
            .pc_address(pc_address),
            .clk(clk),
            .instruction(instruction)
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
      .jump(jump),
      .csr_addr(csr_addr),
      .csr_write_enable(csr_write_enable),
      .csr_op(csr_op),
      .csr_imm(csr_imm)
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
       .rs2_data(rs2_data),
       .alu_op(alu_op),
       .zero(zero),
       .alu_result(alu_result),
       .overflow(overflow)
     );
