module Reg_File (
input wire clk,
input wire rst,

// read ports (ID stage)
input wire [4:0] rs1_addr,
input wire [4:0] rs2_addr,
output reg [31:0] rs1_data,
output reg [31:0] rs2_data,

// write port (WB stage)
input wire reg_write,
input wire [4:0] rd_addr,
input wire [31:0] write_data
);

// Use distributed RAM for register file (saves LUTs)
(* ram_style = "distributed" *) reg [31:0] register [0:31];
integer i;

// Read (Combinational)
always @(*) begin
    if (rs1_addr == 5'd0) begin
        rs1_data = 32'h00000000;
    end
    else if (reg_write && (rd_addr == rs1_addr)) begin
        rs1_data = write_data;
    end
    else begin
        rs1_data = register[rs1_addr];
    end
    if (rs2_addr == 5'd0) begin
        rs2_data = 32'h00000000;
    end
    else if (reg_write && (rd_addr == rs2_addr)) begin
        rs2_data = write_data;
    end
    else begin
        rs2_data = register[rs2_addr];
    end
//    rs1_data = (rs1_addr == 5'd0) ? 32'h00000000 : register[rs1_addr];
//    rs2_data = (rs2_addr == 5'd0) ? 32'h00000000 : register[rs2_addr];
end

// Write (Sequential)
always @(posedge clk) begin
    if (reg_write && rd_addr != 5'd0) begin
        register[rd_addr] <= write_data;
    end
end

// Optional init for simulation (not for hardware reset)
initial begin
    for (i = 0; i < 32; i = i + 1) register[i] = 32'h00000000;
end
        
endmodule