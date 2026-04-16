`timescale 1ns / 1ps
 (* keep_hierarchy = "yes" *)
module MEM(
    input clk,
    input rst,

    // From EX
    input [31:0] alu_result,
    input [31:0] rs2_data,
    input [4:0] rd,
    input reg_write,
    input mem_write, mem_read, mem_reg,
    input [31:0] ex_mem_instruction,

    // To WB
    output [31:0] mem_data,
    output [31:0] mem_alu_result,
    output [4:0]  mem_rd,
    output        mem_reg_write,
    output        mem_regout,

    // --- 新增的 I/O 腳位 ---
    input  [3:0] btns,
    input  sw0,
    input  [6:0] vram_disp_addr,
    output [7:0] vram_disp_data
);

wire [31:0] data_mem_data;

Data_Memory data_memory_inst (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .rs2_data(rs2_data),
    .alu_result(alu_result),
    .instruction(ex_mem_instruction), 
    .data_mem_data(data_mem_data),
    // --- I/O 傳遞給 Data_Memory ---
    .btns(btns),
    .sw0(sw0),
    .vram_disp_addr(vram_disp_addr),
    .vram_disp_data(vram_disp_data)
);

assign mem_data = mem_read ? data_mem_data : 32'b0; // If reading, output data from memory, else 0
assign mem_alu_result = alu_result;
assign mem_rd = rd;
assign mem_reg_write = reg_write;
assign mem_regout = mem_reg;

endmodule