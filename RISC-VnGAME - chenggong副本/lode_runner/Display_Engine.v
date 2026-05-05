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
    output wire        sclk,
    output wire        mosi,
    output wire        dc,
    output wire        cs
);

    localparam integer CLK_HZ    = 100_000_000;
    localparam integer BAUD_RATE = 1_000_000;
    localparam integer BAUD_DIV  = CLK_HZ / BAUD_RATE;

    localparam [7:0] HDR0 = 8'h55;
    localparam [7:0] HDR1 = 8'hAA;
    localparam [7:0] HDR2 = 8'h80;
    localparam [7:0] HDR3 = 8'h40;

    localparam [1:0] ST_IDLE      = 2'd0,
                     ST_LOAD_BYTE = 2'd1,
                     ST_TX_SHIFT  = 2'd2,
                     ST_TX_NEXT   = 2'd3;

    reg [1:0]  state;
    reg [7:0]  framebuf [0:1023];
    reg [15:0] baud_cnt;
    reg [3:0]  tx_bit_idx;
    reg [10:0] stream_idx;
    reg [9:0]  tx_shift;
    reg        redraw_req;
    reg        invert_mode;
    reg        all_on_mode;

    integer i;

    function [7:0] stream_byte;
        input [10:0] index;
        reg [7:0] pixel_byte;
        begin
            case (index)
                11'd0: stream_byte = HDR0;
                11'd1: stream_byte = HDR1;
                11'd2: stream_byte = HDR2;
                11'd3: stream_byte = HDR3;
                default: begin
                    pixel_byte = framebuf[index - 11'd4];
                    if (all_on_mode) begin
                        stream_byte = 8'hFF;
                    end else if (invert_mode) begin
                        stream_byte = ~pixel_byte;
                    end else begin
                        stream_byte = pixel_byte;
                    end
                end
            endcase
        end
    endfunction

    assign sclk = 1'b0;
    assign dc   = 1'b0;
    assign cs   = 1'b1;
    assign mosi = tx_shift[0];

    always @(posedge clk) begin
        if (reset) begin
            state       <= ST_IDLE;
            baud_cnt    <= 16'd0;
            tx_bit_idx  <= 4'd0;
            stream_idx  <= 11'd0;
            tx_shift    <= 10'h3FF;
            busy        <= 1'b0;
            redraw_req  <= 1'b1;
            invert_mode <= 1'b0;
            all_on_mode <= 1'b0;
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
            if (invert_toggle) begin
                invert_mode <= ~invert_mode;
                redraw_req  <= 1'b1;
            end
            if (all_on_toggle) begin
                all_on_mode <= ~all_on_mode;
                redraw_req  <= 1'b1;
            end

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (redraw_req) begin
                        redraw_req <= 1'b0;
                        busy       <= 1'b1;
                        stream_idx <= 11'd0;
                        state      <= ST_LOAD_BYTE;
                    end
                end

                ST_LOAD_BYTE: begin
                    tx_shift   <= {1'b1, stream_byte(stream_idx), 1'b0};
                    tx_bit_idx <= 4'd0;
                    baud_cnt   <= 16'd0;
                    state      <= ST_TX_SHIFT;
                end

                ST_TX_SHIFT: begin
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 16'd0;
                        tx_shift <= {1'b1, tx_shift[9:1]};
                        if (tx_bit_idx == 4'd9) begin
                            state <= ST_TX_NEXT;
                        end else begin
                            tx_bit_idx <= tx_bit_idx + 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                ST_TX_NEXT: begin
                    if (stream_idx == 11'd1027) begin
                        state <= ST_IDLE;
                    end else begin
                        stream_idx <= stream_idx + 1'b1;
                        state      <= ST_LOAD_BYTE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
