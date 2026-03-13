// Debug variant of Data_Memory (original Data_Mem.v unchanged)
(* keep_hierarchy = "yes" *)
module Data_Memory_dbg (
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] rs2_data,
    input [31:0] alu_result,
    input [31:0] instruction,
    output reg [31:0] data_mem_data,
    // Debug read (combinational): expose memory content for top-level checking
    input  [31:0] debug_addr,
    output reg [31:0] debug_data
);
    wire [2:0] funct3 = instruction[14:12];

    // 16KB data memory: 4096 words * 32-bit
    parameter WORDS = 4096;

    // Force distributed RAM (asynchronous read, synchronous write)
    (* ram_style = "distributed" *) reg [31:0] mem [0:WORDS-1];

    wire [31:0] word = mem[alu_result[31:2]];
    wire [1:0]  byte_off = alu_result[1:0];

    // Write
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB
                    case (byte_off)
                        2'b00: mem[alu_result[31:2]] <= {word[31:8],  rs2_data[7:0]};
                        2'b01: mem[alu_result[31:2]] <= {word[31:16], rs2_data[7:0], word[7:0]};
                        2'b10: mem[alu_result[31:2]] <= {word[31:24], rs2_data[7:0], word[15:0]};
                        2'b11: mem[alu_result[31:2]] <= {rs2_data[7:0], word[23:0]};
                    endcase
                end
                3'b001: begin // SH
                    case (byte_off[1])
                        1'b0: mem[alu_result[31:2]] <= {word[31:16], rs2_data[15:0]};
                        1'b1: mem[alu_result[31:2]] <= {rs2_data[15:0], word[15:0]};
                    endcase
                end
                3'b010: begin // SW
                    mem[alu_result[31:2]] <= rs2_data;
                end
                default: begin
                    mem[alu_result[31:2]] <= mem[alu_result[31:2]]; // no-op
                end
            endcase
        end
    end

    // Read
    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB
                    case (byte_off)
                        2'b00: data_mem_data = {{24{word[7]}},  word[7:0]};
                        2'b01: data_mem_data = {{24{word[15]}}, word[15:8]};
                        2'b10: data_mem_data = {{24{word[23]}}, word[23:16]};
                        2'b11: data_mem_data = {{24{word[31]}}, word[31:24]};
                    endcase
                end
                3'b001: begin // LH
                    if (byte_off[1] == 1'b0)
                        data_mem_data = {{16{word[15]}}, word[15:0]};
                    else
                        data_mem_data = {{16{word[31]}}, word[31:16]};
                end
                3'b010: begin // LW
                    data_mem_data = word;
                end
                3'b100: begin // LBU
                    case (byte_off)
                        2'b00: data_mem_data = {24'b0, word[7:0]};
                        2'b01: data_mem_data = {24'b0, word[15:8]};
                        2'b10: data_mem_data = {24'b0, word[23:16]};
                        2'b11: data_mem_data = {24'b0, word[31:24]};
                    endcase
                end
                3'b101: begin // LHU
                    if (byte_off[1] == 1'b0)
                        data_mem_data = {16'b0, word[15:0]};
                    else
                        data_mem_data = {16'b0, word[31:16]};
                end
                default: data_mem_data = 32'b0;
            endcase
        end else begin
            data_mem_data = 32'b0;
        end
    end

    // Debug read (always available, independent of mem_read)
    always @(*) begin
        debug_data = mem[debug_addr[31:2]];
    end
endmodule
