`timescale 1ns / 1ps

module tb_pipeline_lut_opt;
    reg clk;
    reg rst;
    reg [2:0] buttons;
    reg [31:0] timer_value;
    reg display_busy;
    wire display_we;
    wire [31:0] display_cmd;

    pipeline dut (
        .clk(clk),
        .rst(rst),
        .buttons(buttons),
        .timer_value(timer_value),
        .display_busy(display_busy),
        .display_we(display_we),
        .display_cmd(display_cmd)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) timer_value <= 32'b0;
        else     timer_value <= timer_value + 1;
    end

    initial begin
        clk = 0;
        rst = 0;
        buttons = 3'b000;
        timer_value = 32'b0;
        display_busy = 1'b0;

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
