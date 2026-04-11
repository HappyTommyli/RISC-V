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

    output        cache_stall_out
);
wire [31:0] data_mem_data;
wire [31:0] cache_rdata;
wire        cache_stall;
wire        dmem_read;
wire        dmem_write;
wire [31:0] dmem_addr;
wire [31:0] dmem_wdata;
wire [31:0] dmem_instruction;
wire [31:0] dmem_rdata;

// Data_Memory data_memory_inst (
//     .clk(clk),
//     .mem_read(mem_read),
//     .mem_write(mem_write),
//     .rs2_data(rs2_data),
//     .alu_result(alu_result),
//     .instruction(ex_mem_instruction), 
//     .data_mem_data(data_mem_data)
// );

Data_Memory data_memory_inst (
    .clk           (clk),
    .mem_read      (dmem_read),
    .mem_write     (dmem_write),
    .rs2_data      (dmem_wdata),
    .alu_result    (dmem_addr),
    .instruction   (ex_mem_instruction),
    .data_mem_data (dmem_rdata)   
);
Data_Cache u_dcache (
    .clk            (clk),
    .rst            (rst),
    .mem_read       (mem_read),
    .mem_write      (mem_write),
    .addr           (alu_result),
    .wdata          (rs2_data),
    .instruction    (ex_mem_instruction),
    .cache_stall    (cache_stall),
    .rdata          (cache_rdata),
    .dmem_read      (dmem_read),
    .dmem_write     (dmem_write),
    .dmem_addr      (dmem_addr),
    .dmem_wdata     (dmem_wdata),
    .dmem_rdata     (dmem_rdata)
);

// assign mem_data = mem_read ? data_mem_data : 32'b0; // If reading, output data from memory, else 0
// assign mem_alu_result = alu_result;
// assign mem_rd = rd;
// assign mem_reg_write = reg_write;
// assign mem_regout = mem_reg;

assign mem_data       = cache_rdata;
assign mem_alu_result = alu_result;
assign mem_rd         = rd;
assign mem_reg_write  = reg_write;
assign mem_regout     = mem_reg;
assign cache_stall_out    = cache_stall;

endmodule
