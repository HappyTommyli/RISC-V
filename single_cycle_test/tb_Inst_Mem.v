`timescale 1ns / 1ps

module tb_inst_mem;
    // 输入信号
    reg [31:0] pc_address;
    // 输出信号
    wire [31:0] instruction;

    // 实例化指令存储器模块
    inst_mem uut (
        .pc_address(pc_address),
        .instruction(instruction)
    );

    // 测试过程
    initial begin
        // 初始化信号
        pc_address = 32'h00000000;
        #1000;  // 等待组合逻辑稳定

        // 打印测试标题
        $display("==================================== Inst Mem Test Start ====================================");
        $display("Time | PC Address | Expected Instruction | Actual Instruction | Result");
        $display("------------------------------------------------------------------------------------------------");

        // 测试场景1：写入自定义指令（覆盖默认NOP）
        // 注意：通过修改存储器内部值进行测试（实际硬件中ROM需预先烧录）
        uut.memory[0] = 32'h00100033;  // ADD x1, x0, x0
        uut.memory[1] = 32'h00200113;  // ADDI x2, x0, 2
        uut.memory[2] = 32'h00302193;  // SLTI x3, x0, 3
        uut.memory[1023] = 32'h00404233; // XOR x4, x0, x0（边界地址）

        // 测试场景2：访问正常地址
        pc_address = 32'h00000000;  // 对应索引0
        #10;
        check_result(32'h00100033);

        pc_address = 32'h00000004;  // 对应索引1（地址=索引*4）
        #10;
        check_result(32'h00200113);

        pc_address = 32'h00000008;  // 对应索引2
        #10;
        check_result(32'h00302193);

        // 测试场景3：访问边界地址（num_of_inst-1 = 1023）
        pc_address = 32'h00000FFC;  // 1023 * 4 = 4092 = 0xFFC
        #10;
        check_result(32'h00404233);

        // 测试场景4：访问越界地址（超出1024条指令范围）
        pc_address = 32'h00001000;  // 1024 * 4 = 4096（越界）
        #10;
        check_result(32'h00000013);  // 预期输出NOP

        pc_address = 32'h00002000;  // 更大的越界地址
        #10;
        check_result(32'h00000013);

        // 测试场景5：地址变化响应速度（验证组合逻辑）
        pc_address = 32'h00000000;  // 快速切换地址
        #1;  // 组合逻辑应立即响应，无需等待时钟
        check_result(32'h00100033);

        pc_address = 32'h00000004;
        #1;
        check_result(32'h00200113);

        // 测试结束
        $display("\n==================================== Inst Mem Test End ====================================");
        $finish;
    end

    // 检查结果并打印
    task check_result;
        input [31:0] expected;
        begin
            $display("%4t | 0x%08h | 0x%08h | 0x%08h | %s",
                    $time, pc_address, expected, instruction,
                    (instruction == expected) ? "PASS" : "FAIL");
        end
    endtask

endmodule

