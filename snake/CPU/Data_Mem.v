(* keep_hierarchy = "yes" *)
module Data_Memory (
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] rs2_data,
    input [31:0] alu_result,
    input [31:0] instruction,
    output reg [31:0] data_mem_data,
    // --- 新增的 I/O ---
    input  [3:0] btns,
    input  sw0,
    input  [6:0] vram_disp_addr,
    output [7:0] vram_disp_data
);
    wire [2:0] funct3 = instruction[14:12];

    // 判斷當前地址落在哪個區域
    wire is_ram  = (alu_result[15:12] == 4'h0 || alu_result[15:12] == 4'h2); // 0x0000 - 0x3FFF
    wire is_mmio = (alu_result[15:12] == 4'h8); // 0x8000
    wire is_vram = (alu_result[15:12] == 4'hA); // 0xA000

    // ==========================================
    // 1. Data RAM (4 個 Bank，支援 Byte-Write)
    // ==========================================
    parameter WORDS = 4096;
    (* ram_style = "block" *) reg [7:0] mem0 [0:WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem1 [0:WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem2 [0:WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem3 [0:WORDS-1];

    reg [3:0] byte_we;
    always @(*) begin
        if (mem_write && is_ram) begin
            case (funct3)
                3'b000: begin // SB
                    case (alu_result[1:0])
                        2'b00: byte_we = 4'b0001; 2'b01: byte_we = 4'b0010;
                        2'b10: byte_we = 4'b0100; 2'b11: byte_we = 4'b1000;
                    endcase
                end
                3'b001: begin // SH
                    case (alu_result[1:0])
                        2'b00: byte_we = 4'b0011; 2'b10: byte_we = 4'b1100;
                        default: byte_we = 4'b0000;
                    endcase
                end
                3'b010: byte_we = 4'b1111; // SW
                default: byte_we = 4'b0000;
            endcase
        end else begin
            byte_we = 4'b0000;
        end
    end

    wire [11:0] ram_idx = alu_result[13:2];
    always @(posedge clk) begin
        if (byte_we[0]) mem0[ram_idx] <= rs2_data[7:0];
        if (byte_we[1]) mem1[ram_idx] <= rs2_data[15:8];
        if (byte_we[2]) mem2[ram_idx] <= rs2_data[23:16];
        if (byte_we[3]) mem3[ram_idx] <= rs2_data[31:24];
    end

    // ==========================================
    // 2. VRAM (128 Bytes，雙埠，給 OLED)
    // ==========================================
    (* ram_style = "distributed" *) reg [7:0] vram [0:127];
    wire [6:0] vram_idx = alu_result[6:0];
    
    always @(posedge clk) begin
        // CPU 寫入 VRAM (貪吃蛇畫點)
        if (mem_write && is_vram) vram[vram_idx] <= rs2_data[7:0];
    end
    
    // OLED 驅動器讀取 (Port B)
    assign vram_disp_data = vram[vram_disp_addr];

    // ==========================================
    // 3. MMIO (計時器與按鈕)
    // ==========================================
    reg [31:0] timer_cnt;
    always @(posedge clk) timer_cnt <= timer_cnt + 1;

    wire [31:0] mmio_data = (alu_result[3:0] == 4'h0) ? {28'b0, btns} :
                            (alu_result[3:0] == 4'h4) ? timer_cnt :
                            (alu_result[3:0] == 4'h8) ? {31'b0, sw0} : 32'b0;

    // ==========================================
    // 4. 同步讀取邏輯 (維持你原本的時序)
    // ==========================================
    reg [7:0] r0, r1, r2, r3;
    reg [31:0] addr_reg;
    reg is_mmio_reg, is_vram_reg;
    reg [31:0] mmio_data_reg;
    reg [7:0] vram_data_reg;

    always @(posedge clk) begin
        if (mem_read) begin
            // RAM 讀取
            r0 <= mem0[ram_idx];
            r1 <= mem1[ram_idx];
            r2 <= mem2[ram_idx];
            r3 <= mem3[ram_idx];
            
            // 暫存地址與其他資料以保持一週期的延遲
            addr_reg <= alu_result;
            is_mmio_reg <= is_mmio;
            is_vram_reg <= is_vram;
            mmio_data_reg <= mmio_data;
            vram_data_reg <= vram[vram_idx];
        end
    end

    wire [31:0] ram_data = {r3, r2, r1, r0};
    wire [31:0] raw_read = is_vram_reg ? {24'b0, vram_data_reg} :
                           is_mmio_reg ? mmio_data_reg : ram_data;

    wire [1:0] byte_off = addr_reg[1:0];

    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB
                    case (byte_off)
                        2'b00: data_mem_data = {{24{raw_read[7]}},  raw_read[7:0]};
                        2'b01: data_mem_data = {{24{raw_read[15]}}, raw_read[15:8]};
                        2'b10: data_mem_data = {{24{raw_read[23]}}, raw_read[23:16]};
                        2'b11: data_mem_data = {{24{raw_read[31]}}, raw_read[31:24]};
                    endcase
                end
                3'b001: begin // LH
                    if (byte_off[1] == 1'b0)
                        data_mem_data = {{16{raw_read[15]}}, raw_read[15:0]};
                    else
                        data_mem_data = {{16{raw_read[31]}}, raw_read[31:16]};
                end
                3'b010: data_mem_data = raw_read; // LW
                3'b100: begin // LBU
                    case (byte_off)
                        2'b00: data_mem_data = {24'b0, raw_read[7:0]};
                        2'b01: data_mem_data = {24'b0, raw_read[15:8]};
                        2'b10: data_mem_data = {24'b0, raw_read[23:16]};
                        2'b11: data_mem_data = {24'b0, raw_read[31:24]};
                    endcase
                end
                3'b101: begin // LHU
                    if (byte_off[1] == 1'b0)
                        data_mem_data = {16'b0, raw_read[15:0]};
                    else
                        data_mem_data = {16'b0, raw_read[31:16]};
                end
                default: data_mem_data = 32'b0;
            endcase
        end else begin
            data_mem_data = 32'b0;
        end
    end
endmodule