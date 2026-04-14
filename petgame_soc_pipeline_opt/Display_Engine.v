module Display_Engine (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cmd_data,    // [15:8]=PetID, [7:0]=ExpID
    input  wire        we,          // 寫入使能
    output reg         busy,
    output reg         sclk,
    output reg         mosi,
    output reg         dc,
    output reg         cs
);

    // --- 參數設定 ---
    localparam integer SCLK_DIV = 50;   // 100MHz -> 1MHz SCLK
    localparam [6:0] X_OFFSET  = 7'd48; // 水平居中 (128-32)/2 = 48
    localparam [2:0] PAGE_BASE = 3'd4;  // 垂直下方 (Page 4,5,6,7 為螢幕下半部)

    // --- 狀態機定義 ---
    localparam [4:0] ST_BOOT        = 5'd0;
    localparam [4:0] ST_INIT_NEXT   = 5'd1;
    localparam [4:0] ST_FILL_PREP   = 5'd2; // 開始填充背景
    localparam [4:0] ST_FILL_DATA   = 5'd3; // 填充全白數據
    localparam [4:0] ST_IDLE        = 5'd4;
    localparam [4:0] ST_PAGE_CMD0   = 5'd5; // 設置局部更新的 Page
    localparam [4:0] ST_PAGE_CMD1   = 5'd6; // 設置局部更新的 Column Low
    localparam [4:0] ST_PAGE_CMD2   = 5'd7; // 設置局部更新的 Column High
    localparam [4:0] ST_DATA_REQ    = 5'd8;
    localparam [4:0] ST_DATA_WAIT   = 5'd9;
    localparam [4:0] ST_DATA_SAMPLE = 5'd10;
    localparam [4:0] ST_DATA_SEND   = 5'd11;
    localparam [4:0] ST_DATA_NEXT   = 5'd12;
    localparam [4:0] ST_TX_SETUP    = 5'd13;
    localparam [4:0] ST_TX_HIGH     = 5'd14;
    localparam [4:0] ST_TX_LOW      = 5'd15;

    localparam [4:0] INIT_LAST = 5'd24;

    // --- 內部寄存器 ---
    reg [4:0]  state, next_state;
    reg [4:0]  init_idx;
    reg [10:0] fill_cnt;    // 用於填充全螢幕 (128*8 = 1024 字節)
    
    reg [1:0]  page;        // 0..3 (對應 32 像素高)
    reg [5:0]  col;         // 0..31
    reg [2:0]  bit_row;     // 一個 byte 內的 0..7 bit
    reg [7:0]  frame_byte;

    reg [17:0] rom_addr;
    reg [7:0]  tx_byte;
    reg        tx_dc;
    reg [2:0]  tx_bit;
    reg [7:0]  div_cnt;

    // --- 輸入處理 ---
    wire [1:0]  cmd_pet = (cmd_data[15:8] < 8'd4) ? cmd_data[9:8] : 2'd0;
    wire [1:0]  cmd_exp = (cmd_data[7:0]  < 8'd3) ? cmd_data[1:0] : 2'd0;
    wire [17:0] cmd_start_addr = (({16'd0, cmd_pet} * 18'd3) + {16'd0, cmd_exp}) << 10;

    // ROM 地址計算 (32x32 局部)
    wire [5:0] y_in_tile = {page, 3'b000} + bit_row;
    wire [9:0] pixel_idx = ({4'd0, y_in_tile} << 5) + {4'd0, col};
    wire [15:0] current_pixel;

    Picture_ROM rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .dout(current_pixel)
    );

    // --- 初始化命令表 ---
    function [7:0] init_cmd;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  init_cmd = 8'hAE; // 關閉顯示
                5'd1:  init_cmd = 8'hD5; 5'd2:  init_cmd = 8'h80;
                5'd3:  init_cmd = 8'hA8; 5'd4:  init_cmd = 8'h3F;
                5'd5:  init_cmd = 8'hD3; 5'd6:  init_cmd = 8'h00;
                5'd7:  init_cmd = 8'h40;
                5'd8:  init_cmd = 8'h8D; 5'd9:  init_cmd = 8'h14;
                5'd10: init_cmd = 8'h20; 5'd11: init_cmd = 8'h02; // 頁地址模式
                5'd12: init_cmd = 8'hA1; // 段重定向
                5'd13: init_cmd = 8'hC8; // COM 掃描方向
                5'd14: init_cmd = 8'hDA; 5'd15: init_cmd = 8'h12;
                5'd16: init_cmd = 8'h81; 5'd17: init_cmd = 8'hCF;
                5'd18: init_cmd = 8'hD9; 5'd19: init_cmd = 8'hF1;
                5'd20: init_cmd = 8'hDB; 5'd21: init_cmd = 8'h40;
                5'd22: init_cmd = 8'hA4; // 全亮開啟
                5'd23: init_cmd = 8'hA6; // 正常顯示 (A7為反相)
                5'd24: init_cmd = 8'hAF; // 開啟顯示
                default: init_cmd = 8'hAE;
            endcase
        end
    endfunction

    // 閾值判定 (RGB565 -> Mono)
    function pixel_to_mono;
        input [15:0] rgb565;
        reg [6:0] lum;
        begin
            lum = {2'b00, rgb565[15:11]} + {1'b0, rgb565[10:5]} + {2'b00, rgb565[4:0]};
            pixel_to_mono = (lum >= 7'd24); 
        end
    endfunction

    // --- 主狀態機 ---
    always @(posedge clk) begin
        if (reset) begin
            state <= ST_BOOT;
            busy <= 1'b1;
            cs <= 1'b1;
            sclk <= 1'b0;
            fill_cnt <= 11'd0;
            init_idx <= 5'd0;
        end else begin
            case (state)
                ST_BOOT: begin
                    tx_byte <= init_cmd(0);
                    tx_dc <= 1'b0;
                    next_state <= ST_INIT_NEXT;
                    state <= ST_TX_SETUP;
                end

                ST_INIT_NEXT: begin
                    if (init_idx == INIT_LAST) begin
                        fill_cnt <= 11'd0;
                        state <= ST_FILL_PREP; // 初始化完，去填滿背景
                    end else begin
                        init_idx <= init_idx + 1'b1;
                        tx_byte <= init_cmd(init_idx + 1'b1);
                        tx_dc <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state <= ST_TX_SETUP;
                    end
                end

                // --- 填充全螢幕背景邏輯 ---
                ST_FILL_PREP: begin
                    // 強制回到 Page 0, Column 0
                    tx_byte <= 8'hB0; // Page 0
                    tx_dc <= 1'b0;
                    next_state <= ST_FILL_DATA;
                    state <= ST_TX_SETUP;
                end

                ST_FILL_DATA: begin
                    tx_byte <= 8'hFF; // 填充常亮 (1=亮, 0=滅)
                    tx_dc <= 1'b1;
                    if (fill_cnt == 11'd1023) begin
                        state <= ST_IDLE;
                    end else begin
                        fill_cnt <= fill_cnt + 1'b1;
                        next_state <= ST_FILL_DATA;
                        state <= ST_TX_SETUP;
                    end
                end

                ST_IDLE: begin
                    busy <= 1'b0;
                    cs <= 1'b1;
                    if (we) begin
                        busy <= 1'b1;
                        page <= 2'd0;
                        col <= 6'd0;
                        bit_row <= 3'd0;
                        state <= ST_PAGE_CMD0;
                    end
                end

                // --- 定位到 32x32 區域 ---
                ST_PAGE_CMD0: begin
                    tx_byte <= (8'hB0 + PAGE_BASE + {5'd0, page});
                    tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD1;
                    state <= ST_TX_SETUP;
                end

                ST_PAGE_CMD1: begin
                    tx_byte <= {4'h0, X_OFFSET[3:0]}; // Column Low
                    tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD2;
                    state <= ST_TX_SETUP;
                end

                ST_PAGE_CMD2: begin
                    tx_byte <= {4'h1, X_OFFSET[6:4]}; // Column High
                    tx_dc <= 1'b0;
                    next_state <= ST_DATA_REQ;
                    state <= ST_TX_SETUP;
                end

                // --- 讀取並發送像素 ---
                ST_DATA_REQ: begin
                    rom_addr <= cmd_start_addr + {8'd0, pixel_idx};
                    state <= ST_DATA_WAIT;
                end

                ST_DATA_WAIT: state <= ST_DATA_SAMPLE;

                ST_DATA_SAMPLE: begin
                    frame_byte[bit_row] <= pixel_to_mono(current_pixel);
                    if (bit_row == 3'd7) state <= ST_DATA_SEND;
                    else begin
                        bit_row <= bit_row + 1'b1;
                        state <= ST_DATA_REQ;
                    end
                end

                ST_DATA_SEND: begin
                    tx_byte <= frame_byte;
                    tx_dc <= 1'b1;
                    next_state <= ST_DATA_NEXT;
                    state <= ST_TX_SETUP;
                end

                ST_DATA_NEXT: begin
                    bit_row <= 3'd0;
                    if (col == 6'd31) begin
                        col <= 6'd0;
                        if (page == 2'd3) state <= ST_IDLE; // 畫完 32x32
                        else begin
                            page <= page + 1'b1;
                            state <= ST_PAGE_CMD0;
                        end
                    end else begin
                        col <= col + 1'b1;
                        state <= ST_DATA_REQ;
                    end
                end

                // --- SPI 物理傳輸層 ---
                ST_TX_SETUP: begin
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
                end

                ST_TX_LOW: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk <= 1'b0;
                        div_cnt <= 8'd0;
                        if (tx_bit == 3'd0) state <= next_state;
                        else begin
                            tx_bit <= tx_bit - 1'b1;
                            mosi <= tx_byte[tx_bit - 1'b1];
                            state <= ST_TX_HIGH;
                        end
                    end else div_cnt <= div_cnt + 1'b1;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule