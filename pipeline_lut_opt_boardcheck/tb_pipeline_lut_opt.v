`timescale 1ns / 1ps

module tb_pipeline_lut_opt;
    reg clk;
    reg rst;
    wire pass_led;
    integer i;

    // Keep these aligned with pipeline.v board-check constants.
    localparam [31:0] CHECK_ADDR  = 32'h000012FC;
    localparam [31:0] CHECK_VALUE = 32'h00004560;
    localparam integer CHECK_WORD = (CHECK_ADDR >> 2);
    localparam integer MAX_CYCLES = 500000;
    localparam integer DMEM_WORDS = 4096;

    // Use board top in simulation so behavior matches Basys3 integration.
    boardcheck_top u_top (
        .clk(clk),
        .rst(rst),
        .pass_led(pass_led)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    integer cyc;

    initial begin
        clk = 0;
        rst = 1;
        cyc = 0;

        // Initialize data memory for simulation to avoid X-propagation.
        // This does not affect synthesis or on-board behavior.
        for (i = 0; i < DMEM_WORDS; i = i + 1) begin
            u_top.dut.u_MEM.data_memory_inst.mem[i] = 32'b0;
        end
        u_top.dut.u_MEM.data_memory_inst.word_q = 32'b0;

        // reset pulse (active high)
        repeat (2) @(posedge clk);
        rst = 0;

        // run until pass or timeout
        repeat (MAX_CYCLES) begin
            @(posedge clk);
            cyc = cyc + 1;

            if (u_top.dut.ex_mem_write_reg) begin
                $display("STORE @ cycle %0d: addr=0x%08x data=0x%08x",
                         cyc, u_top.dut.ex_mem_alu_result_reg, u_top.dut.mem_rs2_data);
            end

            // Primary criterion: same as board behavior (LED asserted).
            if (pass_led === 1'b1) begin
                $display("PASS @ cycle %0d: pass_led=1", cyc);
                $display("      mem[%0d] = 0x%08x (expected 0x%08x)",
                         CHECK_WORD,
                         u_top.dut.u_MEM.data_memory_inst.mem[CHECK_WORD],
                         CHECK_VALUE);
                $finish;
            end
        end

        // Timeout diagnostics to help debug quickly.
        $display("TIMEOUT after %0d cycles.", MAX_CYCLES);
        $display("  pass_led = %b", pass_led);
        $display("  mem[%0d] = 0x%08x (expected 0x%08x)",
                 CHECK_WORD,
                 u_top.dut.u_MEM.data_memory_inst.mem[CHECK_WORD],
                 CHECK_VALUE);
        $display("  if_pc    = 0x%08x", u_top.dut.if_id_pc);
        $finish;
    end
endmodule
