module imm_generator(input wire [31:0]instruction,input wire alu_op, output reg [31:0]imm);

  parameter I_TYPE = 3'b001;
  parameter S_TYPE = 3'b010;
  parameter B_TYPE = 3'b011;
  parameter U_TYPE = 3'b100;
  parameter J_TYPE = 3'b101;


  always @(*)
  begin
    case (alu_op)
      I_TYPE:
        imm = {21{instruction[31]}, instruction[30:25], instruction[24:21], instruction[20]};
      S_TYPE:
        imm = {21{instruction[31]}, instruction[30:25], instruction[11:8], instruction[7]};
      B_TYPE:
        imm = {20{instruction[31]}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
      U_TYPE:
        imm = {instruction[31],instruction[30:20],instruction[19:12],12'b0};
      J_TYPE:
        imm= {instruction[31],instruction[19:12],instruction[20],instruction[30:25],instruction[24:21],1'b0};
      default:
        imm=32'b0;

    endcase
  end
endmodule
