module PC_update (
    input [31:0] rs1_data,
    input jump,
    input branch,
    input [31:0]pc_address,
    input [31:0]imm,
    input zero,
    output reg [31:0]next_pc
  );

  always @( *)
  begin
    if (jump)
    begin
      next_pc = pc_address + imm;
    end

    else if (branch && zero)
    begin
      next_pc = pc_address + imm;
    end

    else
    begin
      next_pc = pc_address + 32'b100; //PC+4
    end

  end


endmodule
