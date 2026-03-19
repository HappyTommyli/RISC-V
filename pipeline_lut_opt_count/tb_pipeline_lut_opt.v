`timescale 1ns / 1ps

module tb_pipeline_lut_opt;
    reg clk;
    reg rst;

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

        // run long enough for waveform inspection
        repeat (5000) @(posedge clk);
        $finish;
    end
endmodule
