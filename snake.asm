# 暫存器規劃 (維持原樣，但程式碼中改用更嚴謹的寫法)
# x8(s0): VRAM, x9(s1): MMIO, x18(s2): Queue, x19(s3): 方向
# x0: 常數 0 (RISC-V 硬體內建)

_boot:
    # 載入基底地址 (使用標準 lui 指令)
    lui x8, 10           # s0 = 0x0000A000 (VRAM)
    lui x9, 8            # s1 = 0x00008000 (MMIO)
    lui x18, 2           # s2 = 0x00002000 (RAM)
    
    # 載入立即數 (li 改用 addi)
    addi x23, x0, 1024   # s7 = 1024 (速度門檻)
    addi x26, x0, 0      # s10 = 0 (時間戳)

_wait_for_start:
    lw   x5, 8(x9)       # t0 = lw from MMIO 0x8008
    andi x5, x5, 1       # t0 = t0 & 1
    beq  x5, x0, -8      # 若 Sw0 為 0，跳回 _wait_for_start (這裡偏移量需根據實作計算)

_init_game:
    # 1. 清空 VRAM (0xA000 - 0xA07F)
    addi x5, x0, 0       # t0 = 0 (計數器)
_clear_fb:
    add  x6, x8, x5      # t1 = VRAM_Base + t0
    sb   x0, 0(x6)       # 使用 sb 指令，寫入 x0 (0)
    addi x5, x5, 1       # t0 = t0 + 1
    addi x7, x0, 128     # t2 = 128
    blt  x5, x7, -16     # if t0 < 128, jump back to _clear_fb

    # 2. 初始化蛇
    addi x19, x0, 1      # s3 = 1 (方向：右)
    addi x20, x0, 64     # s4 = 64 (頭坐標)
    addi x21, x0, 0      # s5 = 0 (尾 Index)
    addi x22, x0, 1      # s6 = 1 (頭 Index)
    
    sw   x20, 0(x18)     # Queue[0] = 64 (x18 是 s2)
    
    add  x5, x8, x20     # t0 = VRAM + 64
    addi x6, x0, 255     # t1 = 0xFF (蛇身圖案)
    sb   x6, 0(x5)

_gen_food:
    lw   x5, 4(x9)       # t0 = Timer (隨機數)
    andi x5, x5, 127     # t0 = t0 % 128
    add  x6, x8, x5      # t1 = VRAM + t0
    lbu  x7, 0(x6)       # t2 = lbu (讀取該點)
    bne  x7, x0, -16     # 若不為空，跳回 _gen_food
    addi x7, x0, 170     # t2 = 0xAA (食物圖案)
    sb   x7, 0(x6)

_game_loop:
    # A. 檢查 Sw0
    lw   x5, 8(x9)
    andi x5, x5, 1
    beq  x5, x0, _wait_for_start # (彙編器會自動轉成 jal x0 或相對偏移)

    # B. 更新方向 (BTNs)
    lw   x5, 0(x9)       # 讀取按鈕
    
    # 右鍵判斷
    andi x6, x5, 8
    beq  x6, x0, 8       # 若沒按右鍵，跳過下一行
    addi x19, x0, 1      # s3 = 1
    # 左鍵判斷
    andi x6, x5, 4
    beq  x6, x0, 8
    addi x19, x0, -1     # s3 = -1
    # 下鍵判斷
    andi x6, x5, 2
    beq  x6, x0, 8
    addi x19, x0, 16     # s3 = 16
    # 上鍵判斷
    andi x6, x5, 1
    beq  x6, x0, 8
    addi x19, x0, -16    # s3 = -16

_check_timer:
    lw   x5, 4(x9)       # t0 = Timer
    sub  x6, x5, x26     # t1 = Timer - s10
    blt  x6, x23, _game_loop # 若還沒到門檻，回迴圈
    addi x26, x5, 0      # s10 = Timer (這就是 mv 指令的本體)

_move_step:
    add  x5, x20, x19     # t0 = s4 + s3 (新頭坐標)
    andi x5, x5, 127      # 邊界環繞

    add  x6, x8, x5       # t1 = VRAM + t0
    lbu  x7, 0(x6)        # t2 = 讀取內容
    addi x28, x0, 170     # t3 = 0xAA (食物)
    beq  x7, x28, _eat_food

_move_normal:
    # 抹除尾巴
    slli x6, x21, 2       # t1 = s5 << 2
    add  x6, x18, x6      # t1 = Queue + t1
    lw   x7, 0(x6)        # t2 = 舊尾巴坐標
    add  x28, x8, x7      # t3 = VRAM + t2
    sb   x0, 0(x28)       # 抹除
    
    addi x21, x21, 1      # s5++ (尾 Index)
    addi x29, x0, 256     # t4 = 256
    blt  x21, x29, 8
    addi x21, x0, 0       # 環狀重置

_draw_new_head:
    # 存入新頭到 Queue
    slli x6, x22, 2
    add  x6, x18, x6
    sw   x5, 0(x6)        # 將新頭坐標存入 Queue
    
    addi x22, x22, 1      # s6++ (頭 Index)
    addi x29, x0, 256
    blt  x22, x29, 8
    addi x22, x0, 0
    
    # 畫出新頭
    add  x6, x8, x5
    addi x7, x0, 255      # 0xFF
    sb   x7, 0(x6)
    addi x20, x5, 0       # s4 = t0 (更新頭部位置)
    jal  x0, _game_loop   # (這就是 j 指令的本體)

_eat_food:
    jal  x0, _draw_new_head
    jal  x0, _gen_food