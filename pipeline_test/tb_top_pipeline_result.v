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
    wire        wb_valid;
    wire [31:0] wb_instr;

    // Adjust if your program runs longer
    integer i;
    localparam integer MAX_CYCLES = 200000;
    integer cycle_count;
    integer instr_count;
    reg done_seen;
    localparam [31:0] DONE_INSTR = 32'h0000006F; // jal x0, 0 (self-loop)
    integer cycles_left;
    reg saw_store_c;
    reg [31:0] max_pc;

    top_pipeline_result dut (
        .clk(clk),
        .rst(rst),
        .result_index(result_index),
        .result_word(result_word),
        .instruction(instruction),
        .debug_pc(debug_pc),
        .debug_mem_write(debug_mem_write),
        .debug_mem_addr (debug_mem_addr),
        .debug_mem_wdata(debug_mem_wdata),
        .wb_valid(wb_valid),
        .wb_instr(wb_instr)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instr_count <= 0;
            done_seen   <= 0;
            saw_store_c <= 0;
            max_pc      <= 32'h0;
        end else begin
            if (!done_seen) begin
                cycle_count <= cycle_count + 1;
                if (wb_valid)
                    instr_count <= instr_count + 1;
                if (wb_valid && wb_instr == DONE_INSTR)
                    done_seen <= 1;
            end

            if (debug_pc > max_pc)
                max_pc <= debug_pc;

            // Debug: show stores into C range
            if (debug_mem_write && (debug_mem_addr >= 32'h00001200) && (debug_mem_addr < 32'h00001300)) begin
                $display("STORE C @%h <= %h (pc=%h)", debug_mem_addr, debug_mem_wdata, debug_pc);
                saw_store_c <= 1;
            end else if (debug_mem_write) begin
                $display("STORE @%h <= %h (pc=%h)", debug_mem_addr, debug_mem_wdata, debug_pc);
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
        saw_store_c = 0;
        max_pc = 0;

        // reset for a few cycles
        repeat (5) @(posedge clk);
        rst = 0;

        // wait for program to finish (detect done loop) or timeout
        cycles_left = MAX_CYCLES;
        while (cycles_left > 0 && !done_seen) begin
            @(posedge clk);
            cycles_left = cycles_left - 1;
        end
        if (done_seen) begin
            $display("DONE detected at cycle=%0d (wb_instr=%h)", cycle_count, wb_instr);
            $display("MAX PC reached = %h", max_pc);
        end else begin
            $display("WARNING: timeout waiting for DONE (jal x0,0)");
            $display("MAX PC reached = %h", max_pc);
        end
        if (!saw_store_c) $display("WARNING: no stores observed in C range (0x1200..0x12FF)");

        $display("==== Cycle Count = %0d ====", cycle_count);
        $display("==== Instruction Count (retired) = %0d ====", instr_count);
        $display("==== C matrix output (index -> value) ====");
        for (i = 0; i < 64; i = i + 1) begin
            result_index = i[5:0];
            @(posedge clk);
            #1; // allow combinational read to settle after clock edge
            $display("C[%0d] = 0x%08x (%0d)", i, result_word, result_word);
        end

        $display("==== DONE ====");
        $finish;
    end
endmodule
