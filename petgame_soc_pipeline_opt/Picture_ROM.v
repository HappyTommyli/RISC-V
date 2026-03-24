module Picture_ROM (
    input  wire        clk,
    input  wire [17:0] addr,
    output reg  [15:0] dout
);
    // ROM depth: 5 pets * 5 expressions * 32*32 = 25600
    // If you change pets/expressions/size, update ROM_DEPTH and addr width.
    localparam ROM_DEPTH = 25600;

    (* rom_style = "block" *) reg [15:0] rom [0:ROM_DEPTH-1];

    // Paste your generated init block here:
    // initial begin
    //     rom[0] = 16'h....;
    // end

    always @(posedge clk) begin
        dout <= rom[addr];
    end
endmodule
