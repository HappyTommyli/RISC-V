module SSD1306_ImageTop (
    input  wire       clk,
    input  wire       reset,
    input  wire [2:0] buttons,     // kept for XDC compatibility
    output wire [3:0] leds,
    output wire       screen_sclk,
    output wire       screen_mosi,
    output wire       screen_dc,
    output wire       screen_cs
);
    // Select which image slot to display:
    // slot = pet_id * 5 + exp_id
    localparam [7:0] PET_ID = 8'd0;
    localparam [7:0] EXP_ID = 8'd0;

    reg  we_reg;
    wire busy;
    reg  sent_once;

    wire [31:0] cmd_data = {16'd0, PET_ID, EXP_ID};
    wire _unused_buttons = ^buttons;

    Display_Engine u_display (
        .clk    (clk),
        .reset  (reset),
        .cmd_data(cmd_data),
        .we     (we_reg),
        .busy   (busy),
        .sclk   (screen_sclk),
        .mosi   (screen_mosi),
        .dc     (screen_dc),
        .cs     (screen_cs)
    );

    always @(posedge clk) begin
        if (reset) begin
            we_reg    <= 1'b0;
            sent_once <= 1'b0;
        end else begin
            we_reg <= 1'b0;
            // Send one display command after init is done.
            if (!sent_once && !busy) begin
                we_reg    <= 1'b1;
                sent_once <= 1'b1;
            end
        end
    end

    // LEDs: [3]=busy, [2]=sent_once, [1:0]=0
    assign leds = {busy, sent_once, 2'b00};

endmodule
