`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 02:44:08
// Design Name: 
// Module Name: tb_MEM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_MEM;
    reg clk, rst;
    reg [31:0] alu_result;
    reg [31:0] rs2_data;
    reg [4:0]  rd;
    reg reg_write;
    reg mem_write, mem_read, mem_reg;
    reg [31:0] ex_mem_instruction;

    wire [31:0] mem_data;
    wire [31:0] mem_alu_result;
    wire [4:0]  mem_rd;
    wire        mem_reg_write;
    wire        mem_regout;

    // Instantiating the MEM module
    MEM uut (
        .clk(clk),
        .rst(rst),
        .alu_result(alu_result),
        .rs2_data(rs2_data),
        .rd(rd),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_reg(mem_reg),
        .ex_mem_instruction(ex_mem_instruction),
        .mem_data(mem_data),
        .mem_alu_result(mem_alu_result),
        .mem_rd(mem_rd),
        .mem_reg_write(mem_reg_write),
        .mem_regout(mem_regout)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        $display("Starting MEM stage testbench...");
        
        rst = 1;
        alu_result = 32'h10;
        rs2_data = 32'hBADCAFE;
        rd = 5'd3;
        reg_write = 0;
        mem_write = 0;
        mem_read = 0;
        mem_reg = 0;
        ex_mem_instruction = 32'b0;
        #10 rst = 0;

        // Store operation
        mem_write = 1;
        mem_read = 0;
        rs2_data = 32'hABCD1234;
        alu_result = 32'h20;
        #10 mem_write = 0;

        // Load operation
        mem_read = 1;
        alu_result = 32'h20;
        #10 mem_read = 0;

        // Test no memory op (pass-through)
        alu_result = 32'hDEADBEEF;
        reg_write = 1;
        rd = 5'd15;
        mem_reg = 1;
        #10;

        $display("Finished MEM stage testbench.");
        $stop;
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0d | mem_data=%h, mem_alu_result=%h, mem_rd=%d, mem_reg_write=%b, mem_regout=%b",
                 $time, mem_data, mem_alu_result, mem_rd, mem_reg_write, mem_regout);
    end
endmodule

