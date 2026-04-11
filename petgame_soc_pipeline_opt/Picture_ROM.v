module Picture_ROM (
    input  wire        clk,
    input  wire [17:0] addr,
    output reg  [15:0] dout
);
    // ROM depth: 4 pets * 3 expressions * 32*32 = 12288
    // If you change pets/expressions/size, update ROM_DEPTH and addr width.
    localparam ROM_DEPTH = 12288;

    (* rom_style = "block" *) reg [15:0] rom [0:ROM_DEPTH-1];

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

    initial begin
        integer i;
        
        // 1. 先把整個 ROM 預設為全黑 (16'h0000)
        // 這樣 pet1_exp0 和 pet2_exp0 就會自動是全黑了
        for (i = 0; i < ROM_DEPTH; i = i + 1) begin
            rom[i] = 16'h0000;
        end

        // 2. 將 pet0_exp0 (位址 0 ~ 1023) 設為全亮白 (16'hffff)
        for (i = 0; i < 1024; i = i + 1) begin
            rom[i] = 16'hffff;
        end

        // 3. 將 pet3_exp0 (位址 9216 ~ 10239) 設為全亮白 (16'hffff)
        for (i = 9216; i < 10240; i = i + 1) begin
            rom[i] = 16'hffff;
        end
        
    end

    always @(posedge clk) begin
        dout <= rom[addr];
    end
endmodule