(* keep_hierarchy = "yes" *)
module Data_Memory (
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [31:0] rs2_data,
    input  [31:0] alu_result,
    input  [31:0] instruction,
    output reg [31:0] data_mem_data
);
    wire [2:0] funct3 = instruction[14:12];

    // 16KB data memory: 4096 words * 32-bit
    parameter WORDS = 4096;

    (* ram_style = "block" *) reg [31:0] mem [0:WORDS-1];

    wire [31:0] word     = mem[alu_result[31:2]];
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
                    mem[alu_result[31:2]] <= mem[alu_result[31:2]];
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

                default: begin
                    data_mem_data = 32'b0;
                end
            endcase
        end else begin
            data_mem_data = 32'b0;
        end
    end

endmodule

module Data_Cache (
    input         clk,
    input         rst,
    input         mem_read,
    input         mem_write,
    input  [31:0] addr,
    input  [31:0] wdata,
    input  [31:0] instruction,
    output        cache_stall,
    output [31:0] rdata,
    output        dmem_read,
    output        dmem_write,
    output [31:0] dmem_addr,
    output [31:0] dmem_wdata,
    output [31:0] dmem_instruction,
    input  [31:0] dmem_rdata
);

    localparam NUM_LINES   = 64;
    localparam INDEX_BITS  = 6;
    localparam TAG_BITS    = 32 - INDEX_BITS - 2; // word address uses addr[31:2]

    reg                 valid_array [0:NUM_LINES-1];
    reg [TAG_BITS-1:0]  tag_array   [0:NUM_LINES-1];
    reg [31:0]          data_array  [0:NUM_LINES-1];

    wire [1:0]             byte_off;
    wire [INDEX_BITS-1:0]  index;
    wire [TAG_BITS-1:0]    tag;
    wire [2:0]             funct3;
    wire                   hit;

    reg  [31:0] hit_rdata;

    // ---- hit/miss counters ----
    reg [31:0] load_access_count;
    reg [31:0] load_hit_count;
    reg [31:0] load_miss_count;
    reg [31:0] store_access_count;

    integer i;

    assign byte_off = addr[1:0];
    assign index    = addr[2 + INDEX_BITS - 1 : 2];
    assign tag      = addr[31 : 2 + INDEX_BITS];
    assign funct3   = instruction[14:12];

    assign hit = valid_array[index] && (tag_array[index] == tag);

    assign cache_stall      = 1'b0;
    assign dmem_read        = mem_read && ~hit;
    assign dmem_write       = mem_write;
    assign dmem_addr        = addr;
    assign dmem_wdata       = wdata;
    assign dmem_instruction = instruction;

    always @(*) begin
        case (funct3)
            3'b000: begin // LB
                case (byte_off)
                    2'b00: hit_rdata = {{24{data_array[index][7]}},   data_array[index][7:0]};
                    2'b01: hit_rdata = {{24{data_array[index][15]}},  data_array[index][15:8]};
                    2'b10: hit_rdata = {{24{data_array[index][23]}},  data_array[index][23:16]};
                    2'b11: hit_rdata = {{24{data_array[index][31]}},  data_array[index][31:24]};
                endcase
            end

            3'b001: begin // LH
                if (byte_off[1] == 1'b0)
                    hit_rdata = {{16{data_array[index][15]}}, data_array[index][15:0]};
                else
                    hit_rdata = {{16{data_array[index][31]}}, data_array[index][31:16]};
            end

            3'b010: begin // LW
                hit_rdata = data_array[index];
            end

            3'b100: begin // LBU
                case (byte_off)
                    2'b00: hit_rdata = {24'b0, data_array[index][7:0]};
                    2'b01: hit_rdata = {24'b0, data_array[index][15:8]};
                    2'b10: hit_rdata = {24'b0, data_array[index][23:16]};
                    2'b11: hit_rdata = {24'b0, data_array[index][31:24]};
                endcase
            end

            3'b101: begin // LHU
                if (byte_off[1] == 1'b0)
                    hit_rdata = {16'b0, data_array[index][15:0]};
                else
                    hit_rdata = {16'b0, data_array[index][31:16]};
            end

            default: begin
                hit_rdata = 32'b0;
            end
        endcase
    end

    assign rdata = mem_read ? (hit ? hit_rdata : dmem_rdata) : 32'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            load_access_count  <= 32'b0;
            load_hit_count     <= 32'b0;
            load_miss_count    <= 32'b0;
            store_access_count <= 32'b0;

            for (i = 0; i < NUM_LINES; i = i + 1) begin
                valid_array[i] <= 1'b0;
                tag_array[i]   <= {TAG_BITS{1'b0}};
                data_array[i]  <= 32'b0;
            end
        end else begin
            // ---- load hit/miss 統計 ----
            if (mem_read) begin
                load_access_count <= load_access_count + 32'd1;

                if (hit) begin
                    load_hit_count <= load_hit_count + 32'd1;
                end else begin
                    load_miss_count <= load_miss_count + 32'd1;
                end
            end

            // ---- store 統計 ----
            if (mem_write) begin
                store_access_count <= store_access_count + 32'd1;
            end

            // ---- miss allocate ----
            if (mem_read && ~hit) begin
                case (funct3)
                    3'b000, 3'b001, 3'b010, 3'b100, 3'b101: begin
                        valid_array[index] <= 1'b1;
                        tag_array[index]   <= tag;
                        data_array[index]  <= dmem_rdata;
                    end
                    default: begin
                        valid_array[index] <= valid_array[index];
                        tag_array[index]   <= tag_array[index];
                        data_array[index]  <= data_array[index];
                    end
                endcase
            end

            // ---- write hit update ----
            if (mem_write && hit) begin
                case (funct3)
                    3'b000: begin // SB
                        case (byte_off)
                            2'b00: data_array[index] <= {data_array[index][31:8],  wdata[7:0]};
                            2'b01: data_array[index] <= {data_array[index][31:16], wdata[7:0], data_array[index][7:0]};
                            2'b10: data_array[index] <= {data_array[index][31:24], wdata[7:0], data_array[index][15:0]};
                            2'b11: data_array[index] <= {wdata[7:0], data_array[index][23:0]};
                        endcase
                    end

                    3'b001: begin // SH
                        case (byte_off[1])
                            1'b0: data_array[index] <= {data_array[index][31:16], wdata[15:0]};
                            1'b1: data_array[index] <= {wdata[15:0], data_array[index][15:0]};
                        endcase
                    end

                    3'b010: begin // SW
                        data_array[index] <= wdata;
                    end

                    default: begin
                        data_array[index] <= data_array[index];
                    end
                endcase
            end
        end
    end

endmodule
// (* keep_hierarchy = "yes" *)
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

//     // 16KB data memory: 4096 words * 32-bit
//     parameter WORDS = 4096;

//     // Force distributed RAM (asynchronous read, synchronous write)
//     (* ram_style = "block" *) reg [31:0] mem [0:WORDS-1];

//     wire [31:0] word = mem[alu_result[31:2]];
//     wire [1:0]  byte_off = alu_result[1:0];

//     // Write
//     always @(posedge clk) begin
//         if (mem_write) begin
//             case (funct3)
//                 3'b000: begin // SB
//                     case (byte_off)
//                         2'b00: mem[alu_result[31:2]] <= {word[31:8],  rs2_data[7:0]};
//                         2'b01: mem[alu_result[31:2]] <= {word[31:16], rs2_data[7:0], word[7:0]};
//                         2'b10: mem[alu_result[31:2]] <= {word[31:24], rs2_data[7:0], word[15:0]};
//                         2'b11: mem[alu_result[31:2]] <= {rs2_data[7:0], word[23:0]};
//                     endcase
//                 end
//                 3'b001: begin // SH
//                     case (byte_off[1])
//                         1'b0: mem[alu_result[31:2]] <= {word[31:16], rs2_data[15:0]};
//                         1'b1: mem[alu_result[31:2]] <= {rs2_data[15:0], word[15:0]};
//                     endcase
//                 end
//                 3'b010: begin // SW
//                     mem[alu_result[31:2]] <= rs2_data;
//                 end
//                 default: begin
//                     mem[alu_result[31:2]] <= mem[alu_result[31:2]]; // no-op
//                 end
//             endcase
//         end
//     end

//     // Read
//     always @(*) begin
//         if (mem_read) begin
//             case (funct3)
//                 3'b000: begin // LB
//                     case (byte_off)
//                         2'b00: data_mem_data = {{24{word[7]}},  word[7:0]};
//                         2'b01: data_mem_data = {{24{word[15]}}, word[15:8]};
//                         2'b10: data_mem_data = {{24{word[23]}}, word[23:16]};
//                         2'b11: data_mem_data = {{24{word[31]}}, word[31:24]};
//                     endcase
//                 end
//                 3'b001: begin // LH
//                     if (byte_off[1] == 1'b0)
//                         data_mem_data = {{16{word[15]}}, word[15:0]};
//                     else
//                         data_mem_data = {{16{word[31]}}, word[31:16]};
//                 end
//                 3'b010: begin // LW
//                     data_mem_data = word;
//                 end
//                 3'b100: begin // LBU
//                     case (byte_off)
//                         2'b00: data_mem_data = {24'b0, word[7:0]};
//                         2'b01: data_mem_data = {24'b0, word[15:8]};
//                         2'b10: data_mem_data = {24'b0, word[23:16]};
//                         2'b11: data_mem_data = {24'b0, word[31:24]};
//                     endcase
//                 end
//                 3'b101: begin // LHU
//                     if (byte_off[1] == 1'b0)
//                         data_mem_data = {16'b0, word[15:0]};
//                     else
//                         data_mem_data = {16'b0, word[31:16]};
//                 end
//                 default: data_mem_data = 32'b0;
//             endcase
//         end else begin
//             data_mem_data = 32'b0;
//         end
//     end
// endmodule
