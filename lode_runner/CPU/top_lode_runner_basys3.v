`timescale 1ns / 1ps

module top_lode_runner_basys3 (
    input  wire        CLK100MHZ,
    input  wire        BTN_C,
    input  wire        BTN_U,
    input  wire        BTN_D,
    input  wire        BTN_L,
    input  wire        BTN_R,
    output wire        OLED_SCLK,
    output wire        OLED_MOSI,
    output wire        OLED_DC,
    output wire        OLED_RES,
    output wire        OLED_CS,
    output wire        OLED_VBAT,
    output wire        OLED_VDD,
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

    wire cpu_display_we;
    wire [31:0] cpu_display_cmd;
    wire cpu_oled_fb_we;
    wire [9:0] cpu_oled_fb_addr;
    wire [7:0] cpu_oled_fb_data;

    pipeline u_pipeline (
        .clk         (CLK100MHZ),
        .rst         (rst),
        .buttons     ({btn_u, btn_d, btn_l, btn_r}),
        .timer_value (timer_value),
        .display_busy(1'b0),
        .display_we  (cpu_display_we),
        .display_cmd (cpu_display_cmd),
        .oled_fb_we  (cpu_oled_fb_we),
        .oled_fb_addr(cpu_oled_fb_addr),
        .oled_fb_data(cpu_oled_fb_data)
    );

    reg [7:0] fb_mem [0:1023];
    integer i;
    always @(posedge CLK100MHZ) begin
        if (rst) begin
            for (i = 0; i < 1024; i = i + 1) begin
                fb_mem[i] <= 8'h00;
            end
        end else if (cpu_oled_fb_we) begin
            fb_mem[cpu_oled_fb_addr] <= cpu_oled_fb_data;
        end
    end

    wire [9:0] oled_rd_addr;
    reg  [7:0] oled_rd_data;
    always @(*) begin
        oled_rd_data = fb_mem[oled_rd_addr];
    end

    ssd1306_controller u_oled (
        .clk      (CLK100MHZ),
        .rst      (rst),
        .fb_addr  (oled_rd_addr),
        .fb_data  (oled_rd_data),
        .oled_sclk(OLED_SCLK),
        .oled_mosi(OLED_MOSI),
        .oled_dc  (OLED_DC),
        .oled_res (OLED_RES),
        .oled_cs  (OLED_CS),
        .oled_vbat(OLED_VBAT),
        .oled_vdd (OLED_VDD)
    );

    reg [15:0] cpu_activity;
    always @(posedge CLK100MHZ) begin
        if (rst) begin
            cpu_activity <= 16'd0;
        end else if (cpu_display_we || cpu_oled_fb_we) begin
            cpu_activity <= cpu_activity + 16'd1;
        end
    end

    assign LED[3:0] = {btn_u, btn_d, btn_l, btn_r};
    assign LED[11:4] = cpu_oled_fb_data;
    assign LED[15:12] = cpu_activity[3:0];
endmodule
