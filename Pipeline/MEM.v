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
    output        mem_regout
);
wire [31:0] data_mem_data;

Data_Memory data_memory_inst (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .rs2_data(rs2_data),
    .alu_result(alu_result),
    .instruction(ex_mem_instruction), 
    .data_mem_data(data_mem_data)
);

assign mem_data = mem_read ? data_mem_data : 32'b0; // If reading, output data from memory, else 0
assign mem_alu_result = alu_result;
assign mem_rd = rd;
assign mem_reg_write = reg_write;
assign mem_regout = mem_reg;
endmodule
