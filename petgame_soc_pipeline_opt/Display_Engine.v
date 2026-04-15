module Display_Engine (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cmd_data,      
    input  wire        we,            
    input  wire        invert_toggle, 
    input  wire        all_on_toggle, 
    input  wire        redraw_pulse,  
    output reg         busy,
    output reg         sclk,
    output reg         mosi,
    output reg         dc,
    output reg         cs
);

    // --- 參數定義 ---
    localparam integer SCLK_DIV = 25;   
    localparam [6:0] X_OFFSET = 7'd0;   
    localparam [2:0] PAGE_BASE = 3'd0;  

    localparam [4:0] ST_BOOT         = 5'd0,
                     ST_INIT_NEXT    = 5'd1,
                     ST_CLEAR_PREP   = 5'd2, // 強制重置座標指令
                     ST_CLEAR_DATA   = 5'd3, // 噴發 1024 字節數據
                     ST_IDLE         = 5'd4,
                     ST_PAGE_CMD0    = 5'd5,
                     ST_PAGE_CMD1    = 5'd6,
                     ST_PAGE_CMD2    = 5'd7,
                     ST_DATA_REQ     = 5'd8,
                     ST_DATA_WAIT    = 5'd9,
                     ST_DATA_SAMPLE  = 5'd10,
                     ST_DATA_SEND    = 5'd11,
                     ST_DATA_NEXT    = 5'd12,
                     ST_TX_SETUP     = 5'd13,
                     ST_TX_HIGH      = 5'd14,
                     ST_TX_LOW       = 5'd15;

    localparam [4:0] INIT_LAST = 5'd24;

    // --- 寄存器 ---
    reg [4:0]  state, next_state;
    reg [4:0]  init_idx;
    reg [10:0] clear_cnt; // 用於計算清屏 1024 字節
    reg [1:0]  page;    
    reg [5:0]  col;     
    reg [2:0]  bit_row; 
    reg [7:0]  frame_byte;
    reg [17:0] rom_addr;
    reg [7:0]  tx_byte;
    reg        tx_dc;
    reg [2:0]  tx_bit;
    reg [7:0]  div_cnt;
    reg        invert_mode, all_on_mode;
    reg [23:0] wait_cnt; 

    // --- ROM 介面 ---
    wire [15:0] current_pixel_word;
    wire [9:0]  pixel_idx = ({4'd0, page, bit_row} << 5) + {4'd0, col};
    wire [17:0] start_addr = (cmd_data[15:8] * 4 + cmd_data[7:0]) * 1024;
    wire [17:0] target_word_addr = start_addr + (pixel_idx >> 4);
    wire [3:0]  bit_offset = pixel_idx[3:0];

    Picture_ROM rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .dout(current_pixel_word)
    );

    // --- 指令配置 (水平模式) ---
    function [7:0] init_cmd(input [4:0] idx);
        case (idx)
            5'd0:  init_cmd = 8'hAE;
            5'd1:  init_cmd = 8'hD5; 5'd2:  init_cmd = 8'h80;
            5'd3:  init_cmd = 8'hA8; 5'd4:  init_cmd = 8'h3F;
            5'd5:  init_cmd = 8'hD3; 5'd6:  init_cmd = 8'h00;
            5'd7:  init_cmd = 8'h40;
            5'd8:  init_cmd = 8'h8D; 5'd9:  init_cmd = 8'h14;
            5'd10: init_cmd = 8'h20; 5'd11: init_cmd = 8'h00; // 00 = 水平地址模式
            5'd12: init_cmd = 8'hA1; 5'd13: init_cmd = 8'hC8;
            5'd14: init_cmd = 8'hDA; 5'd15: init_cmd = 8'h02; 
            5'd16: init_cmd = 8'h81; 5'd17: init_cmd = 8'h7F;
            5'd18: init_cmd = 8'hD9; 5'd19: init_cmd = 8'hF1;
            5'd20: init_cmd = 8'hDB; 5'd21: init_cmd = 8'h40;
            5'd22: init_cmd = 8'hA4; 
            5'd23: init_cmd = 8'hA6;
            5'd24: init_cmd = 8'hAF;
            default: init_cmd = 8'hAE;
        endcase
    endfunction

    // --- 主狀態機 ---
    always @(posedge clk) begin
        if (reset) begin
            state <= ST_BOOT;
            busy <= 1'b1;
            cs <= 1'b1;
            wait_cnt <= 0;
            clear_cnt <= 0;
            {page, col, bit_row} <= 0;
            invert_mode <= 1'b0;
            all_on_mode <= 1'b0;
        end else begin
            case (state)
                ST_BOOT: begin
                    busy <= 1'b1;
                    if (wait_cnt < 24'd1000000) begin // 20ms 等待電源穩定
                        wait_cnt <= wait_cnt + 1;
                    end else begin
                        init_idx <= 0;
                        tx_byte <= init_cmd(0);
                        tx_dc <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state <= ST_TX_SETUP;
                    end
                end

                ST_INIT_NEXT: begin
                    if (init_idx == INIT_LAST) begin
                        state <= ST_CLEAR_PREP;
                        clear_cnt <= 0;
                    end else begin
                        init_idx <= init_idx + 1'b1;
                        tx_byte <= init_cmd(init_idx + 1'b1);
                        tx_dc <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state <= ST_TX_SETUP;
                    end
                end

                // --- 清屏準備：強制座標重歸 (0,0) ---
                ST_CLEAR_PREP: begin
                    tx_dc <= 1'b0;
                    case (clear_cnt[2:0])
                        3'd0: tx_byte <= 8'h21; // Set Column Range
                        3'd1: tx_byte <= 8'h00; // Start 0
                        3'd2: tx_byte <= 8'h7F; // End 127
                        3'd3: tx_byte <= 8'h22; // Set Page Range
                        3'd4: tx_byte <= 8'h00; // Start 0
                        3'd5: tx_byte <= 8'h07; // End 7
                        default: tx_byte <= 8'h00;
                    endcase
                    
                    if (clear_cnt[2:0] == 3'd5) begin
                        clear_cnt <= 0;
                        next_state <= ST_CLEAR_DATA;
                    end else begin
                        clear_cnt <= clear_cnt + 1;
                        next_state <= ST_CLEAR_PREP;
                    end
                    state <= ST_TX_SETUP;
                end

                // --- 噴發全亮數據 (1024 Bytes) ---
                ST_CLEAR_DATA: begin
                    tx_byte <= 8'hFF; // 全亮
                    tx_dc <= 1'b1;
                    if (clear_cnt == 11'd1023) begin
                        state <= ST_IDLE;
                    end else begin
                        clear_cnt <= clear_cnt + 1;
                        next_state <= ST_CLEAR_DATA;
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
                        page <= 0; col <= 0; bit_row <= 0;
                        busy <= 1'b1;
                        state <= ST_PAGE_CMD0;
                    end
                end

                // --- 繪製寵物圖像 (32x32) ---
                ST_PAGE_CMD0: begin
                    // 繪圖前也要重設座標，因為現在是水平模式
                    tx_byte <= 8'h21; tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD1; state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD1: begin
                    tx_byte <= X_OFFSET; tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD2; state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD2: begin
                    tx_byte <= X_OFFSET + 31; tx_dc <= 1'b0;
                    next_state <= ST_DATA_REQ; state <= ST_TX_SETUP;
                end
                // ... (後續 DATA_REQ 邏輯保持一致，水平模式會自動處理換行) ...
                ST_DATA_REQ: begin
                    rom_addr <= target_word_addr;
                    state <= ST_DATA_WAIT;
                end
                ST_DATA_WAIT: state <= ST_DATA_SAMPLE;
                ST_DATA_SAMPLE: begin
                    frame_byte[bit_row] <= (current_pixel_word[15 - bit_offset] != 0);
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
                    bit_row <= 0;
                    if (col == 31) begin
                        col <= 0;
                        if (page == 3) state <= ST_IDLE;
                        else begin
                            page <= page + 1'b1;
                            state <= ST_DATA_REQ; // 水平模式會自動換 Page，不需重新發命令
                        end
                    end else begin
                        col <= col + 1'b1;
                        state <= ST_DATA_REQ;
                    end
                end

                // --- SPI 物理層 ---
                ST_TX_SETUP: begin
                    cs <= 1'b0; dc <= tx_dc; mosi <= tx_byte[7];
                    tx_bit <= 3'd7; div_cnt <= 0; state <= ST_TX_HIGH;
                end
                ST_TX_HIGH: begin
                    if (div_cnt == SCLK_DIV-1) begin
                        sclk <= 1'b1; div_cnt <= 0; state <= ST_TX_LOW;
                    end else div_cnt <= div_cnt + 1'b1;
                end
                ST_TX_LOW: begin
                    if (div_cnt == SCLK_DIV-1) begin
                        sclk <= 1'b0; div_cnt <= 0;
                        if (tx_bit == 0) state <= next_state;
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
