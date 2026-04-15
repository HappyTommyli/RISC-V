module load_runner_top (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] buttons,
    output wire [3:0] leds,
    output wire       screen_sclk,
    output wire       screen_mosi,
    output wire       screen_dc,
    output wire       screen_cs
);
    reg [31:0] timer_value;
    always @(posedge clk) begin
        if (reset) timer_value <= 32'b0;
        else       timer_value <= timer_value + 1'b1;
    end

    wire display_we;
    wire [31:0] display_cmd;
    wire display_busy;
    wire oled_fb_we;
    wire [9:0] oled_fb_addr;
    wire [7:0] oled_fb_data;

    // Game core runs on pipeline CPU
    pipeline cpu_core (
        .clk(clk),
        .rst(reset),
        .buttons(buttons),
        .timer_value(timer_value),
        .display_busy(display_busy),
        .display_we(display_we),
        .display_cmd(display_cmd),
        .oled_fb_we(oled_fb_we),
        .oled_fb_addr(oled_fb_addr),
        .oled_fb_data(oled_fb_data)
    );

    Display_Engine_FB128 oled_engine (
        .clk(clk),
        .reset(reset),
        .fb_we(oled_fb_we),
        .fb_waddr(oled_fb_addr),
        .fb_wdata(oled_fb_data),
        .busy(display_busy),
        .sclk(screen_sclk),
        .mosi(screen_mosi),
        .dc(screen_dc),
        .cs(screen_cs)
    );

    assign leds = {display_busy, buttons[2:0]};
endmodule
