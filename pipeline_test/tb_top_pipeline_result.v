`timescale 1ns / 1ps

module tb_top_pipeline_result;
    reg clk;
    reg rst;
    reg [5:0] result_index;
    wire [31:0] result_word;
    wire [31:0] instruction;
    wire [31:0] debug_pc;
    wire        debug_mem_write;
    wire [31:0] debug_mem_addr;
    wire [31:0] debug_mem_wdata;

    // Adjust if your program runs longer
    integer i;
    localparam integer MAX_CYCLES = 200000;
    integer cycle_count;
    integer instr_count;
    reg done_seen;
    localparam [31:0] DONE_INSTR = 32'h0000006F; // jal x0, 0 (self-loop)
    integer cycles_left;
    reg [31:0] last_pc;
    integer stable_count;
    localparam integer STABLE_DONE_CYCLES = 4;

    top_pipeline_result dut (
        .clk(clk),
        .rst(rst),
        .result_index(result_index),
        .result_word(result_word),
        .instruction(instruction),
        .debug_pc(debug_pc),
        .debug_mem_write(debug_mem_write),
        .debug_mem_addr (debug_mem_addr),
        .debug_mem_wdata(debug_mem_wdata)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instr_count <= 0;
            done_seen   <= 0;
            last_pc     <= 32'h0;
            stable_count<= 0;
        end else begin
            if (!done_seen) begin
                cycle_count <= cycle_count + 1;
                if (instruction !== 32'h00000013 && instruction !== 32'h00000000)
                    instr_count <= instr_count + 1;
                if (instruction == DONE_INSTR && debug_pc == last_pc) begin
                    stable_count <= stable_count + 1;
                    if (stable_count >= STABLE_DONE_CYCLES)
                        done_seen <= 1;
                end else begin
                    stable_count <= 0;
                end
                last_pc <= debug_pc;
            end

            // Debug: show stores into C range
            if (debug_mem_write && (debug_mem_addr >= 32'h00001200) && (debug_mem_addr < 32'h00001300)) begin
                $display("STORE C @%h <= %h (pc=%h)", debug_mem_addr, debug_mem_wdata, debug_pc);
            end
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        result_index = 0;
        cycle_count = 0;
        instr_count = 0;
        done_seen = 0;
        last_pc = 0;
        stable_count = 0;

        // reset for a few cycles
        repeat (5) @(posedge clk);
        rst = 0;

        // wait for program to finish (detect done loop) or timeout
        cycles_left = MAX_CYCLES;
        while (cycles_left > 0 && !done_seen) begin
            @(posedge clk);
            cycles_left = cycles_left - 1;
        end
        if (!done_seen) $display("WARNING: timeout waiting for DONE (jal x0,0)");

        $display("==== Cycle Count = %0d ====", cycle_count);
        $display("==== Instruction Count (non-NOP fetched) = %0d ====", instr_count);
        $display("==== C matrix output (index -> value) ====");
        for (i = 0; i < 64; i = i + 1) begin
            result_index = i[5:0];
            @(posedge clk);
            $display("C[%0d] = 0x%08x (%0d)", i, result_word, result_word);
        end

        $display("==== DONE ====");
        $finish;
    end
endmodule
