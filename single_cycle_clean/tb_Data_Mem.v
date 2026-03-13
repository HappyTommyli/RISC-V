`timescale 1ns / 1ps

module Data_Memory_tb;

    // 输入信号
    reg clk;
    reg mem_read;
    reg mem_write;
    reg [31:0] rs2_data;
    reg [31:0] alu_result;
    reg [31:0] instruction;  // 包含funct3字段的完整指令
    
    // 输出信号
    wire [31:0] data_mem_data;
    
    // 新增：测试计数变量
    integer pass_count;
    
    // 实例化被测试模块
    Data_Memory Data_Memory_inst (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .rs2_data(rs2_data),
        .alu_result(alu_result),
        .instruction(instruction),  // 连接完整指令
        .data_mem_data(data_mem_data)
    );
    
    // 生成时钟信号 (20ns周期，占空比50%)
    always #10 clk = ~clk;
    
    // 测试过程
    initial begin
        // 初始化
        clk = 0;
        mem_read = 0;
        mem_write = 0;
        rs2_data = 0;
        alu_result = 0;
        instruction = 0;
        pass_count = 0;  // 初始化通过计数
        
        $display("=============================================");
        $display("Starting Data Memory Testbench");
        $display("=============================================");
        
        // 等待时钟稳定
        #10;
        
        // 测试场景1: 32位字操作 (SW和LW)
        $display("\n[Test 1: 32-bit Word Operations (SW & LW)]");
        // 写入操作 (SW, funct3=010)
        @(posedge clk);
        #10;
        mem_write = 1;
        mem_read = 0;
        alu_result = 32'd0;               // 地址0
        rs2_data = 32'hA5A5A5A5;          // 要写入的数据
        instruction = 32'h0;
        instruction[14:12] = 3'b010;      // SW的funct3=010
        $display("Writing 0x%0h to address 0 with SW (funct3=010 at [14:12])", rs2_data);
        
        @(posedge clk);
        #10;
        mem_write = 0;  // 结束写入
        
        // 读取操作 (LW, funct3=010)
        @(posedge clk);
        #10;
        mem_read = 1;
        mem_write = 0;
        alu_result = 32'd0;               // 读取地址0
        instruction = 32'h0;
        instruction[14:12] = 3'b010;      // LW的funct3=010
        $display("Reading from address 0 with LW (funct3=010 at [14:12])");
        
        @(posedge clk);
        #10;
        mem_read = 0;
        // 验证结果
        if(data_mem_data == 32'hA5A5A5A5) begin
            $display("Test 1 Result: PASS - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'hA5A5A5A5);
            pass_count = pass_count + 1;  // 计数加1
        end else begin
            $display("Test 1 Result: FAIL - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'hA5A5A5A5);
        end
        
        // 测试场景2: 16位半字操作 (SH, LH, LHU)
        $display("\n[Test 2: 16-bit Halfword Operations]");
        // 写入操作 (SH, funct3=001)
        @(posedge clk);
        #10;
        mem_write = 1;
        mem_read = 0;
        alu_result = 32'd4;               // 地址4
        rs2_data = 32'h0000B3B3;          // 要写入的半字
        instruction = 32'h0;
        instruction[14:12] = 3'b001;      // SH的funct3=001
        $display("Writing 0xB3B3 to address 4 with SH (funct3=001 at [14:12])");
        
        @(posedge clk);
        #10;
        mem_write = 0;
        
        // 带符号读取 (LH, funct3=001)
        @(posedge clk);
        #10;
        mem_read = 1;
        mem_write = 0;
        alu_result = 32'd4;
        instruction = 32'h0;
        instruction[14:12] = 3'b001;      // LH的funct3=001
        $display("Reading from address 4 with LH (signed, funct3=001 at [14:12])");
        
        @(posedge clk);
        #10;
        if(data_mem_data == 32'hFFFFB3B3) begin
            $display("Test 2.1 Result: PASS - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'hFFFFB3B3);
            pass_count = pass_count + 1;  // 计数加1
        end else begin
            $display("Test 2.1 Result: FAIL - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'hFFFFB3B3);
        end
        
        // 无符号读取 (LHU, funct3=101)
        instruction = 32'h0;
        instruction[14:12] = 3'b101;      // LHU的funct3=101
        $display("Reading from address 4 with LHU (unsigned, funct3=101 at [14:12])");
        
        @(posedge clk);
        #10;
        mem_read = 0;
        if(data_mem_data == 32'h0000B3B3) begin
            $display("Test 2.2 Result: PASS - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'h0000B3B3);
            pass_count = pass_count + 1;  // 计数加1
        end else begin
            $display("Test 2.2 Result: FAIL - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'h0000B3B3);
        end
        
        // 测试场景3: 8位字节操作 (SB, LB, LBU)
        $display("\n[Test 3: 8-bit Byte Operations]");
        // 写入操作 (SB, funct3=000)
        @(posedge clk);
        #10;
        mem_write = 1;
        mem_read = 0;
        alu_result = 32'd8;               // 地址8
        rs2_data = 32'h000000C7;          // 要写入的字节
        instruction = 32'h0;
        instruction[14:12] = 3'b000;      // SB的funct3=000
        $display("Writing 0xC7 to address 8 with SB (funct3=000 at [14:12])");
        
        @(posedge clk);
        #10;
        mem_write = 0;
        
        // 带符号读取 (LB, funct3=000)
        @(posedge clk);
        #10;
        mem_read = 1;
        mem_write = 0;
        alu_result = 32'd8;
        instruction = 32'h0;
        instruction[14:12] = 3'b000;      // LB的funct3=000
        $display("Reading from address 8 with LB (signed, funct3=000 at [14:12])");
        
        @(posedge clk);
        #10;
        if(data_mem_data == 32'hFFFFFFC7) begin
            $display("Test 3.1 Result: PASS - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'hFFFFFFC7);
            pass_count = pass_count + 1;  // 计数加1
        end else begin
            $display("Test 3.1 Result: FAIL - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'hFFFFFFC7);
        end
        
        // 无符号读取 (LBU, funct3=100)
        instruction = 32'h0;
        instruction[14:12] = 3'b100;      // LBU的funct3=100
        $display("Reading from address 8 with LBU (unsigned, funct3=100 at [14:12])");
        
        @(posedge clk);
        #10;
        mem_read = 0;
        if(data_mem_data == 32'h000000C7) begin
            $display("Test 3.2 Result: PASS - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'h000000C7);
            pass_count = pass_count + 1;  // 计数加1
        end else begin
            $display("Test 3.2 Result: FAIL - Read 0x%0h (Expected 0x%0h)", data_mem_data, 32'h000000C7);
        end
        
        // 测试完成
        #10;
        $display("\n=============================================");
        $display("All tests completed");
        $display("Total Passed Tests: %0d out of 5", pass_count);  // 显示通过数量
        $display("=============================================");
        $finish;
    end
    
    // 监控信号
    initial begin
        $monitor("Time: %0t, clk: %b, mem_read: %b, mem_write: %b, Address: 0x%0h, Write Data: 0x%0h, Read Data: 0x%0h, funct3: %b",
                 $time, clk, mem_read, mem_write, alu_result, rs2_data, data_mem_data, instruction[14:12]);
    end

endmodule
