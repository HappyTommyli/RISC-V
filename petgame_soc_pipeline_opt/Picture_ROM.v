module Picture_ROM (
    input  wire        clk,
    input  wire [17:0] addr,
    output reg  [15:0] dout
);
    // ROM depth: 4 pets * 3 expressions * 32*32 = 12288
    // If you change pets/expressions/size, update ROM_DEPTH and addr width.
    localparam ROM_DEPTH = 12288;

    (* rom_style = "block" *) reg [15:0] rom [0:ROM_DEPTH-1];

    // Auto-generated image init.
    // Re-generate tools/picture_rom_init.v with:
    // tools/img_to_ssd1306_picture_rom.py
`include "picture_rom_init.v"

    always @(posedge clk) begin
        dout <= rom[addr];
    end
endmodule
