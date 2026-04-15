module LodeRunner_SSD1306_Top (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] buttons, // [0]=UP [1]=DOWN [2]=LEFT [3]=RIGHT
    output wire [3:0] leds,
    output wire       screen_sclk,
    output wire       screen_mosi,
    output wire       screen_dc,
    output wire       screen_cs
);
    wire [6:0] fb_addr;
    wire [7:0] fb_data;
    wire [3:0] score;
    wire game_clear;
    wire busy;

    LodeRunner32_Core u_core (
        .clk(clk),
        .reset(reset),
        .btn_up(buttons[0]),
        .btn_down(buttons[1]),
        .btn_left(buttons[2]),
        .btn_right(buttons[3]),
        .rd_addr(fb_addr),
        .rd_data(fb_data),
        .score(score),
        .game_clear(game_clear)
    );

    Display_Engine_Frame32 u_disp (
        .clk(clk),
        .reset(reset),
        .fb_addr(fb_addr),
        .fb_data(fb_data),
        .busy(busy),
        .sclk(screen_sclk),
        .mosi(screen_mosi),
        .dc(screen_dc),
        .cs(screen_cs)
    );

    // LEDs: [3]=clear, [2]=busy, [1:0]=score low bits
    assign leds = {game_clear, busy, score[1:0]};

endmodule
