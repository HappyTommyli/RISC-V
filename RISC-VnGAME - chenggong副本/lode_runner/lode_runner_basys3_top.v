module lode_runner_basys3_top (
    input  wire clk100,
    input  wire btnC,
    input  wire btnU,
    input  wire btnD,
    input  wire btnL,
    input  wire btnR,
    input  wire uart_rx,
    output wire [15:0] led,
    output wire uart_tx
);

    wire rst = btnC;

    // buttons[0]=UP, [1]=DOWN, [2]=LEFT, [3]=RIGHT
    wire [3:0] buttons = {btnR, btnL, btnD, btnU};

    reg [31:0] timer_value;
    always @(posedge clk100) begin
        if (rst) begin
            timer_value <= 32'b0;
        end else begin
            timer_value <= timer_value + 32'd1;
        end
    end

    wire        display_we;
    wire [31:0] display_cmd;
    wire        oled_fb_we;
    wire [9:0]  oled_fb_addr;
    wire [7:0]  oled_fb_data;
    wire [15:0] dbg_leds;
    wire        display_busy;

    pipeline u_pipeline (
        .clk         (clk100),
        .rst         (rst),
        .buttons     (buttons),
        .timer_value (timer_value),
        .display_busy(display_busy),
        .display_we  (display_we),
        .display_cmd (display_cmd),
        .oled_fb_we  (oled_fb_we),
        .oled_fb_addr(oled_fb_addr),
        .oled_fb_data(oled_fb_data),
        .dbg_leds    (dbg_leds)
    );

    // LED count is controlled by CPU debug register (coin lamps etc.)
    assign led = dbg_leds;

    Display_Engine u_display (
        .clk          (clk100),
        .reset        (rst),
        .cmd_data     (display_cmd),
        .we           (display_we),
        .invert_toggle(1'b0),
        .all_on_toggle(1'b0),
        .redraw_pulse (1'b0),
        .oled_fb_we   (oled_fb_we),
        .oled_fb_addr (oled_fb_addr),
        .oled_fb_data (oled_fb_data),
        .busy         (display_busy),
        .sclk         (),
        .mosi         (uart_tx),
        .dc           (),
        .cs           ()
    );

endmodule
