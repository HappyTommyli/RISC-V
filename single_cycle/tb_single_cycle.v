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
        #20 clk = ~clk;  // 10ns period (100 MHz)
    end

    // Load a simple test program into instruction memory
    // Program:
    // 0x000: addi x1, x0, 5   (x1 = 5)
    // 0x004: addi x2, x0, 7   (x2 = 7)
    // 0x008: add x3, x1, x2   (x3 = 12)
    // 0x00C: sw x3, 0(x0)     (store 12 at memory address 0)
    // 0x010: lw x4, 0(x0)     (load from memory address 0 to x4)
//    initial begin
//        dut.inst_mem_inst.memory[0] = 32'h00500093;  // addi x1, x0, 5
//        dut.inst_mem_inst.memory[1] = 32'h00700113;  // addi x2, x0, 7
//        dut.inst_mem_inst.memory[2] = 32'h002081b3;  // add x3, x1, x2
//        dut.inst_mem_inst.memory[3] = 32'h00302023;  // sw x3, 0(x0)
//        dut.inst_mem_inst.memory[4] = 32'h00002203;  // lw x4, 0(x0)
//    end

    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;

        // Apply reset
        #40;
        rst = 0;

        // Run simulation for enough cycles to execute the program (single-cycle: 1 instr/cycle)
        // 5 instructions + some margin


        // End simulation
        $finish;
    end

    // Dump waveform for debugging
    initial begin
        $dumpfile("single_cycle_tb.vcd");
        $dumpvars(0, tb_SingleCycle_RISCV);
    end

endmodule
