# load_runner CPU game: 96x64 map window on 128x64 OLED
# MMIO
# 0x8000: buttons [3:0] => [UP,DOWN,LEFT,RIGHT]
# 0x8004: timer
# 0xA000..0xA3FF: framebuffer bytes

_start:
    addi x10, x0, 12      # player x [0..87]
    addi x11, x0, 56      # player y (page aligned)
    addi x12, x0, 0       # last timer
    addi x13, x0, 0       # coin flags bit0..2
    addi x14, x0, 0       # anim frame
    addi x15, x0, 80      # enemy x
    addi x16, x0, 56      # enemy y
    addi x18, x0, 127     # holeL x (127=none)
    addi x19, x0, 0       # holeL timer
    addi x20, x0, 127     # holeR x
    addi x21, x0, 0       # holeR timer
    lui  x30, 0x8         # IO base
    lui  x31, 0xA         # FB base

_tick_wait:
    lw   t0, 4(x30)
    sub  t1, t0, x12
    srli t1, t1, 19
    beq  t1, x0, _tick_wait
    addi x12, t0, 0
    addi x14, x14, 1
    andi x14, x14, 1

    lw   t2, 0(x30)

# ---------------- player ladder detect: t6=1 if on ladder ----------------
    addi t6, x0, 0
    addi t4, x10, -30
    blt  t4, x0, _lad_chk2
    addi t4, x10, -35
    bge  t4, x0, _lad_chk2
    addi t6, x0, 1
_lad_chk2:
    addi t4, x10, -62
    blt  t4, x0, _move_lr
    addi t4, x10, -67
    bge  t4, x0, _move_lr
    addi t6, x0, 1

# ---------------- movement ----------------
_move_lr:
    andi t3, t2, 8
    beq  t3, x0, _move_left
    addi t4, x10, -87
    bge  t4, x0, _move_left
    addi x10, x10, 1
_move_left:
    andi t3, t2, 4
    beq  t3, x0, _move_up
    addi t4, x10, -1
    blt  t4, x0, _move_up
    addi x10, x10, -1

_move_up:
    andi t3, t2, 1
    beq  t3, x0, _move_down
    beq  t6, x0, _move_down
    addi t4, x11, -8
    blt  t4, x0, _move_down
    addi x11, x11, -8

_move_down:
    andi t3, t2, 2
    beq  t3, x0, _dig_logic
    beq  t6, x0, _dig_logic
    addi t4, x11, -56
    bge  t4, x0, _dig_logic
    addi x11, x11, 8

# ---------------- dig: DOWN+LEFT / DOWN+RIGHT on ground ----------------
_dig_logic:
    addi t4, x11, -56
    bne  t4, x0, _hole_decay

    andi t3, t2, 2
    beq  t3, x0, _hole_decay

    andi t3, t2, 4
    beq  t3, x0, _dig_right
    addi t4, x10, -8
    blt  t4, x0, _dig_right
    andi t4, t4, -8
    addi x18, t4, 0
    addi x19, x0, 24

_dig_right:
    andi t3, t2, 8
    beq  t3, x0, _hole_decay
    addi t4, x10, 8
    addi t5, t4, -88
    bge  t5, x0, _hole_decay
    andi t4, t4, -8
    addi x20, t4, 0
    addi x21, x0, 24

# ---------------- hole timers ----------------
_hole_decay:
    beq  x19, x0, _hole_r_decay
    addi x19, x19, -1
    bne  x19, x0, _hole_r_decay
    addi x18, x0, 127
_hole_r_decay:
    beq  x21, x0, _gravity
    addi x21, x21, -1
    bne  x21, x0, _gravity
    addi x20, x0, 127

# ---------------- gravity ----------------
_gravity:
    # s7 = supported (0/1)
    addi s7, x0, 0
    beq  t6, x0, _sup_ground
    addi s7, x0, 1

_sup_ground:
    addi t4, x11, -56
    bne  t4, x0, _sup_mid
    addi s7, x0, 1
    # hole L under player?
    beq  x19, x0, _chk_hole_r_player
    sub  t4, x10, x18
    blt  t4, x0, _chk_hole_r_player
    addi t5, x0, 8
    blt  t4, t5, _unsup_by_hole
_chk_hole_r_player:
    beq  x21, x0, _sup_mid
    sub  t4, x10, x20
    blt  t4, x0, _sup_mid
    addi t5, x0, 8
    blt  t4, t5, _unsup_by_hole
    jal  x0, _sup_mid
_unsup_by_hole:
    addi s7, x0, 0

_sup_mid:
    addi t4, x11, -40
    bne  t4, x0, _sup_top
    addi t4, x10, -8
    blt  t4, x0, _sup_top
    addi t4, x10, -88
    blt  t4, x0, _set_sup_mid
    jal  x0, _sup_top
_set_sup_mid:
    addi s7, x0, 1

_sup_top:
    addi t4, x11, -24
    bne  t4, x0, _do_fall
    addi t4, x10, -20
    blt  t4, x0, _do_fall
    addi t4, x10, -76
    blt  t4, x0, _set_sup_top
    jal  x0, _do_fall
_set_sup_top:
    addi s7, x0, 1

_do_fall:
    bne  s7, x0, _enemy_ai
    addi t4, x11, -56
    bge  t4, x0, _enemy_ai
    addi x11, x11, 8

# ---------------- enemy AI with ladder usage ----------------
_enemy_ai:
    # enemy ladder detect t6
    addi t6, x0, 0
    addi t4, x15, -30
    blt  t4, x0, _e_lad_chk2
    addi t4, x15, -35
    bge  t4, x0, _e_lad_chk2
    addi t6, x0, 1
_e_lad_chk2:
    addi t4, x15, -62
    blt  t4, x0, _enemy_vertical
    addi t4, x15, -67
    bge  t4, x0, _enemy_vertical
    addi t6, x0, 1

_enemy_vertical:
    beq  t6, x0, _enemy_horizontal
    addi t4, x16, 0
    bge  t4, x11, _enemy_try_up
    addi t4, x16, -56
    bge  t4, x0, _enemy_horizontal
    addi x16, x16, 8
    jal  x0, _enemy_gravity
_enemy_try_up:
    addi t4, x16, -8
    blt  t4, x0, _enemy_horizontal
    addi x16, x16, -8
    jal  x0, _enemy_gravity

_enemy_horizontal:
    addi t4, x15, 0
    blt  t4, x10, _enemy_go_right
    beq  t4, x10, _enemy_gravity
    addi t4, x15, -1
    blt  t4, x0, _enemy_gravity
    addi x15, x15, -1
    jal  x0, _enemy_gravity
_enemy_go_right:
    addi t4, x15, -87
    bge  t4, x0, _enemy_gravity
    addi x15, x15, 1

_enemy_gravity:
    addi s7, x0, 0
    beq  t6, x0, _e_sup_ground
    addi s7, x0, 1
_e_sup_ground:
    addi t4, x16, -56
    bne  t4, x0, _e_sup_mid
    addi s7, x0, 1
_e_sup_mid:
    addi t4, x16, -40
    bne  t4, x0, _e_sup_top
    addi t4, x15, -8
    blt  t4, x0, _e_sup_top
    addi t4, x15, -88
    blt  t4, x0, _e_set_sup_mid
    jal  x0, _e_sup_top
_e_set_sup_mid:
    addi s7, x0, 1
_e_sup_top:
    addi t4, x16, -24
    bne  t4, x0, _e_do_fall
    addi t4, x15, -20
    blt  t4, x0, _e_do_fall
    addi t4, x15, -76
    blt  t4, x0, _e_set_sup_top
    jal  x0, _e_do_fall
_e_set_sup_top:
    addi s7, x0, 1
_e_do_fall:
    bne  s7, x0, _coin_logic
    addi t4, x16, -56
    bge  t4, x0, _coin_logic
    addi x16, x16, 8

# ---------------- coins ----------------
_coin_logic:
    # coin0 (70,40)
    andi t5, x13, 1
    bne  t5, x0, _coin1
    addi t4, x11, -40
    bne  t4, x0, _coin1
    addi t4, x10, -68
    blt  t4, x0, _coin1
    addi t4, x10, -73
    bge  t4, x0, _coin1
    ori  x13, x13, 1
_coin1:
    # coin1 (48,24)
    andi t5, x13, 2
    bne  t5, x0, _coin2
    addi t4, x11, -24
    bne  t4, x0, _coin2
    addi t4, x10, -46
    blt  t4, x0, _coin2
    addi t4, x10, -51
    bge  t4, x0, _coin2
    ori  x13, x13, 2
_coin2:
    # coin2 (84,56)
    andi t5, x13, 4
    bne  t5, x0, _hit_check
    addi t4, x11, -56
    bne  t4, x0, _hit_check
    addi t4, x10, -82
    blt  t4, x0, _hit_check
    addi t4, x10, -87
    bge  t4, x0, _hit_check
    ori  x13, x13, 4

# ---------------- collision ----------------
_hit_check:
    bne  x11, x16, _render
    sub  t4, x10, x15
    blt  t4, x0, _abs_neg
    jal  x0, _abs_done
_abs_neg:
    sub  t4, x0, t4
_abs_done:
    addi t5, x0, 4
    blt  t4, t5, _reset_player
    jal  x0, _render
_reset_player:
    addi x10, x0, 12
    addi x11, x0, 56

# ---------------- render ----------------
_render:
    # clear 1024 bytes
    addi t0, x0, 0
_r_clr:
    add  t1, x31, t0
    sb   x0, 0(t1)
    addi t0, t0, 1
    addi t2, x0, 1024
    blt  t0, t2, _r_clr

    # separator x=95 (all pages)
    addi t0, x0, 95
_r_sep:
    add  t1, x31, t0
    addi t3, x0, -1
    sb   t3, 0(t1)
    addi t0, t0, 128
    addi t2, x0, 1024
    blt  t0, t2, _r_sep

    # ground row page7 x0..95 textured brick
    addi t0, x0, 896
    addi t4, x0, 0
_r_ground:
    # default brick pattern by parity
    andi t5, t4, 1
    beq  t5, x0, _g_even
    addi t3, x0, -37    # 0xDB
    jal  x0, _g_holechk
_g_even:
    addi t3, x0, -67    # 0xBD
_g_holechk:
    # hole left
    beq  x19, x0, _g_hole_r
    sub  t6, t4, x18
    blt  t6, x0, _g_hole_r
    addi s7, x0, 8
    blt  t6, s7, _g_zero
_g_hole_r:
    beq  x21, x0, _g_store
    sub  t6, t4, x20
    blt  t6, x0, _g_store
    addi s7, x0, 8
    blt  t6, s7, _g_zero
    jal  x0, _g_store
_g_zero:
    addi t3, x0, 0
_g_store:
    add  t1, x31, t0
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t4, t4, 1
    addi t2, x0, 96
    blt  t4, t2, _r_ground

    # stone platform page5 x8..87 (alternating 0xAA/0x55)
    addi t0, x0, 648
    addi t4, x0, 8
_r_stone:
    andi t5, t4, 1
    beq  t5, x0, _s_even
    addi t3, x0, 85
    jal  x0, _s_store
_s_even:
    addi t3, x0, -86
_s_store:
    add  t1, x31, t0
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t4, t4, 1
    addi t2, x0, 88
    blt  t4, t2, _r_stone

    # top brick platform page3 x20..75 (0xE7/0x7E)
    addi t0, x0, 404
    addi t4, x0, 20
_r_top:
    andi t5, t4, 1
    beq  t5, x0, _tb_even
    addi t3, x0, 126
    jal  x0, _tb_store
_tb_even:
    addi t3, x0, -25
_tb_store:
    add  t1, x31, t0
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t4, t4, 1
    addi t2, x0, 76
    blt  t4, t2, _r_top

    # rope page2 x20..79 = 0x10
    addi t0, x0, 276
_r_rope:
    add  t1, x31, t0
    addi t3, x0, 16
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t2, x0, 336
    blt  t0, t2, _r_rope

    # ladders x30..34 and x62..66, pages3..7
    addi t0, x0, 414
_r_lad1:
    add  t1, x31, t0
    addi t3, x0, -1
    sb   t3, 0(t1)
    addi t4, t0, 1
    add  t1, x31, t4
    addi t3, x0, 36
    sb   t3, 0(t1)
    addi t4, t0, 2
    add  t1, x31, t4
    addi t3, x0, 126
    sb   t3, 0(t1)
    addi t4, t0, 3
    add  t1, x31, t4
    addi t3, x0, 36
    sb   t3, 0(t1)
    addi t4, t0, 4
    add  t1, x31, t4
    addi t3, x0, -1
    sb   t3, 0(t1)

    addi t0, t0, 128
    addi t2, x0, 1054
    blt  t0, t2, _r_lad1

    addi t0, x0, 446
_r_lad2:
    add  t1, x31, t0
    addi t3, x0, -1
    sb   t3, 0(t1)
    addi t4, t0, 1
    add  t1, x31, t4
    addi t3, x0, 36
    sb   t3, 0(t1)
    addi t4, t0, 2
    add  t1, x31, t4
    addi t3, x0, 126
    sb   t3, 0(t1)
    addi t4, t0, 3
    add  t1, x31, t4
    addi t3, x0, 36
    sb   t3, 0(t1)
    addi t4, t0, 4
    add  t1, x31, t4
    addi t3, x0, -1
    sb   t3, 0(t1)

    addi t0, t0, 128
    addi t2, x0, 1086
    blt  t0, t2, _r_lad2

    # coins (single-byte glyph)
    andi t5, x13, 1
    bne  t5, x0, _r_coin1
    addi t0, x0, 710
    add  t1, x31, t0
    addi t3, x0, 60
    sb   t3, 0(t1)
_r_coin1:
    andi t5, x13, 2
    bne  t5, x0, _r_coin2
    addi t0, x0, 432
    add  t1, x31, t0
    addi t3, x0, 60
    sb   t3, 0(t1)
_r_coin2:
    andi t5, x13, 4
    bne  t5, x0, _draw_enemy
    addi t0, x0, 980
    add  t1, x31, t0
    addi t3, x0, 60
    sb   t3, 0(t1)

# enemy sprite 8x8
_draw_enemy:
    srli t0, x16, 3
    slli t0, t0, 7
    add  t0, t0, x15
    add  t0, t0, x31

    addi t3, x0, 60
    sb   t3, 0(t0)
    addi t3, x0, 102
    sb   t3, 1(t0)
    addi t3, x0, -37
    sb   t3, 2(t0)
    addi t3, x0, -1
    sb   t3, 3(t0)
    addi t3, x0, -91
    sb   t3, 4(t0)
    addi t3, x0, 36
    sb   t3, 5(t0)
    addi t3, x0, 90
    sb   t3, 6(t0)
    addi t3, x0, -127
    sb   t3, 7(t0)

# player sprite 8x8, 2-frame
_draw_player:
    srli t0, x11, 3
    slli t0, t0, 7
    add  t0, t0, x10
    add  t0, t0, x31

    beq  x14, x0, _p_frame0
    addi t3, x0, 24
    sb   t3, 0(t0)
    addi t3, x0, 60
    sb   t3, 1(t0)
    addi t3, x0, 90
    sb   t3, 2(t0)
    addi t3, x0, 126
    sb   t3, 3(t0)
    addi t3, x0, 36
    sb   t3, 4(t0)
    addi t3, x0, 36
    sb   t3, 5(t0)
    addi t3, x0, 66
    sb   t3, 6(t0)
    addi t3, x0, 36
    sb   t3, 7(t0)
    jal  x0, _hud

_p_frame0:
    addi t3, x0, 24
    sb   t3, 0(t0)
    addi t3, x0, 60
    sb   t3, 1(t0)
    addi t3, x0, 90
    sb   t3, 2(t0)
    addi t3, x0, 126
    sb   t3, 3(t0)
    addi t3, x0, 36
    sb   t3, 4(t0)
    addi t3, x0, 36
    sb   t3, 5(t0)
    addi t3, x0, 36
    sb   t3, 6(t0)
    addi t3, x0, 102
    sb   t3, 7(t0)

# simple HUD in right panel x100/x108/x116 for coins
_hud:
    andi t5, x13, 1
    beq  t5, x0, _hud2
    addi t0, x0, 100
    add  t1, x31, t0
    addi t3, x0, -1
    sb   t3, 0(t1)
_hud2:
    andi t5, x13, 2
    beq  t5, x0, _hud3
    addi t0, x0, 108
    add  t1, x31, t0
    addi t3, x0, -1
    sb   t3, 0(t1)
_hud3:
    andi t5, x13, 4
    beq  t5, x0, _tick_wait
    addi t0, x0, 116
    add  t1, x31, t0
    addi t3, x0, -1
    sb   t3, 0(t1)

    jal  x0, _tick_wait
