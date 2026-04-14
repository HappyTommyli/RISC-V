module Display_Engine (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cmd_data,    // [15:8]=PetID, [7:0]=ExpID
    input  wire        we,          // 0x9000 write enable
    input  wire        invert_toggle, // 切换黑白反色
    input  wire        all_on_toggle, // 切换全亮模式
    input  wire        redraw_pulse,  // 手动重绘
    output reg         busy,
    output reg         sclk,
    output reg         mosi,
    output reg         dc,
    output reg         cs
);

    // --- 参数与状态定义 ---
    localparam integer SCLK_DIV = 50; 
    localparam [6:0] X_OFFSET = 7'd0; 
    localparam [2:0] PAGE_BASE = 3'd0; 

    localparam [4:0] ST_BOOT         = 5'd0,
                     ST_INIT_NEXT    = 5'd1,
                     ST_IDLE         = 5'd2,
                     ST_PAGE_CMD0    = 5'd3,
                     ST_PAGE_CMD1    = 5'd4,
                     ST_PAGE_CMD2    = 5'd5,
                     ST_DATA_REQ     = 5'd6,
                     ST_DATA_WAIT    = 5'd7,
                     ST_DATA_SAMPLE  = 5'd8,
                     ST_DATA_SEND    = 5'd9,
                     ST_DATA_NEXT    = 5'd10,
                     ST_TX_SETUP     = 5'd11,
                     ST_TX_HIGH      = 5'd12,
                     ST_TX_LOW       = 5'd13;

    localparam [4:0] INIT_LAST = 5'd24;

    // --- 寄存器定义 ---
    reg [4:0]  state, next_state;
    reg [4:0]  init_idx;
    reg [1:0]  page;    
    reg [5:0]  col;     
    reg [2:0]  bit_row; 
    reg [7:0]  frame_byte;
    reg [17:0] start_addr; 
    reg [17:0] rom_addr;
    reg [7:0]  tx_byte;
    reg        tx_dc;
    reg [2:0]  tx_bit;
    reg [7:0]  div_cnt;
    reg        invert_mode, all_on_mode;
    reg [17:0] last_draw_addr;

    // --- 核心逻辑：寻址与像素提取 ---
    // 假设 ROM 为 16 位宽，总像素 32x32=1024
    // pixel_idx 为 0~1023
    wire [9:0]  pixel_idx = ({4'd0, page, bit_row} << 5) + {4'd0, col};
    
    // 计算 ROM 字地址（1024 像素 / 16 位每字 = 64 个字）
    wire [17:0] target_word_addr = start_addr + (pixel_idx >> 4); 
    
    // 计算在 16 位字中的偏移 (0~15)
    // 假设存储时 16'h8000 是最左边的像素，则用 15 - offset
    wire [3:0]  bit_offset = pixel_idx[3:0];

    wire [15:0] current_pixel_word;
    Picture_ROM rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .dout(current_pixel_word)
    );

    // --- 初始化命令序列 ---
    function [7:0] init_cmd(input [4:0] idx);
        case (idx)
            5'd0:  init_cmd = 8'hAE; // display off
            5'd1:  init_cmd = 8'hD5; 5'd2:  init_cmd = 8'h80;
            5'd3:  init_cmd = 8'hA8; 5'd4:  init_cmd = 8'h3F;
            5'd5:  init_cmd = 8'hD3; 5'd6:  init_cmd = 8'h00;
            5'd7:  init_cmd = 8'h40;
            5'd8:  init_cmd = 8'h8D; 5'd9:  init_cmd = 8'h14;
            5'd10: init_cmd = 8'h20; 5'd11: init_cmd = 8'h02; // Page addressing mode
            5'd12: init_cmd = 8'hA1; // Segment remap (X-flip)
            5'd13: init_cmd = 8'hC8; // COM scan direction (Y-flip)
            5'd14: init_cmd = 8'hDA; 5'd15: init_cmd = 8'h12;
            5'd16: init_cmd = 8'h81; 5'd17: init_cmd = 8'hCF; // Contrast
            5'd18: init_cmd = 8'hD9; 5'd19: init_cmd = 8'hF1;
            5'd20: init_cmd = 8'hDB; 5'd21: init_cmd = 8'h40;
            5'd22: init_cmd = 8'hA4; // Resume RAM
            5'd23: init_cmd = 8'hA6; // Normal display
            5'd24: init_cmd = 8'hAF; // display on
            default: init_cmd = 8'hAE;
        endcase
    endfunction

    // --- 状态机逻辑 ---
    always @(posedge clk) begin
        if (reset) begin
            state <= ST_BOOT;
            busy <= 1'b1;
            cs <= 1'b1;
            {page, col, bit_row} <= 0;
            invert_mode <= 1'b0;
            all_on_mode <= 1'b0;
            start_addr <= 18'd0;
        end else begin
            case (state)
                ST_BOOT: begin
                    busy    <= 1'b1;
                    tx_byte <= init_cmd(5'd0);
                    tx_dc   <= 1'b0;
                    init_idx <= 5'd0;
                    next_state <= ST_INIT_NEXT;
                    state   <= ST_TX_SETUP;
                end

                ST_INIT_NEXT: begin
                    if (init_idx == INIT_LAST) begin
                        busy <= 1'b0;
                        state <= ST_IDLE;
                    end else begin
                        init_idx <= init_idx + 1'b1;
                        tx_byte <= init_cmd(init_idx + 1'b1);
                        tx_dc <= 1'b0;
                        init_idx <= init_idx + 1'b1;
                        tx_byte <= init_cmd(init_idx + 1'b1);
                        tx_dc <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state <= ST_TX_SETUP;
                    end
                end

                ST_IDLE: begin
                    busy <= 1'b0;
                    cs <= 1'b1;
                    if (invert_toggle) begin
                        tx_byte <= invert_mode ? 8'hA6 : 8'hA7;
                        tx_dc <= 1'b0;
                        invert_mode <= ~invert_mode;
                        busy <= 1'b1;
                        next_state <= ST_IDLE;
                        state <= ST_TX_SETUP;
                    end else if (all_on_toggle) begin
                        tx_byte <= all_on_mode ? 8'hA4 : 8'hA5;
                        tx_dc <= 1'b0;
                        all_on_mode <= ~all_on_mode;
                        busy <= 1'b1;
                        next_state <= ST_IDLE;
                        state <= ST_TX_SETUP;
                    end else if (we || redraw_pulse) begin
                        // 开始绘制 32x32 区域
                        page <= 0; col <= 0; bit_row <= 0;
                        busy <= 1'b1;
                        state <= ST_PAGE_CMD0;
                    end
                end

                // 设置 Page 地址 (B0-B7)
                ST_PAGE_CMD0: begin
                    tx_byte <= (8'hB0 + PAGE_BASE + {6'd0, page});
                    tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD1;
                    state <= ST_TX_SETUP;
                    state <= ST_TX_SETUP;
                end

                // 设置列起始地址低 4 位
                ST_PAGE_CMD1: begin
                    tx_byte <= {4'h0, X_OFFSET[3:0]};
                    tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD2;
                    state <= ST_TX_SETUP;
                    state <= ST_TX_SETUP;
                end

                // 设置列起始地址高 4 位
                ST_PAGE_CMD2: begin
                    tx_byte <= {4'h1, X_OFFSET[6:4]};
                    tx_dc <= 1'b0;
                    next_state <= ST_DATA_REQ;
                    state <= ST_TX_SETUP;
                    state <= ST_TX_SETUP;
                end

                // 请求 ROM 数据
                ST_DATA_REQ: begin
                    rom_addr <= target_word_addr;
                    state <= ST_DATA_WAIT;
                end

                ST_DATA_WAIT: state <= ST_DATA_SAMPLE;
                ST_DATA_WAIT: state <= ST_DATA_SAMPLE;

                // 采样并构造字节 (SSD1306 在 Page 模式下，1 个 Byte 对应垂直 8 个像素)
                ST_DATA_SAMPLE: begin
                    // 提取单 bit 像素。注意 15-bit_offset 取决于你存入 ROM 的端序
                    frame_byte[bit_row] <= (current_pixel_word[15 - bit_offset] != 1'b0);
                    
                    if (bit_row == 3'd7) begin
                        state <= ST_DATA_SEND; // 垂直 8 bits 凑齐，发送
                    end else begin
                        bit_row <= bit_row + 1'b1;
                        state <= ST_DATA_REQ; // 继续读下一点
                    end
                end

                ST_DATA_SEND: begin
                    tx_byte <= frame_byte;
                    tx_dc   <= 1'b1;
                    next_state <= ST_DATA_NEXT;
                    state <= ST_TX_SETUP;
                    state <= ST_TX_SETUP;
                end

                ST_DATA_NEXT: begin
                    bit_row <= 3'd0;
                    if (col == 6'd31) begin
                        col <= 6'd0;
                        if (page == 2'd3) state <= ST_IDLE; // 32 像素高 = 4 Pages
                        else begin
                            page <= page + 1'b1;
                            state <= ST_PAGE_CMD0;
                        end
                    end else begin
                        col <= col + 1'b1;
                        state <= ST_DATA_REQ;
                    end
                end

                // --- SPI 物理传输状态 ---
                ST_TX_SETUP: begin
                    cs <= 1'b0;
                    dc <= tx_dc;
                    mosi <= tx_byte[7];
                    cs <= 1'b0;
                    dc <= tx_dc;
                    mosi <= tx_byte[7];
                    tx_bit <= 3'd7;
                    div_cnt <= 8'd0;
                    state <= ST_TX_HIGH;
                end

                ST_TX_HIGH: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk <= 1'b1;
                        div_cnt <= 8'd0;
                        state <= ST_TX_LOW;
                    end else div_cnt <= div_cnt + 1'b1;
                    end else div_cnt <= div_cnt + 1'b1;
                end

                ST_TX_LOW: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk <= 1'b0;
                        div_cnt <= 8'd0;
                        if (tx_bit == 3'd0) begin
                            // 这里不立即拉高 CS 以保持传输连贯性
                            state <= next_state;
                        end else begin
                            tx_bit <= tx_bit - 1'b1;
                            mosi <= tx_byte[tx_bit - 1'b1];
                            state <= ST_TX_HIGH;
                        end
                    end else div_cnt <= div_cnt + 1'b1;
                    end else div_cnt <= div_cnt + 1'b1;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule