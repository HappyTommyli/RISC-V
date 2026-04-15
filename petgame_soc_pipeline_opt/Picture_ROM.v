module Picture_ROM (
    input  wire        clk,
    input  wire [11:0] addr, // 12 張圖 * 128 Byte = 1536
    output reg  [7:0]  dout
);
    localparam ROM_DEPTH = 1536;

    (* rom_style = "block" *) reg [7:0] rom [0:ROM_DEPTH-1];

    // 使用 include 載入數據
    initial begin
        `include "picture_rom_init.v"
    end

    always @(posedge clk) begin
        dout <= rom[addr];
    end
endmodule
