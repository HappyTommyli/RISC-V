`timescale 1ns / 1ps
module pc (
    input wire clk,
    input wire rst,
    input wire [31:0] next_pc,
    output reg [31:0] pc_address
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_address <= 32'h00000000;
        else
            pc_address <= next_pc;
    end
endmodule