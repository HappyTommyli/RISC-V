integer i;
initial begin
    // 初始化 ROM，默认全黑 (0) 或全亮 (ffff)，取决于你的显示偏好
    for (i = 0; i < ROM_DEPTH; i = i + 1) rom[i] = 16'h0000;

    // 32x32 图像数据 (共 64 个 16-bit 字)
    // 每 2 个 rom 条目代表图像的一行 (32 bits)

    // Row 1-4: 空白背景
    rom[0]  = 16'h0000; rom[1]  = 16'h0000;
    rom[2]  = 16'h0000; rom[3]  = 16'h0000;
    rom[4]  = 16'h0000; rom[5]  = 16'h0000;
    rom[6]  = 16'h0000; rom[7]  = 16'h0000;

    // Row 5: 猫耳尖
    rom[8]  = 16'h000E; rom[9]  = 16'h7000; 
    rom[10] = 16'h001F; rom[11] = 16'hF800; 
    rom[12] = 16'h003F; rom[13] = 16'hFC00; 
    rom[14] = 16'h007F; rom[15] = 16'hFE00; 

    // Row 9: 头部轮廓
    rom[16] = 16'h007F; rom[17] = 16'hFE00;
    rom[18] = 16'h00FF; rom[19] = 16'hFF00;
    rom[20] = 16'h00FF; rom[21] = 16'hFF00;
    rom[22] = 16'h00FF; rom[23] = 16'hFF00;

    // Row 13: 眼睛部分 (包含 0 组成的空洞)
    rom[24] = 16'h00DB; rom[25] = 16'hDB00;
    rom[26] = 16'h00DB; rom[27] = 16'hDB00;
    rom[28] = 16'h00FF; rom[29] = 16'hFF00;
    rom[30] = 16'h00E7; rom[31] = 16'hE700;

    // Row 17: 身体与尾巴
    rom[32] = 16'h00FF; rom[33] = 16'hFF00;
    rom[34] = 16'h00FF; rom[35] = 16'hFF18;
    rom[36] = 16'h007F; rom[37] = 16'hFE3C;
    rom[38] = 16'h047F; rom[39] = 16'hFE3C;

    // Row 21: 身体轮廓
    rom[40] = 16'h007F; rom[41] = 16'hFE3C;
    rom[42] = 16'h003F; rom[43] = 16'hFC3C;
    rom[44] = 16'h003F; rom[45] = 16'hFC1C;
    rom[46] = 16'h001F; rom[47] = 16'hF800;

    // Row 25-32: 底部收尾/草地边缘
    rom[48] = 16'h0000; rom[49] = 16'h0000;
    rom[50] = 16'h0000; rom[51] = 16'h0000;
    rom[52] = 16'h0000; rom[53] = 16'h0000;
    rom[54] = 16'h0000; rom[55] = 16'h0000;
    rom[56] = 16'h0000; rom[57] = 16'h0000;
    rom[58] = 16'h0000; rom[59] = 16'h0000;
    rom[60] = 16'h0000; rom[61] = 16'h0000;
    rom[62] = 16'h0000; rom[63] = 16'h0000;
end