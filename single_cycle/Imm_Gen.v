module imm_generator(
    input [31:0]instruction,
    output reg [31:0]imm,
  );

  wire [6:0]op_imm = instruction [6:0];
  reg curr_type = 0;
  parameter I_TYPE = 0;
  parameter S_TYPE = 1;
  parameter B_TYPE = 2;
  parameter U_TYPE = 3;
  parameter J_TYPE = 4;

  always @(*)
  begin
    case (op_imm)
      7'b0010011,
      7'b0000011,
      7'b1110011,//csr
      7'b1100111:
        curr_type = I_TYPE;

      7'b0100011:
        curr_type = S_TYPE;

      7'b1100011:
        curr_type = B_TYPE;

      7'b0110111,
      7'b0010111:
        curr_type = U_TYPE;

      7'b1101111:
        curr_type = J_TYPE;

      default:
        curr_type = 0;
    endcase
  end


  always @(*)
  begin
    case (curr_type)
      I_TYPE:
        imm = {{21{instruction[31]}}, instruction[30:25], instruction[24:21], instruction[20]};
      S_TYPE:
        imm = {{21{instruction[31]}}, instruction[30:25], instruction[11:8], instruction[7]};
      B_TYPE:
        imm = {{19{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
      U_TYPE:
        imm = {instruction[31],instruction[30:20],instruction[19:12],12'b0};
      J_TYPE:
        imm= {instruction[31],instruction[19:12],instruction[20],instruction[30:25],instruction[24:21],1'b0};
      default:
        imm=32'b0;

    endcase
  end
endmodule



//  7'b0110011 R-type //add, sub, and, or
//  7'b0010011 I-type 立即数 //addi, slti, xori
//  7'b0000011 I-type 加载 // LB, LH, LW, LBU, LHU
//  7'b1100111 I-type 跳转 //jalr
//  7'b0100011 S-type 储存 //sw, sb, sh
//  7'b1100011 B-type分支 //beq, bne, blt
//  7'b0110111 U-type 加载高位 //lui
//  7'b0010111 U-type 加至PC //auipc
//  7'b1101111 J-type 跳转 //jal
