`timescale 1ns / 1ps

module top(
    input clk_100mhz,
    input rst_n,
    input [3:0] btns,   // 開發板上的上下左右按鈕
    input sw0,          // 開發板上的開關 (重置/開始遊戲)
    // SSD1306 OLED 7 針介面
    output oled_sdin,
    output oled_sclk,
    output oled_dc,
    output oled_res,
    output oled_cs
);
    // 降頻至 50MHz 以符合你的 57.8MHz 效能限制
    wire clk;
    clk_wiz_0 instance_name (.clk_out1(clk), .clk_in1(clk_100mhz));

    wire rst = !rst_n;

    // VRAM 專用接線 (讓 OLED 驅動器去讀 Data_Mem 裡的 VRAM)
    wire [6:0] vram_disp_addr;
    wire [7:0] vram_disp_data;

    // 實例化你自己的 pipeline
    pipeline cpu_inst (
        .clk(clk),
        .rst(rst),
        .btns(btns),
        .sw0(sw0),
        .vram_disp_addr(vram_disp_addr),
        .vram_disp_data(vram_disp_data)
    );

    // 實例化 7 針 SSD1306 驅動器
    ssd1306_driver oled_inst (
        .clk(clk),
        .rst(rst),
        .vram_data(vram_disp_data),
        .vram_addr(vram_disp_addr),
        .sdin(oled_sdin),
        .sclk(oled_sclk),
        .dc(oled_dc),
        .res(oled_res),
        .cs(oled_cs)
    );
endmodule