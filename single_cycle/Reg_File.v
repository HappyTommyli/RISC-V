module Reg_File (
    input wire clk,
    input wire rst,
    input reg_write,
    input [31:0] instruction,
    input [31:0] write_data, // Changed from alu_result/mem inputs to single write_data
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data
);
    wire [4:0] rs1_addr = instruction[19:15];
    wire [4:0] rs2_addr = instruction[24:20];
    wire [4:0] rd_addr = instruction[11:7];
    reg [31:0] register [0:31];
    integer i;

    // Read (Combinational)
    always @(*) begin
        rs1_data = (rs1_addr == 0) ? 0 : register[rs1_addr];
        rs2_data = (rs2_addr == 0) ? 0 : register[rs2_addr];
    end

    // Write (Sequential)
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for (i = 0; i < 32; i = i + 1) register[i] <= 0;
        end
        else if(reg_write && rd_addr != 0) begin
            register[rd_addr] <= write_data;
        end
    end
endmodule