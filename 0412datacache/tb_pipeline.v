//`timescale 1ns / 1ps

//module tb_pipeline_RISCV();

//    // Inputs
//    reg clk;
//    reg rst;
//    wire [31:0] instruction;

//    // Instantiate the Unit Under Test (UUT)
//    pipeline dut (
//        .clk(clk),
//        .rst(rst)//,
//        //.instruction(instruction)
//    );

//    // Clock generation
//    always begin
//        #20 clk = ~clk;  // 10ns period (100 MHz)
//    end
//always @(posedge clk) begin
//    if (!rst &&
//        dut.wb_regwrite &&                
//        (dut.wb_rd == 5'd10 || dut.wb_rd == 5'd11 || dut.wb_rd == 5'd12 || dut.wb_rd == 5'd13)) begin
//        $display("WB: t=%t rd=%0d data=%h",
//                 $time, dut.wb_rd, dut.wb_data);
//    end
//end

//    // Load a simple test program into instruction memory
//    // Program:
//    // 0x000: addi x1, x0, 5   (x1 = 5)
//    // 0x004: addi x2, x0, 7   (x2 = 7)
//    // 0x008: add x3, x1, x2   (x3 = 12)
//    // 0x00C: sw x3, 0(x0)     (store 12 at memory address 0)
//    // 0x010: lw x4, 0(x0)     (load from memory address 0 to x4)
////    initial begin
////        dut.inst_mem_inst.memory[0] = 32'h00500093;  // addi x1, x0, 5
////        dut.inst_mem_inst.memory[1] = 32'h00700113;  // addi x2, x0, 7
////        dut.inst_mem_inst.memory[2] = 32'h002081b3;  // add x3, x1, x2
////        dut.inst_mem_inst.memory[3] = 32'h00302023;  // sw x3, 0(x0)
////        dut.inst_mem_inst.memory[4] = 32'h00002203;  // lw x4, 0(x0)
////    end

//    // Test sequence
//    initial begin
//        // Initialize inputs
//        clk = 0;
//        rst = 1;

//        // Apply reset
//        #40;
//        rst = 0;

//        // Run simulation for enough cycles to execute the program (single-cycle: 1 instr/cycle)
//        // 5 instructions + some margin

//        #20000000;
//        // End simulation
//        $stop;
//    end

//    // Dump waveform for debugging
////    initial begin
////        $dumpfile("single_cycle_tb.vcd");
////        $dumpvars(0, tb_SingleCycle_RISCV);
////    end

//endmodule
`timescale 1ns / 1ps

module tb_pipeline_count_clean;
    reg clk;
    reg rst;

    wire [31:0] wb_instr;
    wire        wb_valid;

    integer cycle_count;
    integer instr_count;
    integer cycles_left;
    integer i;
    reg     done_seen;

    localparam integer MAX_CYCLES = 500000;
    localparam [31:0] DONE_INSTR = 32'h0000006F; // jal x0, 0
    localparam [31:0] C_BASE     = 32'h00001200;

    pipeline dut (
        .clk      (clk),
        .rst      (rst),
        .wb_instr (wb_instr),
        .wb_valid (wb_valid)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instr_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (wb_valid)
                instr_count <= instr_count + 1;
        end
    end

    initial begin
        clk = 0;
        rst = 0;
        cycle_count = 0;
        instr_count = 0;
        done_seen = 0;

        // reset pulse
        repeat (2) @(posedge clk);
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;

        // wait for DONE or timeout
        cycles_left = MAX_CYCLES;
        while (cycles_left > 0 && !done_seen) begin
            @(posedge clk);
            if (wb_valid && wb_instr == DONE_INSTR) begin
                $display("DONE at cycle=%0d", cycle_count);
                done_seen = 1;
            end
            cycles_left = cycles_left - 1;
        end

        if (!done_seen) begin
            $display("WARNING: timeout waiting for DONE");
        end

        $display("==== Cycle Count = %0d ====", cycle_count);
        $display("==== Instruction Count (retired) = %0d ====", instr_count);
        $display("==== C matrix output ====");
        for (i = 0; i < 64; i = i + 1) begin
            $display("C[%0d] = 0x%08x (%0d)", i,
                dut.u_MEM.data_memory_inst.mem[(C_BASE >> 2) + i],
                dut.u_MEM.data_memory_inst.mem[(C_BASE >> 2) + i]);
        end

        $display("==== DONE ====");
        $finish;
    end
endmodule
