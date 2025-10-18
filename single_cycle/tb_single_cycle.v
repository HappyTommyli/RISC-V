`timescale 1ns / 1ps

module tb_singlecycle();

reg clk;
reg rst;

wire [31:0] pc_address;
wire [31:0] instruction;
wire [31:0] rs1_data;
wire [31:0] rs2_data;
wire [31:0] alu_result;
wire [31:0] data_mem_data;
wire zero;
wire reg_write;

singlecycle uut (
    .clk(clk),
    .rst(rst)
);

assign pc_address = uut.pc_address;
assign instruction = uut.instruction;
assign rs1_data = uut.rs1_data;
assign rs2_data = uut.rs2_data;
assign alu_result = uut.alu_result;
assign data_mem_data = uut.data_mem_data;
assign zero = uut.zero;
assign reg_write = uut.reg_write;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1;
    #20;
    rst = 0;
    #100;
    $display("Test completed!");
    $finish;
end

initial begin
    $monitor("Time = %0t, PC = 0x%08h, Inst = 0x%08h, rs1 = 0x%08h, rs2 = 0x%08h, ALU_Res = 0x%08h, Zero = %b, RegWrite = %b", $time, pc_address, instruction, rs1_data, rs2_data, alu_result, zero, reg_write);
end

endmodule
