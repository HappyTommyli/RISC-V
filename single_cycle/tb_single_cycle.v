`timescale 1ns / 1ps

module tb_SingleCycle_RISCV;

    // Inputs
    reg clk;
    reg rst;

    // Instantiate the Unit Under Test (UUT)
    SingleCycle_RISCV dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;  // 10ns period (100 MHz)
    end

    // Load a simple test program into instruction memory
    // Program:
    // 0x000: addi x1, x0, 5   (x1 = 5)
    // 0x004: addi x2, x0, 7   (x2 = 7)
    // 0x008: add x3, x1, x2   (x3 = 12)
    // 0x00C: sw x3, 0(x0)     (store 12 at memory address 0)
    // 0x010: lw x4, 0(x0)     (load from memory address 0 to x4)
    initial begin
        dut.inst_mem_inst.memory[0] = 32'h00500093;  // addi x1, x0, 5
        dut.inst_mem_inst.memory[1] = 32'h00700113;  // addi x2, x0, 7
        dut.inst_mem_inst.memory[2] = 32'h002081b3;  // add x3, x1, x2
        dut.inst_mem_inst.memory[3] = 32'h00302023;  // sw x3, 0(x0)
        dut.inst_mem_inst.memory[4] = 32'h00002203;  // lw x4, 0(x0)
    end

    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;

        // Apply reset
        #10;
        rst = 0;

        // Run simulation for enough cycles to execute the program (single-cycle: 1 instr/cycle)
        // 5 instructions + some margin
        #100;

        // Check register values
        if (dut.Reg_File_inst.register[1] === 32'd5)
            $display("Test Passed: x1 = 5");
        else
            $display("Test Failed: x1 = %d (expected 5)", dut.Reg_File_inst.register[1]);

        if (dut.Reg_File_inst.register[2] === 32'd7)
            $display("Test Passed: x2 = 7");
        else
            $display("Test Failed: x2 = %d (expected 7)", dut.Reg_File_inst.register[2]);

        if (dut.Reg_File_inst.register[3] === 32'd12)
            $display("Test Passed: x3 = 12");
        else
            $display("Test Failed: x3 = %d (expected 12)", dut.Reg_File_inst.register[3]);

        if (dut.Reg_File_inst.register[4] === 32'd12)
            $display("Test Passed: x4 = 12 (loaded from memory)");
        else
            $display("Test Failed: x4 = %d (expected 12)", dut.Reg_File_inst.register[4]);

        // Check data memory (little-endian: 12 = 0x0000000C)
        if (dut.Data_Memory_inst.memory[0] === 8'h0C &&
            dut.Data_Memory_inst.memory[1] === 8'h00 &&
            dut.Data_Memory_inst.memory[2] === 8'h00 &&
            dut.Data_Memory_inst.memory[3] === 8'h00)
            $display("Test Passed: Memory[0] = 12");
        else
            $display("Test Failed: Memory[0-3] = %h %h %h %h (expected 0C 00 00 00)",
                     dut.Data_Memory_inst.memory[0], dut.Data_Memory_inst.memory[1],
                     dut.Data_Memory_inst.memory[2], dut.Data_Memory_inst.memory[3]);

        // End simulation
        $finish;
    end

    // Dump waveform for debugging
    initial begin
        $dumpfile("single_cycle_tb.vcd");
        $dumpvars(0, tb_SingleCycle_RISCV);
    end

endmodule