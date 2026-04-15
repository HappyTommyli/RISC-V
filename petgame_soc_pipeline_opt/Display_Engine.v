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

    localparam integer SCLK_DIV       = 25;
    localparam [6:0]   X_OFFSET       = 7'd0;
    localparam [6:0]   IMG_W_BYTES    = 7'd32;
    localparam [2:0]   IMG_PAGES      = 3'd4;
    localparam [11:0]  FRAME_STRIDE   = 12'd128; // 32x32 -> 128 bytes
    localparam [7:0]   ROM_NUM_FRAMES = 8'd3;    // cat, dog, duck

    localparam [4:0] ST_BOOT        = 5'd0,
                     ST_INIT_NEXT   = 5'd1,
                     ST_CLEAR_PREP  = 5'd2,
                     ST_CLEAR_DATA  = 5'd3,
                     ST_IDLE        = 5'd4,
                     ST_PAGE_CMD0   = 5'd5,
                     ST_PAGE_CMD1   = 5'd6,
                     ST_PAGE_CMD2   = 5'd7,
                     ST_PAGE_CMD3   = 5'd8,
                     ST_PAGE_CMD4   = 5'd9,
                     ST_PAGE_CMD5   = 5'd10,
                     ST_DATA_REQ    = 5'd11,
                     ST_DATA_WAIT   = 5'd12,
                     ST_DATA_SAMPLE = 5'd13,
                     ST_DATA_NEXT   = 5'd14,
                     ST_TX_SETUP    = 5'd15,
                     ST_TX_HIGH     = 5'd16,
                     ST_TX_LOW      = 5'd17;

    localparam [4:0] INIT_LAST = 5'd24;

    reg [4:0]  state, next_state;
    reg [4:0]  init_idx;
    reg [10:0] clear_cnt;
    reg [6:0]  data_cnt;
    reg [11:0] rom_addr;
    reg [7:0]  tx_byte;
    reg        tx_dc;
    reg [2:0]  tx_bit;
    reg [7:0]  div_cnt;
    reg        invert_mode, all_on_mode;
    reg [23:0] wait_cnt;

    wire [7:0] current_pixel_byte;
    wire [7:0] frame_sel_raw = cmd_data[15:8];
    wire [7:0] frame_sel = (frame_sel_raw < ROM_NUM_FRAMES) ? frame_sel_raw : 8'd0;
    wire [11:0] start_addr = frame_sel * FRAME_STRIDE;

    Picture_ROM rom_inst (
        .clk (clk),
        .addr(rom_addr),
        .dout(current_pixel_byte)
    );

    function [7:0] init_cmd(input [4:0] idx);
        case (idx)
            5'd0:  init_cmd = 8'hAE;
            5'd1:  init_cmd = 8'hD5; 5'd2:  init_cmd = 8'h80;
            5'd3:  init_cmd = 8'hA8; 5'd4:  init_cmd = 8'h3F;
            5'd5:  init_cmd = 8'hD3; 5'd6:  init_cmd = 8'h00;
            5'd7:  init_cmd = 8'h40;
            5'd8:  init_cmd = 8'h8D; 5'd9:  init_cmd = 8'h14;
            5'd10: init_cmd = 8'h20; 5'd11: init_cmd = 8'h00;
            5'd12: init_cmd = 8'hA1; 5'd13: init_cmd = 8'hC8;
            5'd14: init_cmd = 8'hDA; 5'd15: init_cmd = 8'h12;
            5'd16: init_cmd = 8'h81; 5'd17: init_cmd = 8'h7F;
            5'd18: init_cmd = 8'hD9; 5'd19: init_cmd = 8'hF1;
            5'd20: init_cmd = 8'hDB; 5'd21: init_cmd = 8'h40;
            5'd22: init_cmd = 8'hA4;
            5'd23: init_cmd = 8'hA6;
            5'd24: init_cmd = 8'hAF;
            default: init_cmd = 8'hAE;
        endcase
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state       <= ST_BOOT;
            next_state  <= ST_BOOT;
            busy        <= 1'b1;
            sclk        <= 1'b0;
            mosi        <= 1'b0;
            dc          <= 1'b0;
            cs          <= 1'b1;
            init_idx    <= 5'd0;
            clear_cnt   <= 11'd0;
            data_cnt    <= 7'd0;
            rom_addr    <= 12'd0;
            tx_byte     <= 8'h00;
            tx_dc       <= 1'b0;
            tx_bit      <= 3'd0;
            div_cnt     <= 8'd0;
            invert_mode <= 1'b0;
            all_on_mode <= 1'b0;
            wait_cnt    <= 24'd0;
        end else begin
            case (state)
                ST_BOOT: begin
                    busy <= 1'b1;
                    if (wait_cnt < 24'd1000000) begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end else begin
                        init_idx    <= 5'd0;
                        tx_byte     <= init_cmd(5'd0);
                        tx_dc       <= 1'b0;
                        next_state  <= ST_INIT_NEXT;
                        state       <= ST_TX_SETUP;
                    end
                end

                ST_INIT_NEXT: begin
                    if (init_idx == INIT_LAST) begin
                        clear_cnt <= 11'd0;
                        state <= ST_CLEAR_PREP;
                    end else begin
                        init_idx   <= init_idx + 1'b1;
                        tx_byte    <= init_cmd(init_idx + 1'b1);
                        tx_dc      <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state      <= ST_TX_SETUP;
                    end
                end

                ST_CLEAR_PREP: begin
                    tx_dc <= 1'b0;
                    case (clear_cnt[2:0])
                        3'd0: tx_byte <= 8'h21;
                        3'd1: tx_byte <= 8'h00;
                        3'd2: tx_byte <= 8'h7F;
                        3'd3: tx_byte <= 8'h22;
                        3'd4: tx_byte <= 8'h00;
                        3'd5: tx_byte <= 8'h07;
                        default: tx_byte <= 8'h00;
                    endcase

                    if (clear_cnt[2:0] == 3'd5) begin
                        clear_cnt  <= 11'd0;
                        next_state <= ST_CLEAR_DATA;
                    end else begin
                        clear_cnt  <= clear_cnt + 1'b1;
                        next_state <= ST_CLEAR_PREP;
                    end
                    state <= ST_TX_SETUP;
                end

                ST_CLEAR_DATA: begin
                    tx_byte <= 8'h00;
                    tx_dc   <= 1'b1;
                    if (clear_cnt == 11'd1023) begin
                        state <= ST_IDLE;
                    end else begin
                        clear_cnt  <= clear_cnt + 1'b1;
                        next_state <= ST_CLEAR_DATA;
                        state      <= ST_TX_SETUP;
                    end
                end

                ST_IDLE: begin
                    busy <= 1'b0;
                    cs   <= 1'b1;

                    if (invert_toggle) begin
                        tx_byte     <= invert_mode ? 8'hA6 : 8'hA7;
                        tx_dc       <= 1'b0;
                        invert_mode <= ~invert_mode;
                        busy        <= 1'b1;
                        next_state  <= ST_IDLE;
                        state       <= ST_TX_SETUP;
                    end else if (all_on_toggle) begin
                        tx_byte     <= all_on_mode ? 8'hA4 : 8'hA5;
                        tx_dc       <= 1'b0;
                        all_on_mode <= ~all_on_mode;
                        busy        <= 1'b1;
                        next_state  <= ST_IDLE;
                        state       <= ST_TX_SETUP;
                    end else if (we || redraw_pulse) begin
                        data_cnt <= 7'd0;
                        busy <= 1'b1;
                        state <= ST_PAGE_CMD0;
                    end
                end

                ST_PAGE_CMD0: begin
                    tx_byte <= 8'h21; tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD1; state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD1: begin
                    tx_byte <= X_OFFSET; tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD2; state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD2: begin
                    tx_byte <= X_OFFSET + IMG_W_BYTES - 1'b1; tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD3; state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD3: begin
                    tx_byte <= 8'h22; tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD4; state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD4: begin
                    tx_byte <= 8'h00; tx_dc <= 1'b0;
                    next_state <= ST_PAGE_CMD5; state <= ST_TX_SETUP;
                end
                ST_PAGE_CMD5: begin
                    tx_byte <= IMG_PAGES - 1'b1; tx_dc <= 1'b0;
                    next_state <= ST_DATA_REQ; state <= ST_TX_SETUP;
                end

                ST_DATA_REQ: begin
                    rom_addr <= start_addr + data_cnt;
                    state <= ST_DATA_WAIT;
                end
                ST_DATA_WAIT: begin
                    state <= ST_DATA_SAMPLE;
                end
                ST_DATA_SAMPLE: begin
                    tx_byte    <= current_pixel_byte;
                    tx_dc      <= 1'b1;
                    next_state <= ST_DATA_NEXT;
                    state      <= ST_TX_SETUP;
                end
                ST_DATA_NEXT: begin
                    if (data_cnt == (IMG_W_BYTES * IMG_PAGES - 1'b1)) begin
                        state <= ST_IDLE;
                    end else begin
                        data_cnt <= data_cnt + 1'b1;
                        state <= ST_DATA_REQ;
                    end
                end

                ST_TX_SETUP: begin
                    cs      <= 1'b0;
                    dc      <= tx_dc;
                    mosi    <= tx_byte[7];
                    tx_bit  <= 3'd7;
                    div_cnt <= 8'd0;
                    state   <= ST_TX_HIGH;
                end
                ST_TX_HIGH: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk    <= 1'b1;
                        div_cnt <= 8'd0;
                        state   <= ST_TX_LOW;
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end
                ST_TX_LOW: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk    <= 1'b0;
                        div_cnt <= 8'd0;
                        if (tx_bit == 3'd0) begin
                            state <= next_state;
                        end else begin
                            tx_bit <= tx_bit - 1'b1;
                            mosi   <= tx_byte[tx_bit - 1'b1];
                            state  <= ST_TX_HIGH;
                        end
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
