module Display_Engine_Frame32 (
    input  wire       clk,
    input  wire       reset,
    output reg  [6:0] fb_addr,
    input  wire [7:0] fb_data,
    output reg        busy,
    output reg        sclk,
    output reg        mosi,
    output reg        dc,
    output reg        cs
);
    localparam integer SCLK_DIV = 25;
    localparam [4:0] INIT_LAST = 5'd24;

    localparam [4:0] ST_BOOT      = 5'd0,
                     ST_INIT_NEXT = 5'd1,
                     ST_FRAME_CMD = 5'd2,
                     ST_FRAME_DATA= 5'd3,
                     ST_FRAME_NEXT= 5'd4,
                     ST_TX_SETUP  = 5'd5,
                     ST_TX_HIGH   = 5'd6,
                     ST_TX_LOW    = 5'd7,
                     ST_FRAME_WAIT= 5'd8;

    reg [4:0] state, next_state;
    reg [4:0] init_idx;
    reg [2:0] cmd_idx;
    reg [6:0] data_cnt;
    reg [7:0] tx_byte;
    reg       tx_dc;
    reg [2:0] tx_bit;
    reg [7:0] div_cnt;
    reg [23:0] wait_cnt;

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
            state <= ST_BOOT;
            next_state <= ST_BOOT;
            init_idx <= 5'd0;
            cmd_idx <= 3'd0;
            data_cnt <= 7'd0;
            tx_byte <= 8'h00;
            tx_dc <= 1'b0;
            tx_bit <= 3'd0;
            div_cnt <= 8'd0;
            wait_cnt <= 24'd0;
            fb_addr <= 7'd0;
            busy <= 1'b1;
            sclk <= 1'b0;
            mosi <= 1'b0;
            dc <= 1'b0;
            cs <= 1'b1;
        end else begin
            case (state)
                ST_BOOT: begin
                    busy <= 1'b1;
                    if (wait_cnt < 24'd1000000) begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end else begin
                        init_idx <= 5'd0;
                        tx_byte <= init_cmd(5'd0);
                        tx_dc <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state <= ST_TX_SETUP;
                    end
                end

                ST_INIT_NEXT: begin
                    if (init_idx == INIT_LAST) begin
                        cmd_idx <= 3'd0;
                        state <= ST_FRAME_CMD;
                    end else begin
                        init_idx <= init_idx + 1'b1;
                        tx_byte <= init_cmd(init_idx + 1'b1);
                        tx_dc <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state <= ST_TX_SETUP;
                    end
                end

                ST_FRAME_CMD: begin
                    tx_dc <= 1'b0;
                    case (cmd_idx)
                        3'd0: tx_byte <= 8'h21;
                        3'd1: tx_byte <= 8'h00;
                        3'd2: tx_byte <= 8'h1F; // 32 cols
                        3'd3: tx_byte <= 8'h22;
                        3'd4: tx_byte <= 8'h00;
                        3'd5: tx_byte <= 8'h03; // 4 pages
                        default: tx_byte <= 8'h00;
                    endcase

                    if (cmd_idx == 3'd5) begin
                        data_cnt <= 7'd0;
                        fb_addr <= 7'd0;
                        next_state <= ST_FRAME_DATA;
                    end else begin
                        cmd_idx <= cmd_idx + 1'b1;
                        next_state <= ST_FRAME_CMD;
                    end
                    state <= ST_TX_SETUP;
                end

                ST_FRAME_DATA: begin
                    tx_byte <= fb_data;
                    tx_dc <= 1'b1;
                    next_state <= ST_FRAME_NEXT;
                    state <= ST_TX_SETUP;
                end

                ST_FRAME_NEXT: begin
                    if (data_cnt == 7'd127) begin
                        wait_cnt <= 24'd0;
                        state <= ST_FRAME_WAIT;
                    end else begin
                        data_cnt <= data_cnt + 1'b1;
                        fb_addr <= data_cnt + 1'b1;
                        state <= ST_FRAME_DATA;
                    end
                end

                ST_FRAME_WAIT: begin
                    busy <= 1'b0;
                    cs <= 1'b1;
                    if (wait_cnt < 24'd200000) begin // ~4ms @100MHz
                        wait_cnt <= wait_cnt + 1'b1;
                    end else begin
                        busy <= 1'b1;
                        cmd_idx <= 3'd0;
                        state <= ST_FRAME_CMD;
                    end
                end

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
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end
                ST_TX_LOW: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk <= 1'b0;
                        div_cnt <= 8'd0;
                        if (tx_bit == 3'd0) begin
                            state <= next_state;
                        end else begin
                            tx_bit <= tx_bit - 1'b1;
                            mosi <= tx_byte[tx_bit - 1'b1];
                            state <= ST_TX_HIGH;
                        end
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                default: state <= ST_BOOT;
            endcase
        end
    end
endmodule
