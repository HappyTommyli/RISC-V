`timescale 1ns / 1ps

module top_lode_runner_basys3 (
    input  wire       CLK100MHZ,
    input  wire       BTN_C,
    input  wire       BTN_U,
    input  wire       BTN_D,
    input  wire       BTN_L,
    input  wire       BTN_R,
    output wire       OLED_SCLK,
    output wire       OLED_MOSI,
    output wire       OLED_DC,
    output wire       OLED_RES,
    output wire       OLED_CS,
    output wire       OLED_VBAT,
    output wire       OLED_VDD,
    output wire [15:0] LED
);
    wire rst = BTN_C;

    reg [31:0] timer_value;
    always @(posedge CLK100MHZ) begin
        if (rst) begin
            timer_value <= 32'd0;
        end else begin
            timer_value <= timer_value + 32'd1;
        end
    end

    reg [20:0] tick_div;
    reg tick_60hz;
    always @(posedge CLK100MHZ) begin
        if (rst) begin
            tick_div <= 21'd0;
            tick_60hz <= 1'b0;
        end else if (tick_div == 21'd1666665) begin
            tick_div <= 21'd0;
            tick_60hz <= 1'b1;
        end else begin
            tick_div <= tick_div + 21'd1;
            tick_60hz <= 1'b0;
        end
    end

    reg [15:0] btn_u_sync;
    reg [15:0] btn_d_sync;
    reg [15:0] btn_l_sync;
    reg [15:0] btn_r_sync;

    always @(posedge CLK100MHZ) begin
        if (rst) begin
            btn_u_sync <= 16'd0;
            btn_d_sync <= 16'd0;
            btn_l_sync <= 16'd0;
            btn_r_sync <= 16'd0;
        end else begin
            btn_u_sync <= {btn_u_sync[14:0], BTN_U};
            btn_d_sync <= {btn_d_sync[14:0], BTN_D};
            btn_l_sync <= {btn_l_sync[14:0], BTN_L};
            btn_r_sync <= {btn_r_sync[14:0], BTN_R};
        end
    end

    wire btn_u = &btn_u_sync;
    wire btn_d = &btn_d_sync;
    wire btn_l = &btn_l_sync;
    wire btn_r = &btn_r_sync;

    wire [9:0] fb_addr;
    wire [7:0] fb_data;
    wire [7:0] score;
    wire game_over;
    wire game_win;

    lode_runner_game u_game (
        .clk      (CLK100MHZ),
        .rst      (rst),
        .tick_60hz(tick_60hz),
        .btn_up   (btn_u),
        .btn_down (btn_d),
        .btn_left (btn_l),
        .btn_right(btn_r),
        .rd_addr  (fb_addr),
        .rd_data  (fb_data),
        .score    (score),
        .game_over(game_over),
        .game_win (game_win)
    );

    ssd1306_controller u_oled (
        .clk      (CLK100MHZ),
        .rst      (rst),
        .fb_addr  (fb_addr),
        .fb_data  (fb_data),
        .oled_sclk(OLED_SCLK),
        .oled_mosi(OLED_MOSI),
        .oled_dc  (OLED_DC),
        .oled_res (OLED_RES),
        .oled_cs  (OLED_CS),
        .oled_vbat(OLED_VBAT),
        .oled_vdd (OLED_VDD)
    );

    wire cpu_display_we;
    wire [31:0] cpu_display_cmd;
    wire cpu_oled_fb_we;
    wire [6:0] cpu_oled_fb_addr;
    wire [7:0] cpu_oled_fb_data;

    pipeline u_pipeline (
        .clk        (CLK100MHZ),
        .rst        (rst),
        .buttons    ({btn_u, btn_d, btn_l, btn_r}),
        .timer_value(timer_value),
        .display_busy(1'b0),
        .display_we (cpu_display_we),
        .display_cmd(cpu_display_cmd),
        .oled_fb_we (cpu_oled_fb_we),
        .oled_fb_addr(cpu_oled_fb_addr),
        .oled_fb_data(cpu_oled_fb_data)
    );

    reg [15:0] cpu_activity;
    always @(posedge CLK100MHZ) begin
        if (rst) begin
            cpu_activity <= 16'd0;
        end else if (cpu_display_we || cpu_oled_fb_we) begin
            cpu_activity <= cpu_activity + 16'd1;
        end
    end

    assign LED[7:0] = score;
    assign LED[8] = game_over;
    assign LED[9] = game_win;
    assign LED[10] = btn_u;
    assign LED[11] = btn_d;
    assign LED[12] = btn_l;
    assign LED[13] = btn_r;
    assign LED[15:14] = cpu_activity[1:0];
endmodule
