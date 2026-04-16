module load_runner_top (
    input  wire       clk,          // 50MHz 外部時鐘
    input  wire       reset,        // BTNC (高電位有效)
    input  wire [3:0] buttons,      // [0:U, 1:D, 2:L, 3:R]
    output wire [3:0] leds,         // [3:Busy, 2:FB_WE, 1:Any_BTN, 0:Reset]
    output wire       screen_sclk,
    output wire       screen_mosi,
    output wire       screen_dc,
    output wire       screen_cs,
    output wire       screen_res
);

    // 1. Timer: 50MHz 下計數 (0x8004)
    reg [31:0] timer_cnt;
    always @(posedge clk) begin
        if (reset) timer_cnt <= 32'b0;
        else       timer_cnt <= timer_cnt + 1'b1;
    end

    wire        display_busy;
    wire        oled_fb_we;
    wire [9:0]  oled_fb_addr;
    wire [7:0]  oled_fb_data;
    wire        display_we;
    wire [31:0] display_cmd;

    // 2. CPU 實例化
    pipeline cpu_core (
        .clk(clk),
        .rst(reset),
        .buttons(buttons),
        .timer_value(timer_cnt),
        .display_busy(display_busy),
        
        // 顯存接口
        .oled_fb_we(oled_fb_we),
        .oled_fb_addr(oled_fb_addr),
        .oled_fb_data(oled_fb_data),
        
        // 控制接口
        .display_we(display_we),
        .display_cmd(display_cmd)
    );

    // 3. 顯示引擎 (請使用帶有 ST_FRAME_READ 延遲的版本)
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
        .cs(screen_cs),
        .res(screen_res)
    );

    // 4. LED 偵錯分配 (根據你的 XDC leds[0]~[3])
    // leds[0] (U16): Reset 狀態 (按住 BTNC 時應該亮起)
    // leds[1] (E19): 任何按鈕按下時亮起 (測試按鈕輸入是否正常)
    // leds[2] (U19): [最重要] 顯存寫入閃爍燈 (CPU 繪圖時會閃)
    // leds[3] (V19): 顯示引擎忙碌燈 (刷新螢幕時會亮)
    
    assign leds[0] = reset;
    assign leds[1] = |buttons;
    assign leds[2] = oled_fb_we;
    assign leds[3] = display_busy;

endmodule