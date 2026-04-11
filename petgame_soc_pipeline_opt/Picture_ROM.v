module Picture_ROM (
    input  wire        clk,
    input  wire [17:0] addr,
    output reg  [15:0] dout
);
    // ROM depth: 4 pets * 3 expressions * 32*32 = 12288
    // If you change pets/expressions/size, update ROM_DEPTH and addr width.
    localparam ROM_DEPTH = 12288;

    (* rom_style = "block" *) reg [15:0] rom [0:ROM_DEPTH-1];

    // Auto-generated image init (cat at pet0_exp0, others black).
    initial begin
        integer i;
        for (i = 0; i < ROM_DEPTH; i = i + 1) rom[i] = 16'h0000;

        // ROM layout (each image = 1024 entries):
        // pet0_exp0: rom[0..1023]
        // pet0_exp1: rom[1024..2047]
        // pet0_exp2: rom[2048..3071]
        // pet1_exp0: rom[3072..4095]
        // pet1_exp1: rom[4096..5119]
        // pet1_exp2: rom[5120..6143]
        // pet2_exp0: rom[6144..7167]
        // pet2_exp1: rom[7168..8191]
        // pet2_exp2: rom[8192..9215]
        // pet3_exp0: rom[9216..10239]
        // pet3_exp1: rom[10240..11263]
        // pet3_exp2: rom[11264..12287]

        // 32x32 cat image payload starts at rom[0] (pet0 exp0)
        rom[135] = 16'hffff;
        rom[136] = 16'hffff;
        rom[148] = 16'hffff;
        rom[149] = 16'hffff;
        rom[166] = 16'hffff;
        rom[169] = 16'hffff;
        rom[179] = 16'hffff;
        rom[202] = 16'hffff;
        rom[204] = 16'hffff;
        rom[205] = 16'hffff;
        rom[206] = 16'hffff;
        rom[207] = 16'hffff;
        rom[208] = 16'hffff;
        rom[214] = 16'hffff;
        rom[235] = 16'hffff;
        rom[236] = 16'hffff;
        rom[238] = 16'hffff;
        rom[241] = 16'hffff;
        rom[243] = 16'hffff;
        rom[246] = 16'hffff;
        rom[278] = 16'hffff;
        rom[296] = 16'hffff;
        rom[308] = 16'hffff;
        rom[310] = 16'hffff;
        rom[326] = 16'hffff;
        rom[333] = 16'hffff;
        rom[358] = 16'hffff;
        rom[406] = 16'hffff;
        rom[425] = 16'hffff;
        rom[433] = 16'hffff;
        rom[438] = 16'hffff;
        rom[456] = 16'hffff;
        rom[457] = 16'hffff;
        rom[458] = 16'hffff;
        rom[464] = 16'hffff;
        rom[465] = 16'hffff;
        rom[466] = 16'hffff;
        rom[470] = 16'hffff;
        rom[489] = 16'hffff;
        rom[497] = 16'hffff;
        rom[502] = 16'hffff;
        rom[523] = 16'hffff;
        rom[525] = 16'hffff;
        rom[526] = 16'hffff;
        rom[534] = 16'hffff;
        rom[550] = 16'hffff;
        rom[556] = 16'hffff;
        rom[568] = 16'hffff;
        rom[569] = 16'hffff;
        rom[570] = 16'hffff;
        rom[584] = 16'hffff;
        rom[595] = 16'hffff;
        rom[596] = 16'hffff;
        rom[599] = 16'hffff;
        rom[603] = 16'hffff;
        rom[617] = 16'hffff;
        rom[618] = 16'hffff;
        rom[626] = 16'hffff;
        rom[629] = 16'hffff;
        rom[631] = 16'hffff;
        rom[636] = 16'hffff;
        rom[649] = 16'hffff;
        rom[664] = 16'hffff;
        rom[668] = 16'hffff;
        rom[680] = 16'hffff;
        rom[681] = 16'hffff;
        rom[691] = 16'hffff;
        rom[694] = 16'hffff;
        rom[697] = 16'hffff;
        rom[699] = 16'hffff;
        rom[700] = 16'hffff;
        rom[712] = 16'hffff;
        rom[713] = 16'hffff;
        rom[727] = 16'hffff;
        rom[729] = 16'hffff;
        rom[732] = 16'hffff;
        rom[744] = 16'hffff;
        rom[745] = 16'hffff;
        rom[757] = 16'hffff;
        rom[759] = 16'hffff;
        rom[760] = 16'hffff;
        rom[763] = 16'hffff;
        rom[777] = 16'hffff;
        rom[786] = 16'hffff;
        rom[790] = 16'hffff;
        rom[791] = 16'hffff;
        rom[795] = 16'hffff;
        rom[804] = 16'hffff;
        rom[809] = 16'hffff;
        rom[813] = 16'hffff;
        rom[822] = 16'hffff;
        rom[823] = 16'hffff;
        rom[826] = 16'hffff;
        rom[837] = 16'hffff;
        rom[838] = 16'hffff;
        rom[845] = 16'hffff;
        rom[849] = 16'hffff;
        rom[855] = 16'hffff;
        rom[856] = 16'hffff;
        rom[857] = 16'hffff;
        rom[858] = 16'hffff;
        rom[868] = 16'hffff;
        rom[870] = 16'hffff;
        rom[872] = 16'hffff;
        rom[873] = 16'hffff;
        rom[877] = 16'hffff;
        rom[881] = 16'hffff;
        rom[886] = 16'hffff;
        rom[887] = 16'hffff;
        rom[888] = 16'hffff;
        rom[889] = 16'hffff;
        rom[891] = 16'hffff;
        rom[899] = 16'hffff;
        rom[902] = 16'hffff;
        rom[903] = 16'hffff;
        rom[904] = 16'hffff;
        rom[905] = 16'hffff;
        rom[909] = 16'hffff;
        rom[913] = 16'hffff;
        rom[918] = 16'hffff;
        rom[919] = 16'hffff;
        rom[920] = 16'hffff;
        rom[933] = 16'hffff;
        rom[935] = 16'hffff;
        rom[937] = 16'hffff;
        rom[938] = 16'hffff;
        rom[939] = 16'hffff;
        rom[940] = 16'hffff;
        rom[941] = 16'hffff;
        rom[942] = 16'hffff;
        rom[943] = 16'hffff;
        rom[944] = 16'hffff;
        rom[945] = 16'hffff;
        rom[946] = 16'hffff;
        rom[947] = 16'hffff;
        rom[948] = 16'hffff;
        rom[949] = 16'hffff;
        rom[950] = 16'hffff;
        rom[951] = 16'hffff;
        rom[953] = 16'hffff;
        rom[954] = 16'hffff;
    end

    always @(posedge clk) begin
        dout <= rom[addr];
    end
endmodule
