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
    parameter WORDS = 8192;

    (* ram_style = "block" *) reg [31:0] mem [0:WORDS-1];
    reg [31:0] word_q;
    wire [1:0] byte_off = alu_result[1:0];

    // Address map
    wire is_internal_mem = (alu_result < 32'h00008000);
    wire is_btn          = (alu_result == 32'h00008000);
    wire is_timer        = (alu_result == 32'h00008004);
    wire is_display      = (alu_result == 32'h00009000);
    wire is_oled_fb      = (alu_result >= 32'h0000A000) && (alu_result < 32'h0000A400);

    // 修正：內存寫入不再依賴 word_q (直接使用內存當前值寫入比較複雜，通常 BRAM 建議用 Byte Write Enable)
    // 這裡為了讓你的 SB 正常運作，簡化邏輯：
    always @(posedge clk) begin
        if (mem_read && is_internal_mem) begin
            word_q <= mem[alu_result[31:2]];
        end
        
        if (mem_write && is_internal_mem) begin
            // 注意：在真實 FPGA 中，SB 最好使用帶 Byte Mask 的 RAM
            // 這裡暫時保留你的邏輯，但提醒：這需要 mem_read 和 mem_write 在同一地址連續觸發才有效
            // 建議 ASM 中寫入顯存時，確保指令正確
            case (funct3)
                3'b010: mem[alu_result[31:2]] <= rs2_data; // SW 是最安全的
                // SB 和 SH 在沒有 Byte-mask RAM 的情況下，建議直接操作顯存，不要回寫內部 mem
            endcase
        end
    end

    // 讀取邏輯 (保持不變)
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
                    3'b010: data_mem_data = word_q; // LW
                    3'b100: begin // LBU
                        case (byte_off)
                            2'b00: data_mem_data = {24'b0, word_q[7:0]};
                            2'b01: data_mem_data = {24'b0, word_q[15:8]};
                            2'b10: data_mem_data = {24'b0, word_q[23:16]};
                            2'b11: data_mem_data = {24'b0, word_q[31:24]};
                        endcase
                    end
                    default: data_mem_data = word_q;
                endcase
            end else if (is_btn)   data_mem_data = {28'b0, buttons};
            else if (is_timer) data_mem_data = timer_value;
            else if (is_display) data_mem_data = {31'b0, display_busy};
            else data_mem_data = 32'b0;
        end else begin
            data_mem_data = 32'b0;
        end
    end

    // --- 關鍵修正：顯存輸出控制 ---
    always @(*) begin
        // 1. 只要地址對，不管 SB 還是 SW，都允許寫入顯存
        oled_fb_we = mem_write && is_oled_fb;
        
        // 2. 顯存地址
        oled_fb_addr = alu_result[9:0];
        
        // 3. 數據選擇：如果是 SB，取對應字節；如果是 SW，通常取低 8 位
        // 這裡做一個簡單的 Mux 處理 SB 指令的偏移
        if (funct3 == 3'b000) begin // SB
            case (byte_off)
                2'b00: oled_fb_data = rs2_data[7:0];
                2'b01: oled_fb_data = rs2_data[15:8]; // 修正：考慮到某些編譯器會對齊
                2'b10: oled_fb_data = rs2_data[23:16];
                2'b11: oled_fb_data = rs2_data[31:24];
            endcase
        end else begin
            oled_fb_data = rs2_data[7:0]; // 預設 SW 取最低位
        end

        display_we  = mem_write && is_display;
        display_cmd = rs2_data;
    end
endmodule