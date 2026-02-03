module Data_Memory (
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] rs2_data,
    input [31:0] alu_result,
    input [31:0] instruction,
    output reg [31:0] data_mem_data
);
    wire [2:0] funct3 = instruction[14:12];
    parameter max_size = 16384;
    reg [7:0] memory [0:max_size-1];
    integer i;

    initial begin
        for (i=0; i<max_size; i=i+1) memory[i] = 8'd0;
    end

    // Write
    always @(posedge clk) begin
        if(mem_write) begin
            case (funct3)
                3'b000: memory[alu_result] <= rs2_data[7:0]; // SB
                3'b001: begin // SH
                    memory[alu_result] <= rs2_data[7:0];
                    memory[alu_result+1] <= rs2_data[15:8];
                end
                3'b010: begin // SW
                    memory[alu_result] <= rs2_data[7:0];
                    memory[alu_result+1] <= rs2_data[15:8];
                    memory[alu_result+2] <= rs2_data[23:16];
                    memory[alu_result+3] <= rs2_data[31:24];
                end
            endcase
        end
    end

    // Read
    always @(*) begin
        if(mem_read) begin
            case (funct3)
                3'b000: data_mem_data = {{24{memory[alu_result][7]}}, memory[alu_result]}; // LB
                3'b001: data_mem_data = {{16{memory[alu_result+1][7]}}, memory[alu_result+1], memory[alu_result]}; // LH
                3'b010: data_mem_data = {memory[alu_result+3], memory[alu_result+2], memory[alu_result+1], memory[alu_result]}; // LW
                3'b100: data_mem_data = {24'b0, memory[alu_result]}; // LBU
                3'b101: data_mem_data = {16'b0, memory[alu_result+1], memory[alu_result]}; // LHU
                default: data_mem_data = 32'b0;
            endcase
        end else begin
            data_mem_data = 32'b0;
        end
    end
endmodule
