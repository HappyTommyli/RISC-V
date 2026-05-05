module ALU(
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [3:0] alu_op,
    output wire zero,
    output reg signed [31:0] alu_result,
    output reg overflow
);
    wire signed [31:0] rs1temp = rs1_data;
    wire signed [31:0] rs2temp = rs2_data;
    
    // Constant for comparisons
    parameter one1 = 32'h00000001;
    parameter zero0 = 32'h00000000;

    always @ (*) begin
        overflow = 0; // Default
        case (alu_op)
            4'b0000: begin // ADD
                alu_result = rs1temp + rs2temp;
                // Overflow check for signed addition
                if ((rs1_data[31] && rs2_data[31] && !alu_result[31]) || 
                    (!rs1_data[31] && !rs2_data[31] && alu_result[31]))
                    overflow = 1;
            end
            4'b0001: begin // SUB
                alu_result = rs1_data - rs2_data;
                // Overflow check for signed subtraction
                if ((!rs1_data[31] && rs2_data[31] && alu_result[31]) || 
                    (rs1_data[31] && !rs2_data[31] && !alu_result[31]))
                    overflow = 1;
            end
            4'b1001: alu_result = rs1_data & rs2_data; // AND
            4'b1000: alu_result = rs1_data | rs2_data; // OR
            4'b0100: alu_result = rs1_data << rs2_data[4:0]; // SLL [FIX: mask 5 bits]
            4'b0010: alu_result = (rs1temp < rs2temp) ? one1 : zero0; // SLT
            4'b0011: alu_result = (rs1_data < rs2_data) ? one1 : zero0; // SLTU
            4'b0101: alu_result = rs1_data ^ rs2_data; // XOR
            4'b0110: alu_result = rs1_data >> rs2_data[4:0]; // SRL [FIX: mask 5 bits]
            4'b0111: alu_result = rs1temp >>> rs2_data[4:0]; // SRA [FIX: mask 5 bits]
            4'b1011: alu_result = (rs1temp >= rs2temp) ? one1 : zero0; // BGE (Control Unit maps BGE to this)
            4'b1010: alu_result = 32'h00000000; // NO OP
            default: alu_result = 32'h00000000;
        endcase
    end
    
    assign zero = (alu_result == 0) ? 1 : 0;
endmodule