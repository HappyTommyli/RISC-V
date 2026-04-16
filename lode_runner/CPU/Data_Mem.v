(* keep_hierarchy = "yes" *)
module Data_Memory (
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] rs2_data,
    input [31:0] alu_result,
    input [31:0] instruction,
    output reg [31:0] data_mem_data,
    input  [3:0] buttons,
    input  [31:0] timer_value,
    input  display_busy,
    output reg display_we,
    output reg [31:0] display_cmd,
    output reg oled_fb_we,
    output reg [9:0] oled_fb_addr,
    output reg [7:0] oled_fb_data
);
    wire [2:0] funct3 = instruction[14:12];

    // 32KB data memory: 8192 words * 32-bit
    parameter WORDS = 8192;

    // Force block RAM (synchronous read/write)
    (* ram_style = "block" *) reg [31:0] mem [0:WORDS-1];
    reg [7:0] oled_shadow [0:1023];

    reg [31:0] word_q;
    wire [1:0]  byte_off = alu_result[1:0];
    integer i;

    // Address map
    wire is_internal_mem = (alu_result < 32'h00008000);
    wire is_btn          = (alu_result == 32'h00008000);
    wire is_timer        = (alu_result == 32'h00008004);
    wire is_display      = (alu_result == 32'h00009000);
    wire is_oled_fb      = (alu_result >= 32'h0000A000) && (alu_result < 32'h0000A400);

    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            mem[i] = 32'b0;
        end
        for (i = 0; i < 1024; i = i + 1) begin
            oled_shadow[i] = 8'b0;
        end
`include "lode_runner_map_128x64_mem_init.vh"
    end

    // Synchronous read/write
    always @(posedge clk) begin
        if (mem_read && is_internal_mem) begin
            word_q <= mem[alu_result[31:2]];
        end

        if (mem_write && is_internal_mem) begin
            case (funct3)
                3'b000: begin // SB
                    case (byte_off)
                        2'b00: mem[alu_result[31:2]] <= {mem[alu_result[31:2]][31:8],  rs2_data[7:0]};
                        2'b01: mem[alu_result[31:2]] <= {mem[alu_result[31:2]][31:16], rs2_data[7:0], mem[alu_result[31:2]][7:0]};
                        2'b10: mem[alu_result[31:2]] <= {mem[alu_result[31:2]][31:24], rs2_data[7:0], mem[alu_result[31:2]][15:0]};
                        2'b11: mem[alu_result[31:2]] <= {rs2_data[7:0], mem[alu_result[31:2]][23:0]};
                    endcase
                end
                3'b001: begin // SH
                    case (byte_off[1])
                        1'b0: mem[alu_result[31:2]] <= {mem[alu_result[31:2]][31:16], rs2_data[15:0]};
                        1'b1: mem[alu_result[31:2]] <= {rs2_data[15:0], mem[alu_result[31:2]][15:0]};
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

        if (mem_write && is_oled_fb && (funct3 == 3'b000)) begin
            oled_shadow[alu_result[9:0]] <= rs2_data[7:0];
        end
    end

    // Read (combinational from registered word_q)
    always @(*) begin
        if (mem_read) begin
            if (is_internal_mem) begin
                case (funct3)
                    3'b000: begin // LB
                        case (byte_off)
                            2'b00: data_mem_data = {{24{word_q[7]}},  word_q[7:0]};
                            2'b01: data_mem_data = {{24{word_q[15]}}, word_q[15:8]};
                            2'b10: data_mem_data = {{24{word_q[23]}}, word_q[23:16]};
                            2'b11: data_mem_data = {{24{word_q[31]}}, word_q[31:24]};
                        endcase
                    end
                    3'b001: begin // LH
                        if (byte_off[1] == 1'b0)
                            data_mem_data = {{16{word_q[15]}}, word_q[15:0]};
                        else
                            data_mem_data = {{16{word_q[31]}}, word_q[31:16]};
                    end
                    3'b010: begin // LW
                        data_mem_data = word_q;
                    end
                    3'b100: begin // LBU
                        case (byte_off)
                            2'b00: data_mem_data = {24'b0, word_q[7:0]};
                            2'b01: data_mem_data = {24'b0, word_q[15:8]};
                            2'b10: data_mem_data = {24'b0, word_q[23:16]};
                            2'b11: data_mem_data = {24'b0, word_q[31:24]};
                        endcase
                    end
                    3'b101: begin // LHU
                        if (byte_off[1] == 1'b0)
                            data_mem_data = {16'b0, word_q[15:0]};
                        else
                            data_mem_data = {16'b0, word_q[31:16]};
                    end
                    default: data_mem_data = 32'b0;
                endcase
            end else if (is_btn) begin
                data_mem_data = {28'b0, buttons};
            end else if (is_timer) begin
                data_mem_data = timer_value;
            end else if (is_display) begin
                data_mem_data = {display_busy, 31'b0};
            end else if (is_oled_fb) begin
                data_mem_data = {24'b0, oled_shadow[alu_result[9:0]]};
            end else begin
                data_mem_data = 32'b0;
            end
        end else begin
            data_mem_data = 32'b0;
        end
    end

    // Display write handshake (memory-mapped IO)
    always @(*) begin
        display_we  = mem_write && is_display;
        display_cmd = rs2_data;
        oled_fb_we   = mem_write && is_oled_fb && (funct3 == 3'b000);
        oled_fb_addr = alu_result[9:0];
        oled_fb_data = rs2_data[7:0];
    end
endmodule

// --- Original version (kept for reference) ---
// module Data_Memory (
//     input clk,
//     input mem_read,
//     input mem_write,
//     input [31:0] rs2_data,
//     input [31:0] alu_result,
//     input [31:0] instruction,
//     output reg [31:0] data_mem_data
// );
//     wire [2:0] funct3 = instruction[14:12];
//     parameter max_size = 16384;
//     reg [7:0] memory [0:max_size-1];
//     integer i;
//
//     initial begin
//         for (i=0; i<max_size; i=i+1) memory[i] = 8'd0;
//     end
//
//     // Write
//     always @(posedge clk) begin
//         if(mem_write) begin
//             case (funct3)
//                 3'b000: memory[alu_result] <= rs2_data[7:0]; // SB
//                 3'b001: begin // SH
//                     memory[alu_result] <= rs2_data[7:0];
//                     memory[alu_result+1] <= rs2_data[15:8];
//                 end
//                 3'b010: begin // SW
//                     memory[alu_result] <= rs2_data[7:0];
//                     memory[alu_result+1] <= rs2_data[15:8];
//                     memory[alu_result+2] <= rs2_data[23:16];
//                     memory[alu_result+3] <= rs2_data[31:24];
//                 end
//             endcase
//         end
//     end
//
//     // Read
//     always @(*) begin
//         if(mem_read) begin
//             case (funct3)
//                 3'b000: data_mem_data = {{24{memory[alu_result][7]}}, memory[alu_result]}; // LB
//                 3'b001: data_mem_data = {{16{memory[alu_result+1][7]}}, memory[alu_result+1], memory[alu_result]}; // LH
//                 3'b010: data_mem_data = {memory[alu_result+3], memory[alu_result+2], memory[alu_result+1], memory[alu_result]}; // LW
//                 3'b100: data_mem_data = {24'b0, memory[alu_result]}; // LBU
//                 3'b101: data_mem_data = {16'b0, memory[alu_result+1], memory[alu_result]}; // LHU
//                 default: data_mem_data = 32'b0;
//             endcase
//         end else begin
//             data_mem_data = 32'b0;
//         end
//     end
// endmodule
