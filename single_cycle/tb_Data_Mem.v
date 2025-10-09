`timescale 1ns / 1ps

module Data_Memory_tb;

    reg clk;
    reg mem_read;
    reg mem_write;
    reg [31:0] rs2_data;
    reg [31:0] alu_result;
    reg [31:0] instruction;

    wire [31:0] data_mem_data;

    Data_Memory uut (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .rs2_data(rs2_data),
        .alu_result(alu_result),
        .instruction(instruction),
        .data_mem_data(data_mem_data)
    );

    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns 周期的时钟
    end

    // 测试过程
    initial begin
        // 初始化输入
        mem_read = 0;
        mem_write = 0;
        rs2_data = 32'h0;
        alu_result = 32'h0;
        instruction = 32'h0;

        #10;

        // 测试 sb（存储字节）
        mem_write = 1;
        mem_read = 0;
        rs2_data = 32'hA5;
        alu_result = 32'h0;
        instruction = 32'h00000000; // funct3 = 3'b000
        #10;
        mem_write = 0;

        #10;
        // 测试 lb（加载字节，有符号）
        mem_read = 1;
        mem_write = 0;
        alu_result = 32'h0;
        instruction = 32'h00000000; // funct3 = 3'b000
        #10;
        $display("lb result: %h", data_mem_data);
        mem_read = 0;

        #10;
        // 测试 sh（存储半字）
        mem_write = 1;
        mem_read = 0;
        rs2_data = 32'hABCD;
        alu_result = 32'h4;
        instruction = 32'h00100000; // funct3 = 3'b001
        #10;
        mem_write = 0;

        #10;
        // 测试 lh（加载半字，有符号）
        mem_read = 1;
        mem_write = 0;
        alu_result = 32'h4;
        instruction = 32'h00100000; // funct3 = 3'b001
        #10;
        $display("lh result: %h", data_mem_data);
        mem_read = 0;

        #10;
        // 测试 sw（存储字）
        mem_write = 1;
        mem_read = 0;
        rs2_data = 32'h12345678;
        alu_result = 32'h8;
        instruction = 32'h01000000; // funct3 = 3'b010
        #10;
        mem_write = 0;

        #10;
        // 测试 lw（加载字）
        mem_read = 1;
        mem_write = 0;
        alu_result = 32'h8;
        instruction = 32'h01000000; // funct3 = 3'b010
        #10;
        $display("lw result: %h", data_mem_data);
        mem_read = 0;

        #10;
        // 测试 lbu（加载字节，无符号）
        mem_read = 1;
        mem_write = 0;
        alu_result = 32'h0;
        instruction = 32'h10000000; // funct3 = 3'b100
        #10;
        $display("lbu result: %h", data_mem_data);
        mem_read = 0;

        #10;
        // 测试 lhu（加载半字，无符号）
        mem_read = 1;
        mem_write = 0;
        alu_result = 32'h4;
        instruction = 32'h10100000; // funct3 = 3'b101
        #10;
        $display("lhu result: %h", data_mem_data);
        mem_read = 0;

        #10;
        $finish;
    end

endmodule