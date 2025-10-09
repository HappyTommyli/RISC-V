
module CU_tb;

  // Parameters

  //Ports
  reg [31:0] instruction;
  wire reg_write;
  wire mem_to_reg;
  wire mem_write;
  wire mem_read;
  wire alu_src;
  wire [3:0] alu_op;
  wire branch;
  wire jump;
  wire jalr_enable;
  wire [11:0] csr_addr;
  wire csr_write_enable;
  wire [1:0] csr_op;
  wire [4:0] csr_imm;
  wire [2:0] csr_funct3;

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
    .jalr_enable(jalr_enable),
    .csr_addr(csr_addr),
    .csr_write_enable(csr_write_enable),
    .csr_op(csr_op),
    .csr_imm(csr_imm),
    .csr_funct3(csr_funct3)
  );

//always #5  clk = ! clk ;

endmodule
