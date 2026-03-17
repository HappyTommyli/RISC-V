`timescale 1ns / 1ps

// Top-level wrapper: exposes C matrix words via result_index
module top_pipeline_result (
    input  wire        clk,
    input  wire        rst,
    input  wire [5:0]  result_index,
    output wire [31:0] result_word,
    output wire [31:0] instruction,
    output wire [31:0] debug_pc,
    output wire        debug_mem_write,
    output wire [31:0] debug_mem_addr,
    output wire [31:0] debug_mem_wdata,
    output wire        wb_valid,
    output wire [31:0] wb_instr
);
    // Base address of C matrix in data memory. Adjust if your asm uses a different layout.
    localparam [31:0] C_BASE = 32'h00001200;

    wire [31:0] debug_addr = C_BASE + {result_index, 2'b00};

    pipeline_dbg u_cpu (
        .clk       (clk),
        .rst       (rst),
        .debug_addr(debug_addr),
        .debug_data(result_word),
        .instruction(instruction),
        .debug_pc   (debug_pc),
        .debug_mem_write(debug_mem_write),
        .debug_mem_addr (debug_mem_addr),
        .debug_mem_wdata(debug_mem_wdata),
        .wb_valid   (wb_valid),
        .wb_instr   (wb_instr)
    );
endmodule
