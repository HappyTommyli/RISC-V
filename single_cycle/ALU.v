`timescale 1ns / 1ps 

module ALU(
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [3:0] alu_op,
    output wire zero,
    output reg signed [31:0] alu_result,
    output reg overflow
    );

    wire temp;
    assign temp = alu_result;
    wire signed [31:0] rs1temp, rs2temp;
    assign rs1temp = rs1_data;
    assign rs2temp = rs2_data;
    parameter one1 = 32'h00000001; 
    parameter zero0 = 32'h00000000;

    always @ (*) begin
        case (alu_op)
            4'b0000:begin //add
                alu_result = rs1temp + rs2temp;
                if (rs1_data[31] == 1 && rs2_data[31] == 1 && alu_result[31] == 0 || rs1_data[31] == 0 && rs2_data[31] == 0 && alu_result[31] == 1)
                    overflow = 1;
                else overflow = 0;
            end
            4'b0001:begin //sub
                alu_result = rs1_data - rs2_data;
                if (rs1_data[31] == 0 && rs2_data[31] == 1 && alu_result[31] == 1 || rs1_data[31] == 1 && rs2_data[31] == 0 && alu_result[31] == 0)
                    overflow = 1;
                else overflow = 0;
            end
            4'b1001:begin //and
                alu_result = rs1_data & rs2_data;
                overflow = 0;
            end
            4'b1000:begin //or
                alu_result = rs1_data | rs2_data;
                overflow = 0;
            end
            4'b0100:begin //sll
                alu_result = (rs1_data << rs2_data);
                overflow = 0;
            end
            4'b0010:begin //slt
                alu_result = (rs1temp < rs2temp) ? one1 : zero0;
                overflow = 0;
            end
            4'b0011:begin //sltu
                alu_result = (rs1_data < rs2_data) ? one1 : zero0;
                overflow = 0;
            end
            4'b0101:begin //xor
                alu_result = rs1_data ^ rs2_data;
                overflow = 0;
            end
            4'b0110:begin //srl
                alu_result = (rs1_data >> rs2_data);
                overflow = 0;
            end
            4'b0111:begin //sra
                alu_result = rs1temp >>> rs2_data;
                overflow = 0;
            end
            4'b1011:begin //bge
                alu_result = (rs1temp >= rs2temp) ? 1 : 0;
                overflow = 0;
            end
            default: alu_result = 32'hx;
        endcase
    end
    assign zero = (alu_result == 0) ? 1 : 0;

endmodule