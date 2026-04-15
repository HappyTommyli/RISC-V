module SSD1306_ImageTop (
    input  wire       clk,
    input  wire       reset,
    input  wire [2:0] buttons,
    output wire [3:0] leds,
    output wire       screen_sclk,
    output wire       screen_mosi,
    output wire       screen_dc,
    output wire       screen_cs
);
    localparam [31:0] SWAP_INTERVAL = 32'd100_000_000; // 1s @100MHz

    reg  we_reg;
    wire busy;
    reg  sent_once;
    reg  pet_sel;      // 0: cat, 1: dog
    reg [31:0] swap_cnt;

    wire [31:0] cmd_data = {16'd0, pet_sel ? 8'd1 : 8'd0, 8'd0};
    wire _unused_buttons = ^buttons;

    Display_Engine u_display (
        .clk          (clk),
        .reset        (reset),
        .cmd_data     (cmd_data),
        .we           (we_reg),
        .invert_toggle(1'b0),
        .all_on_toggle(1'b0),
        .redraw_pulse (1'b0),
        .busy         (busy),
        .sclk         (screen_sclk),
        .mosi         (screen_mosi),
        .dc           (screen_dc),
        .cs           (screen_cs)
    );

    always @(posedge clk) begin
        if (reset) begin
            we_reg    <= 1'b0;
            sent_once <= 1'b0;
            pet_sel   <= 1'b0;
            swap_cnt  <= 32'd0;
        end else begin
            we_reg <= 1'b0;

            if (!busy) begin
                if (!sent_once) begin
                    // First frame: cat.
                    we_reg    <= 1'b1;
                    sent_once <= 1'b1;
                    swap_cnt  <= 32'd0;
                end else if (swap_cnt == SWAP_INTERVAL - 1) begin
                    // Toggle between cat and dog.
                    pet_sel  <= ~pet_sel;
                    we_reg   <= 1'b1;
                    swap_cnt <= 32'd0;
                end else begin
                    swap_cnt <= swap_cnt + 1'b1;
                end
            end
        end
    end

    // LEDs: [3]=busy, [2]=current pet (0 cat/1 dog), [1]=sent_once, [0]=0
    assign leds = {busy, pet_sel, sent_once, 1'b0};

endmodule
