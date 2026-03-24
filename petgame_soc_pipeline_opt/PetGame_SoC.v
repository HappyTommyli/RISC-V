module PetGame_SoC (
    input  wire       clk,
    input  wire       reset,
    input  wire [2:0] buttons,     // 實體按鈕 (餵食, 互動, 切換)
    output wire [3:0] leds,        // 狀態顯示
    // SPI 螢幕接口
    output wire screen_sclk,
    output wire screen_mosi,
    output wire screen_dc,
    output wire screen_cs
);

    // --- 1. Timer ---
    reg [31:0] timer_value;
    always @(posedge clk) begin
        if (reset) timer_value <= 32'b0;
        else       timer_value <= timer_value + 1;
    end

    // --- 2. Pipeline CPU ---
    wire display_we;
    wire [31:0] display_cmd;
    wire display_busy;

    pipeline cpu_inst (
        .clk(clk),
        .rst(reset),
        .buttons(buttons),
        .timer_value(timer_value),
        .display_busy(display_busy),
        .display_we(display_we),
        .display_cmd(display_cmd)
    );

    // --- 3. Display Engine ---
    Display_Engine gfx_engine (
        .clk(clk),
        .reset(reset),
        .cmd_data(display_cmd),
        .we(display_we),
        .busy(display_busy),
        .sclk(screen_sclk),
        .mosi(screen_mosi),
        .dc(screen_dc),
        .cs(screen_cs)
    );

    // --- 4. LEDs ---
    assign leds = {display_busy, buttons};

endmodule
