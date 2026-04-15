module Picture_ROM (
    input  wire        clk,
    input  wire [11:0] addr, 
    output reg  [7:0]  dout
);
    // 定義 ROM 空間
    reg [7:0] rom [0:383]; 
    integer i;

    // 這裡放入 initial 區塊
    initial begin
        // 先將所有空間清零，防止出現未知態 (X)
        for (i = 0; i < 384; i = i + 1) begin
            rom[i] = 8'h00;
        end

        // 引入純數據賦值的檔案
        `include "picture_rom_init.v"
    end

    always @(posedge clk) begin
        dout <= rom[addr];
    end
endmodule
