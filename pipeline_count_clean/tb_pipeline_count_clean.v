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

    pipeline_count_clean dut (
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
