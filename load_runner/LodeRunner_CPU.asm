# load_runner CPU game: redesigned 128x64 map (Lode Runner style)
# MMIO
# 0x8000: buttons [3:0] => [UP,DOWN,LEFT,RIGHT]
# 0x8004: timer
# 0xA000..0xA3FF: framebuffer bytes

_start:
    addi x10, x0, 8       # player x
    addi x11, x0, 56      # player y (page aligned)
    addi x12, x0, 0       # last timer
    addi x13, x0, 0       # coin flags bit0..4
    addi x14, x0, 0       # anim frame
    addi x15, x0, 104     # enemy x
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
    # ladder1 x16..20, y24..56
    addi t4, x10, -16
    blt  t4, x0, _p_lad2
    addi t5, x10, -21
    bge  t5, x0, _p_lad2
    addi t5, x11, -24
    blt  t5, x0, _p_lad2
    addi t5, x11, -57
    bge  t5, x0, _p_lad2
    addi t6, x0, 1
_p_lad2:
    # ladder2 x56..60, y24..40
    addi t4, x10, -56
    blt  t4, x0, _p_lad3
    addi t5, x10, -61
    bge  t5, x0, _p_lad3
    addi t5, x11, -24
    blt  t5, x0, _p_lad3
    addi t5, x11, -41
    bge  t5, x0, _p_lad3
    addi t6, x0, 1
_p_lad3:
    # ladder3 x96..100, y24..56
    addi t4, x10, -96
    blt  t4, x0, _p_rope
    addi t5, x10, -101
    bge  t5, x0, _p_rope
    addi t5, x11, -24
    blt  t5, x0, _p_rope
    addi t5, x11, -57
    bge  t5, x0, _p_rope
    addi t6, x0, 1

# ---------------- player rope detect: s6=1 if on rope ----------------
_p_rope:
    addi s6, x0, 0
    addi t4, x11, -16
    bne  t4, x0, _move_lr
    addi t4, x10, -24
    blt  t4, x0, _move_lr
    addi t4, x10, -104
    bge  t4, x0, _move_lr
    addi s6, x0, 1

# ---------------- movement ----------------
_move_lr:
    andi t3, t2, 8
    beq  t3, x0, _move_left
    addi t4, x10, -119
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
    bne  t6, x0, _do_move_down
    beq  s6, x0, _dig_logic
_do_move_down:
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
    addi t5, t4, -120
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
    bne  t6, x0, _set_sup_ladder
    jal  x0, _sup_rope
_set_sup_ladder:
    addi s7, x0, 1

_sup_rope:
    beq  s6, x0, _sup_ground
    addi s7, x0, 1

_sup_ground:
    addi t4, x11, -56
    bne  t4, x0, _sup_p5
    addi s7, x0, 1
    beq  x19, x0, _chk_hole_r_player
    sub  t4, x10, x18
    blt  t4, x0, _chk_hole_r_player
    addi t5, x0, 8
    blt  t4, t5, _unsup_by_hole
_chk_hole_r_player:
    beq  x21, x0, _sup_p5
    sub  t4, x10, x20
    blt  t4, x0, _sup_p5
    addi t5, x0, 8
    blt  t4, t5, _unsup_by_hole
    jal  x0, _sup_p5
_unsup_by_hole:
    addi s7, x0, 0

_sup_p5:
    addi t4, x11, -40
    bne  t4, x0, _sup_p4
    addi t4, x10, -16
    blt  t4, x0, _sup_p4
    addi t4, x10, -112
    bge  t4, x0, _sup_p4
    addi s7, x0, 1

_sup_p4:
    addi t4, x11, -32
    bne  t4, x0, _sup_p3
    addi t4, x10, -24
    blt  t4, x0, _sup_p3
    addi t4, x10, -96
    bge  t4, x0, _sup_p3
    addi s7, x0, 1

_sup_p3:
    addi t4, x11, -24
    bne  t4, x0, _do_fall
    addi t4, x10, -32
    blt  t4, x0, _do_fall
    addi t4, x10, -88
    bge  t4, x0, _do_fall
    addi s7, x0, 1

_do_fall:
    bne  s7, x0, _enemy_ai
    addi t4, x11, -56
    bge  t4, x0, _enemy_ai
    addi x11, x11, 8

# ---------------- enemy AI ----------------
_enemy_ai:
    # enemy ladder detect -> t6
    addi t6, x0, 0
    addi t4, x15, -16
    blt  t4, x0, _e_lad2
    addi t5, x15, -21
    bge  t5, x0, _e_lad2
    addi t5, x16, -24
    blt  t5, x0, _e_lad2
    addi t5, x16, -57
    bge  t5, x0, _e_lad2
    addi t6, x0, 1
_e_lad2:
    addi t4, x15, -56
    blt  t4, x0, _e_lad3
    addi t5, x15, -61
    bge  t5, x0, _e_lad3
    addi t5, x16, -24
    blt  t5, x0, _e_lad3
    addi t5, x16, -41
    bge  t5, x0, _e_lad3
    addi t6, x0, 1
_e_lad3:
    addi t4, x15, -96
    blt  t4, x0, _e_rope
    addi t5, x15, -101
    bge  t5, x0, _e_rope
    addi t5, x16, -24
    blt  t5, x0, _e_rope
    addi t5, x16, -57
    bge  t5, x0, _e_rope
    addi t6, x0, 1

_e_rope:
    addi s6, x0, 0

_enemy_vertical:
    beq  t6, x0, _enemy_horizontal
    addi t4, x16, 0
    bge  t4, x11, _enemy_try_up
    addi t4, x16, -56
    bge  t4, x0, _enemy_horizontal
    addi x16, x16, 8
    jal  x0, _enemy_gravity
_enemy_try_up:
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
    addi t4, x15, -119
    bge  t4, x0, _enemy_gravity
    addi x15, x15, 1

_enemy_gravity:
    addi s7, x0, 0
    beq  t6, x0, _e_sup_ground
    addi s7, x0, 1

_e_sup_ground:
    addi t4, x16, -56
    bne  t4, x0, _e_sup_p5
    addi s7, x0, 1

_e_sup_p5:
    addi t4, x16, -40
    bne  t4, x0, _e_sup_p4
    addi t4, x15, -16
    blt  t4, x0, _e_sup_p4
    addi t4, x15, -112
    bge  t4, x0, _e_sup_p4
    addi s7, x0, 1
_e_sup_p4:
    addi t4, x16, -32
    bne  t4, x0, _e_sup_p3
    addi t4, x15, -24
    blt  t4, x0, _e_sup_p3
    addi t4, x15, -96
    bge  t4, x0, _e_sup_p3
    addi s7, x0, 1
_e_sup_p3:
    addi t4, x16, -24
    bne  t4, x0, _e_do_fall
    addi t4, x15, -32
    blt  t4, x0, _e_do_fall
    addi t4, x15, -88
    bge  t4, x0, _e_do_fall
    addi s7, x0, 1
_e_do_fall:
    bne  s7, x0, _coin_logic
    addi t4, x16, -56
    bge  t4, x0, _coin_logic
    addi x16, x16, 8

# ---------------- coins ----------------
_coin_logic:
    # coin0 (40,40) bit0
    andi t5, x13, 1
    bne  t5, x0, _coin1
    addi t4, x11, -40
    bne  t4, x0, _coin1
    addi t4, x10, -38
    blt  t4, x0, _coin1
    addi t4, x10, -43
    bge  t4, x0, _coin1
    ori  x13, x13, 1
_coin1:
    # coin1 (72,32) bit1
    andi t5, x13, 2
    bne  t5, x0, _coin2
    addi t4, x11, -32
    bne  t4, x0, _coin2
    addi t4, x10, -70
    blt  t4, x0, _coin2
    addi t4, x10, -75
    bge  t4, x0, _coin2
    ori  x13, x13, 2
_coin2:
    # coin2 (96,24) bit2
    andi t5, x13, 4
    bne  t5, x0, _coin3
    addi t4, x11, -24
    bne  t4, x0, _coin3
    addi t4, x10, -94
    blt  t4, x0, _coin3
    addi t4, x10, -99
    bge  t4, x0, _coin3
    ori  x13, x13, 4
_coin3:
    # coin3 (56,56) bit3
    andi t5, x13, 8
    bne  t5, x0, _win_check
    addi t4, x11, -56
    bne  t4, x0, _win_check
    addi t4, x10, -54
    blt  t4, x0, _win_check
    addi t4, x10, -59
    bge  t4, x0, _win_check
    ori  x13, x13, 8

# ---------------- win loop ----------------
_win_check:
    addi t4, x13, -15
    bne  t4, x0, _hit_check
    addi x13, x0, 0
    addi x10, x0, 8
    addi x11, x0, 56

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
    addi x10, x0, 8
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

    # ground row page7 x0..127 textured brick + holes
    addi t0, x0, 896
    addi t4, x0, 0
_r_ground:
    andi t5, t4, 1
    beq  t5, x0, _g_even
    addi t3, x0, -37    # 0xDB
    jal  x0, _g_holechk
_g_even:
    addi t3, x0, -67    # 0xBD
_g_holechk:
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
    addi t2, x0, 128
    blt  t4, t2, _r_ground

    # platform page5 x16..111 (0xAA/0x55)
    addi t0, x0, 656
    addi t4, x0, 16
_r_p5:
    andi t5, t4, 1
    beq  t5, x0, _p5_even
    addi t3, x0, 85
    jal  x0, _p5_store
_p5_even:
    addi t3, x0, -86
_p5_store:
    add  t1, x31, t0
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t4, t4, 1
    addi t2, x0, 112
    blt  t4, t2, _r_p5

    # platform page4 x24..95 (0xE7/0x7E)
    addi t0, x0, 536
    addi t4, x0, 24
_r_p4:
    andi t5, t4, 1
    beq  t5, x0, _p4_even
    addi t3, x0, 126
    jal  x0, _p4_store
_p4_even:
    addi t3, x0, -25
_p4_store:
    add  t1, x31, t0
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t4, t4, 1
    addi t2, x0, 96
    blt  t4, t2, _r_p4

    # platform page3 x32..87 (0xDB/0xBD)
    addi t0, x0, 416
    addi t4, x0, 32
_r_p3:
    andi t5, t4, 1
    beq  t5, x0, _p3_even
    addi t3, x0, -37
    jal  x0, _p3_store
_p3_even:
    addi t3, x0, -67
_p3_store:
    add  t1, x31, t0
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t4, t4, 1
    addi t2, x0, 88
    blt  t4, t2, _r_p3

    # rope page2 x24..103 = 0x18
    addi t0, x0, 280
_r_rope:
    add  t1, x31, t0
    addi t3, x0, 24
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t2, x0, 360
    blt  t0, t2, _r_rope

    # ladders draw pattern [FF,24,7E,24,FF]
    # ladder1 x16 pages3..7
    addi t0, x0, 400
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
    addi t2, x0, 1040
    blt  t0, t2, _r_lad1

    # ladder2 x56 pages3..5
    addi t0, x0, 440
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
    addi t2, x0, 824
    blt  t0, t2, _r_lad2

    # ladder3 x96 pages3..7
    addi t0, x0, 480
_r_lad3:
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
    addi t2, x0, 1120
    blt  t0, t2, _r_lad3

    # coins (single-byte glyph)
    andi t5, x13, 1
    bne  t5, x0, _r_coin1
    addi t0, x0, 680
    add  t1, x31, t0
    addi t3, x0, 60
    sb   t3, 0(t1)
_r_coin1:
    andi t5, x13, 2
    bne  t5, x0, _r_coin2
    addi t0, x0, 584
    add  t1, x31, t0
    addi t3, x0, 60
    sb   t3, 0(t1)
_r_coin2:
    andi t5, x13, 4
    bne  t5, x0, _r_coin3
    addi t0, x0, 480
    add  t1, x31, t0
    addi t3, x0, 60
    sb   t3, 0(t1)
_r_coin3:
    andi t5, x13, 8
    bne  t5, x0, _draw_enemy
    addi t0, x0, 952
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
    jal  x0, _tick_wait

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

    jal  x0, _tick_wait
