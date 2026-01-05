module Reg_File (
    input wire clk,
    input wire rst,
    input reg_write,
    input [31:0]instruction,
    input [31:0]alu_result,
    input wire mem_to_reg,
    input [31:0]data_mem_data,
    output reg [31:0]rs1_data,
    output reg [31:0]rs2_data
  );
  wire [4:0] rs1_addr = instruction[19:15];
  wire [4:0] rs2_addr = instruction[24:20];
  wire [4:0] rd_addr  = instruction[11:7];
  reg [31:0] register [0:31];

    integer i;
    always @(posedge rst) begin
        for (i = 1; i < 32; i = i + 1) begin
            register[i] <= 32'h00000000;
        end
    end
  //read x0, always zero
      always @(*) begin
        rs1_data = (rs1_addr == 5'd0) ? 32'h00000000 : register[rs1_addr];//change register, not rs1_data
        rs2_data = (rs2_addr == 5'd0) ? 32'h00000000 : register[rs2_addr];
    end
  //write x0 not allowed
  //所以這邊always 要不要用posedge clk?
   always @(posedge clk)begin
    if(reg_write && rd_addr != 5'd0)
    begin
      register[rd_addr] <= mem_to_reg ? data_mem_data : alu_result;
    end
  end

endmodule


/**
 x0 zero Zeroconstant —
 x1 ra Returnaddress Caller
 x2 sp Stackpointer Callee
 x3 gp Globalpointer —
 x4 tp Threadpointer —
 x5-x7 t0-t2 Temporaries Caller
 x8 s0/fp Saved/framepointer Callee
 x9 s1 Savedregister Callee
 x10-x11 a0-a1 Fnargs/returnvalues Caller
 x12-x17 a2-a7 Fnargs Caller
 x18-x27 s2-s11 Savedregisters Callee
 x28-x31 t3-t6 Temporaries Caller
**/
