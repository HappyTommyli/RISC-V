module Display_Engine (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cmd_data,    // [15:8]=PetID, [7:0]=ExpID
    input  wire        we,          // write enable (from 0x9000 store)
    output reg         busy,
    output reg         sclk,
    output reg         mosi,
    output reg         dc,
    output reg         cs
);
    // Simple skeleton state machine (SPI logic to be implemented later)
    localparam IDLE  = 2'd0;
    localparam FETCH = 2'd1;
    localparam SEND  = 2'd2;

    reg [1:0]  state;
    reg [14:0] pixel_cnt;   // 0..1023 for 32x32
    reg [17:0] start_addr;  // enough for 5*5*1024=25600 entries

    // Example ROM hookup (RGB565 pixel stream)
    wire [15:0] current_pixel;
    Picture_ROM rom_inst (
        .clk(clk),
        .addr(start_addr + pixel_cnt),
        .dout(current_pixel)
    );

    // NOTE: This is a placeholder. It only latches command and returns to IDLE.
    //       Replace with real SPI init + data streaming when display arrives.
    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            pixel_cnt  <= 0;
            start_addr <= 0;
            busy       <= 1'b0;
            sclk       <= 1'b0;
            mosi       <= 1'b0;
            dc         <= 1'b0;
            cs         <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (we) begin
                        // (PetID * 5 + ExpID) * 1024
                        start_addr <= (cmd_data[15:8] * 5 + cmd_data[7:0]) << 10;
                        pixel_cnt  <= 0;
                        busy       <= 1'b1;
                        state      <= FETCH;
                    end
                end
                FETCH: begin
                    // Placeholder: transition immediately to IDLE
                    state <= IDLE;
                end
                SEND: begin
                    // Placeholder for SPI streaming logic
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
