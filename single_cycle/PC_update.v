module PC_update (
    input [31:0] rs1_data,
    input jump,
    input wire jalr_enable,  
    input branch,
    input [31:0]pc_address,
    input [31:0]imm,
    input zero,
    output reg [31:0]next_pc
  );

  wire [3:0]ctrl = {jump,jalr_enable,branch,zero};
  always @( *)
  begin
    case (ctrl)
      4'b1100, 4'b1101, 4'b1110, 4'b1111: 
            next_pc = rs1_data + imm;
        
        4'b1000, 4'b1001, 4'b1010, 4'b1011: 
            next_pc = pc_address + imm;
        
        4'b0011, 4'b0111: 
            next_pc = pc_address + {imm[30:0],1'b0};

      default: next_pc = pc_address + 32'b100;
    endcase
    // if (jump && jalr_enable)//jalr
    // begin
    //   ctrl = 1
    // end

    // else if (jump && !jalr_enable)//jal
    // begin
    //   next_pc = pc_address + imm;
    // end

    // else if (branch && zero)
    // begin
    //   next_pc = pc_address + imm;
    // end
    // else
    // begin
    //   next_pc = pc_address + 32'b100; //PC+4
    // end


  end


endmodule
