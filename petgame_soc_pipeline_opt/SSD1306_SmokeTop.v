module SSD1306_SmokeTop (
    input  wire       clk,
    input  wire       reset,
    input  wire [2:0] buttons,     // kept for XDC compatibility
    output wire [3:0] leds,
    output reg        screen_sclk,
    output reg        screen_mosi,
    output reg        screen_dc,
    output reg        screen_cs
);
    wire _unused_buttons = ^buttons;

    // 100MHz / (2*SCLK_DIV) ~= SPI SCLK
    localparam integer SCLK_DIV        = 50;            // ~1 MHz
    localparam [31:0]  TOGGLE_INTERVAL = 32'd50_000_000; // 0.5 s
    localparam [4:0]   INIT_LAST       = 5'd24;

    localparam [3:0] ST_INIT_LOAD = 4'd0;
    localparam [3:0] ST_INIT_NEXT = 4'd1;
    localparam [3:0] ST_WAIT      = 4'd2;
    localparam [3:0] ST_CMD_LOAD  = 4'd3;
    localparam [3:0] ST_CMD_NEXT  = 4'd4;
    localparam [3:0] ST_TX_SETUP  = 4'd5;
    localparam [3:0] ST_TX_HIGH   = 4'd6;
    localparam [3:0] ST_TX_LOW    = 4'd7;

    reg [3:0] state;
    reg [3:0] next_state;
    reg [4:0] init_idx;
    reg [7:0] tx_byte;
    reg [2:0] tx_bit;
    reg [7:0] div_cnt;
    reg [31:0] wait_cnt;

    // Command queue for the white/black toggle sequence.
    reg [7:0] cmd_a;
    reg [7:0] cmd_b;
    reg [1:0] cmd_left;

    reg white_mode;

    function [7:0] init_cmd;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  init_cmd = 8'hAE;
                5'd1:  init_cmd = 8'hD5;
                5'd2:  init_cmd = 8'h80;
                5'd3:  init_cmd = 8'hA8;
                5'd4:  init_cmd = 8'h3F;
                5'd5:  init_cmd = 8'hD3;
                5'd6:  init_cmd = 8'h00;
                5'd7:  init_cmd = 8'h40;
                5'd8:  init_cmd = 8'h8D;
                5'd9:  init_cmd = 8'h14;
                5'd10: init_cmd = 8'h20;
                5'd11: init_cmd = 8'h00;
                5'd12: init_cmd = 8'hA1;
                5'd13: init_cmd = 8'hC8;
                5'd14: init_cmd = 8'hDA;
                5'd15: init_cmd = 8'h12;
                5'd16: init_cmd = 8'h81;
                5'd17: init_cmd = 8'hCF;
                5'd18: init_cmd = 8'hD9;
                5'd19: init_cmd = 8'hF1;
                5'd20: init_cmd = 8'hDB;
                5'd21: init_cmd = 8'h40;
                5'd22: init_cmd = 8'hA4;
                5'd23: init_cmd = 8'hA6;
                5'd24: init_cmd = 8'hAF;
                default: init_cmd = 8'hAE;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state       <= ST_INIT_LOAD;
            next_state  <= ST_INIT_LOAD;
            init_idx    <= 5'd0;
            tx_byte     <= 8'h00;
            tx_bit      <= 3'd0;
            div_cnt     <= 8'd0;
            wait_cnt    <= 32'd0;
            cmd_a       <= 8'h00;
            cmd_b       <= 8'h00;
            cmd_left    <= 2'd0;
            white_mode  <= 1'b0;
            screen_sclk <= 1'b0;
            screen_mosi <= 1'b0;
            screen_dc   <= 1'b0;
            screen_cs   <= 1'b1;
        end else begin
            case (state)
                ST_INIT_LOAD: begin
                    tx_byte     <= init_cmd(init_idx);
                    screen_dc   <= 1'b0;
                    next_state  <= ST_INIT_NEXT;
                    state       <= ST_TX_SETUP;
                end

                ST_INIT_NEXT: begin
                    if (init_idx == INIT_LAST) begin
                        // Force a known starting point: black screen first.
                        cmd_a      <= 8'hAE;
                        cmd_b      <= 8'h00;
                        cmd_left   <= 2'd1;
                        white_mode <= 1'b0;
                        state      <= ST_CMD_LOAD;
                    end else begin
                        init_idx <= init_idx + 1'b1;
                        state    <= ST_INIT_LOAD;
                    end
                end

                ST_WAIT: begin
                    if (wait_cnt == TOGGLE_INTERVAL - 1) begin
                        wait_cnt <= 32'd0;
                        if (white_mode) begin
                            // Pure black: display off.
                            cmd_a      <= 8'hAE;
                            cmd_b      <= 8'h00;
                            cmd_left   <= 2'd1;
                            white_mode <= 1'b0;
                        end else begin
                            // Pure white: display on + entire display ON.
                            cmd_a      <= 8'hAF;
                            cmd_b      <= 8'hA5;
                            cmd_left   <= 2'd2;
                            white_mode <= 1'b1;
                        end
                        state <= ST_CMD_LOAD;
                    end else begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end
                end

                ST_CMD_LOAD: begin
                    tx_byte <= cmd_a;
                    if (cmd_left == 2'd2) begin
                        cmd_a    <= cmd_b;
                        cmd_left <= 2'd1;
                    end else begin
                        cmd_left <= 2'd0;
                    end
                    screen_dc  <= 1'b0;
                    next_state <= ST_CMD_NEXT;
                    state      <= ST_TX_SETUP;
                end

                ST_CMD_NEXT: begin
                    if (cmd_left == 2'd0) begin
                        state <= ST_WAIT;
                    end else begin
                        state <= ST_CMD_LOAD;
                    end
                end

                ST_TX_SETUP: begin
                    screen_cs   <= 1'b0;
                    screen_sclk <= 1'b0;
                    tx_bit      <= 3'd7;
                    screen_mosi <= tx_byte[7];
                    div_cnt     <= 8'd0;
                    state       <= ST_TX_HIGH;
                end

                ST_TX_HIGH: begin
                    if (div_cnt == (SCLK_DIV - 1)) begin
                        div_cnt     <= 8'd0;
                        screen_sclk <= 1'b1;
                        state       <= ST_TX_LOW;
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                ST_TX_LOW: begin
                    if (div_cnt == (SCLK_DIV - 1)) begin
                        div_cnt     <= 8'd0;
                        screen_sclk <= 1'b0;
                        if (tx_bit == 3'd0) begin
                            screen_cs <= 1'b1;
                            state     <= next_state;
                        end else begin
                            tx_bit      <= tx_bit - 1'b1;
                            screen_mosi <= tx_byte[tx_bit - 1'b1];
                            state       <= ST_TX_HIGH;
                        end
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                default: state <= ST_INIT_LOAD;
            endcase
        end
    end

    // LEDs: [3]=init-busy, [2]=white_mode, [1]=cs, [0]=sclk
    assign leds = {(state != ST_WAIT), white_mode, screen_cs, screen_sclk};

endmodule
