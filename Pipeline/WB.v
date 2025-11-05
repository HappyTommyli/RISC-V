module WB (
    input  [31:0] mem_data,     // Data from memory (if load)
    input  [31:0] alu_result,   // ALU output (if arithmetic)
    input  [4:0]  rd,           // Destination
    input         reg_write,     // write?
    input         mem_reg,     // 1 = mem_data, 0 = alu_result

    output [31:0] wb_data,      // Data to write to regfile
    output [4:0]  wb_rd,        // Register to write to
    output        wb_regwrite   // Write enable
);

    // select memory data / ALU result
    assign wb_data = mem_reg ? mem_data : alu_result;

    // Pass through destination register and write enable
    assign wb_rd = rd;
    assign wb_regwrite = reg_write;
endmodule