module Display_Engine (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cmd_data,      // [15:8]=PetID, [7:0]=ExpID
    input  wire        we,            // write enable
    input  wire        invert_toggle, // 切換黑白反色
    input  wire        all_on_toggle, // 切換全亮模式
    input  wire        redraw_pulse,  // 手動重繪
    output reg         busy,
    output reg         sclk,
    output reg         mosi,
    output reg         dc,
    output reg         cs
);

    // --- 參數與狀態定義 ---
    localparam integer SCLK_DIV = 25;   // 50MHz / (25*2) = 1MHz SCLK
    localparam [6:0] X_OFFSET = 7'd0;   
    localparam [2:0] PAGE_BASE = 3'd0;  

    localparam [4:0] ST_BOOT         = 5'd0,
                     ST_INIT_NEXT    = 5'd1,
                     ST_CLEAR_PREP   = 5'd2, // 定位 Page
                     ST_CLEAR_DATA   = 5'd3, // 填入全亮數據
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

    // --- 寄存器定義 ---
    reg [4:0]  state, next_state;
    reg [4:0]  init_idx;
    reg [3:0]  clear_page; 
    reg [6:0]  clear_col;  
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

    // --- 尋址邏輯 ---
    wire [9:0] pixel_idx = ({4'd0, page, bit_row} << 5) + {4'd0, col};
    wire [17:0] start_addr = (cmd_data[15:8] * 4 + cmd_data[7:0]) * 1024;
    wire [17:0] target_word_addr = start_addr + (pixel_idx >> 4);
    wire [3:0]  bit_offset = pixel_idx[3:0];

    Picture_ROM rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .dout(current_pixel_word)
    );
    wire [15:0] current_pixel_word;

    // --- 初始化序列 ---
    function [7:0] init_cmd(input [4:0] idx);
        case (idx)
            5'd0:  init_cmd = 8'hAE;
            5'd1:  init_cmd = 8'hD5; 5'd2:  init_cmd = 8'h80;
            5'd3:  init_cmd = 8'hA8; 5'd4:  init_cmd = 8'h3F;
            5'd5:  init_cmd = 8'hD3; 5'd6:  init_cmd = 8'h00;
            5'd7:  init_cmd = 8'h40;
            5'd8:  init_cmd = 8'h8D; 5'd9:  init_cmd = 8'h14;
            5'd10: init_cmd = 8'h20; 5'd11: init_cmd = 8'h02;
            5'd12: init_cmd = 8'hA1; 5'd13: init_cmd = 8'hC8;
            5'd14: init_cmd = 8'hDA; 5'd15: init_cmd = 8'h02; // 修改為 02
            5'd16: init_cmd = 8'h81; 5'd17: init_cmd = 8'h7F;
            5'd18: init_cmd = 8'hD9; 5'd19: init_cmd = 8'hF1;
            5'd20: init_cmd = 8'hDB; 5'd21: init_cmd = 8'h40;
            5'd22: init_cmd = 8'hA4; // 恢復 RAM 模式
            5'd23: init_cmd = 8'hA6;
            5'd24: init_cmd = 8'hAF;
            default: init_cmd = 8'hAE;
        endcase
    endfunction

    // --- 狀態機 ---
    always @(posedge clk) begin
        if (reset) begin
            state <= ST_BOOT;
            busy <= 1'b1;
            cs <= 1'b1;
            wait_cnt <= 0;
            clear_page <= 0;
            clear_col <= 0;
            {page, col, bit_row} <= 0;
            invert_mode <= 1'b0;
            all_on_mode <= 1'b0;
        end else begin
            case (state)
                ST_BOOT: begin
                    busy <= 1'b1;
                    if (wait_cnt < 24'd500000) begin // 10ms 延時
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
                        state <= ST_CLEAR_PREP; // 強制進入清屏
                        clear_page <= 0;
                        clear_col <= 0;
                    end else begin
                        init_idx <= init_idx + 1'b1;
                        tx_byte <= init_cmd(init_idx + 1'b1);
                        tx_dc <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state <= ST_TX_SETUP;
                    end
                end

                ST_CLEAR_PREP: begin
                    busy <= 1'b1;
                    tx_byte <= (8'hB0 + {4'd0, clear_page}); // 指向當前頁
                    tx_dc <= 1'b0;
                    next_state <= ST_CLEAR_DATA;
                    state <= ST_TX_SETUP;
                end

                ST_CLEAR_DATA: begin
                    tx_byte <= 8'hFF; // 填滿白色
                    tx_dc <= 1'b1;
                    if (clear_col == 127) begin
                        clear_col <= 0;
                        if (clear_page == 7) state <= ST_IDLE; // 八頁全清完才準去 IDLE
                        else begin
                            clear_page <= clear_page + 1'b1;
                            state <= ST_CLEAR_PREP;
                        end
                    end else begin
                        clear_col <= clear_col + 1'b1;
                        next_state <= ST_CLEAR_DATA;
                        state <= ST_TX_SETUP;
                    end
                end

                ST_IDLE: begin
                    busy <= 1'b0;
                    cs <= 1'b1;
                    // 在 IDLE 狀態才處理外部請求
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

                // --- 繪製寵物區域 ---
                ST_PAGE_CMD0: begin
                    tx_byte <= (8'hB0 + PAGE_BASE + {5'd0, page});
                    tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD1;
                    state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD1: begin
                    tx_byte <= {4'h0, X_OFFSET[3:0]};
                    tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD2;
                    state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD2: begin
                    tx_byte <= {4'h1, X_OFFSET[6:4]};
                    tx_dc <= 1'b0;
                    next_state <= ST_DATA_REQ;
                    state <= ST_TX_SETUP;
                end
                ST_DATA_REQ: begin
                    rom_addr <= target_word_addr;
                    state <= ST_DATA_WAIT;
                end
                ST_DATA_WAIT: state <= ST_DATA_SAMPLE;
                ST_DATA_SAMPLE: begin
                    frame_byte[bit_row] <= (current_pixel_word[15 - bit_offset] != 16'd0);
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
                            state <= ST_PAGE_CMD0;
                        end
                    end else begin
                        col <= col + 1'b1;
                        state <= ST_DATA_REQ;
                    end
                end

                // --- SPI 物理層 ---
                ST_TX_SETUP: begin
                    cs <= 1'b0;
                    dc <= tx_dc;
                    mosi <= tx_byte[7];
                    tx_bit <= 3'd7;
                    div_cnt <= 0;
                    state <= ST_TX_HIGH;
                end
                ST_TX_HIGH: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk <= 1'b1;
                        div_cnt <= 0;
                        state <= ST_TX_LOW;
                    end else div_cnt <= div_cnt + 1'b1;
                end
                ST_TX_LOW: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk <= 1'b0;
                        div_cnt <= 0;
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
