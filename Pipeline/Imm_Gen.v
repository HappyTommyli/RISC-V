module imm_generator(
    input [31:0] instruction,
    output reg [31:0] imm
);
    wire [6:0] opcode = instruction[6:0];
    // Simple logic based on opcode to select type
    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111: // I-Type
                imm = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011: // S-Type
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b1100011: // B-Type (Already shifted left by 1)
                imm = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            7'b0110111, 7'b0010111: // U-Type (Upper 20 bits)
                imm = {instruction[31:12], 12'b0};
            7'b1101111: // J-Type (Already shifted left by 1)
                imm = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            default: imm = 32'b0;
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
