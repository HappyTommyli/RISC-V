module Display_Engine (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cmd_data,
    input  wire        we,
    input  wire        invert_toggle,
    input  wire        all_on_toggle,
    input  wire        redraw_pulse,
    input  wire        oled_fb_we,
    input  wire [9:0]  oled_fb_addr,
    input  wire [7:0]  oled_fb_data,
    output reg         busy,
    output reg         sclk,
    output reg         mosi,
    output reg         dc,
    output reg         cs
);

    localparam integer SCLK_DIV = 25;

    localparam [4:0] ST_BOOT      = 5'd0,
                     ST_INIT_NEXT = 5'd1,
                     ST_IDLE      = 5'd2,
                     ST_CMD_0     = 5'd3,
                     ST_CMD_1     = 5'd4,
                     ST_CMD_2     = 5'd5,
                     ST_CMD_3     = 5'd6,
                     ST_CMD_4     = 5'd7,
                     ST_CMD_5     = 5'd8,
                     ST_DATA_REQ  = 5'd9,
                     ST_DATA_WAIT = 5'd10,
                     ST_DATA_NEXT = 5'd11,
                     ST_TX_SETUP  = 5'd12,
                     ST_TX_HIGH   = 5'd13,
                     ST_TX_LOW    = 5'd14;

    localparam [4:0] INIT_LAST = 5'd24;

    reg [4:0]  state;
    reg [4:0]  next_state;
    reg [4:0]  init_idx;
    reg [9:0]  data_cnt;
    reg [7:0]  tx_byte;
    reg        tx_dc;
    reg [2:0]  tx_bit;
    reg [7:0]  div_cnt;
    reg [23:0] wait_cnt;
    reg        invert_mode;
    reg        all_on_mode;
    reg        redraw_req;

    reg [7:0] framebuf [0:1023];
    reg [7:0] fb_byte_q;

    integer i;

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
            data_cnt    <= 10'd0;
            tx_byte     <= 8'h00;
            tx_dc       <= 1'b0;
            tx_bit      <= 3'd0;
            div_cnt     <= 8'd0;
            wait_cnt    <= 24'd0;
            invert_mode <= 1'b0;
            all_on_mode <= 1'b0;
            redraw_req  <= 1'b0;
            fb_byte_q   <= 8'h00;
            for (i = 0; i < 1024; i = i + 1) begin
                framebuf[i] <= 8'h00;
            end
        end else begin
            if (oled_fb_we) begin
                framebuf[oled_fb_addr] <= oled_fb_data;
            end

            if (we || redraw_pulse || cmd_data[0]) begin
                redraw_req <= 1'b1;
            end

            case (state)
                ST_BOOT: begin
                    busy <= 1'b1;
                    if (wait_cnt < 24'd1000000) begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end else begin
                        init_idx   <= 5'd0;
                        tx_byte    <= init_cmd(5'd0);
                        tx_dc      <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state      <= ST_TX_SETUP;
                    end
                end

                ST_INIT_NEXT: begin
                    if (init_idx == INIT_LAST) begin
                        busy       <= 1'b0;
                        redraw_req <= 1'b1;
                        state      <= ST_IDLE;
                    end else begin
                        init_idx   <= init_idx + 1'b1;
                        tx_byte    <= init_cmd(init_idx + 1'b1);
                        tx_dc      <= 1'b0;
                        next_state <= ST_INIT_NEXT;
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
                    end else if (redraw_req) begin
                        redraw_req <= 1'b0;
                        data_cnt   <= 10'd0;
                        busy       <= 1'b1;
                        state      <= ST_CMD_0;
                    end
                end

                ST_CMD_0: begin tx_byte <= 8'h21; tx_dc <= 1'b0; next_state <= ST_CMD_1; state <= ST_TX_SETUP; end
                ST_CMD_1: begin tx_byte <= 8'h00; tx_dc <= 1'b0; next_state <= ST_CMD_2; state <= ST_TX_SETUP; end
                ST_CMD_2: begin tx_byte <= 8'h7F; tx_dc <= 1'b0; next_state <= ST_CMD_3; state <= ST_TX_SETUP; end
                ST_CMD_3: begin tx_byte <= 8'h22; tx_dc <= 1'b0; next_state <= ST_CMD_4; state <= ST_TX_SETUP; end
                ST_CMD_4: begin tx_byte <= 8'h00; tx_dc <= 1'b0; next_state <= ST_CMD_5; state <= ST_TX_SETUP; end
                ST_CMD_5: begin tx_byte <= 8'h07; tx_dc <= 1'b0; next_state <= ST_DATA_REQ; state <= ST_TX_SETUP; end

                ST_DATA_REQ: begin
                    fb_byte_q <= framebuf[data_cnt];
                    state <= ST_DATA_WAIT;
                end

                ST_DATA_WAIT: begin
                    tx_byte    <= fb_byte_q;
                    tx_dc      <= 1'b1;
                    next_state <= ST_DATA_NEXT;
                    state      <= ST_TX_SETUP;
                end

                ST_DATA_NEXT: begin
                    if (data_cnt == 10'd1023) begin
                        state <= ST_IDLE;
                    end else begin
                        data_cnt <= data_cnt + 1'b1;
                        state    <= ST_DATA_REQ;
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

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
