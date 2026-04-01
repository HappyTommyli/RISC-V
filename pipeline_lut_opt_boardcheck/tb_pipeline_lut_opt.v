`timescale 1ns / 1ps

module tb_pipeline_lut_opt;
    reg clk;
    reg rst;

    // Adjust these for your expected result
    localparam [31:0] CHECK_ADDR  = 32'h00001020;
    localparam [31:0] CHECK_VALUE = 32'h00000046;
    localparam integer CHECK_WORD = (CHECK_ADDR >> 2);

    pipeline dut (
        .clk(clk),
        .rst(rst)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;

        // reset pulse
        repeat (2) @(posedge clk);
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;

        // run until pass or timeout
        repeat (20000) begin
            @(posedge clk);
            if (dut.u_MEM.data_memory_inst.mem[CHECK_WORD] === CHECK_VALUE) begin
                $display("PASS: mem[%0d] == 0x%08x", CHECK_WORD, CHECK_VALUE);
                $finish;
            end
        end
        $display("TIMEOUT: expected value not observed.");
        $finish;
    end
endmodule
