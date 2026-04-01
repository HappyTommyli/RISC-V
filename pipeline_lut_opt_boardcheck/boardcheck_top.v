`timescale 1ns / 1ps

module boardcheck_top (
    input  clk,
    input  rst,
    output pass_led
);
    pipeline dut (
        .clk(clk),
        .rst(rst),
        .pass_led(pass_led)
    );
endmodule
