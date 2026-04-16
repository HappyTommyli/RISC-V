# Lode Runner lite - stable gameplay core
# buttons[3:0] = {RIGHT, LEFT, DOWN, UP}
# IO: 0x8000 buttons, 0x9000 redraw, 0xA000 fb, 0xB000 leds

start:
    lui s0, 0x8           # buttons
    lui s1, 0x9           # display
    lui s2, 0xA           # oled fb
    lui s3, 0x1           # map seed @0x1000
    lui s4, 0xB           # dbg leds

    addi s5, zero, 8      # x
    addi s6, zero, 6      # page y
    addi s7, zero, 0      # collected coins bitmask (10 bits)
    addi s8, zero, 0      # throttle / animation counter
    addi a0, zero, 0      # world page: 0=left map, 1=right map

main_loop:
    addi s8, s8, 1
    lw t1, 0(s0)          # buttons
    addi t2, zero, 0      # move flags

    # update every 64 loops (slow enough to observe)
    andi t3, s8, 63
    bne t3, zero, dbg_and_render

    # candidate positions
    addi s9, s5, 0        # nx
    addi s10, s6, 0       # ny

    # ladder_here flag -> s11
    addi s11, zero, 0

    # ladder1: x [16,22), page [2,7)
    addi t3, zero, 16
    blt s5, t3, ladder_here_2
    addi t4, zero, 22
    bge s5, t4, ladder_here_2
    addi t5, zero, 2
    blt s6, t5, ladder_here_2
    addi t5, zero, 7
    bge s6, t5, ladder_here_2
    addi s11, zero, 1
    jal zero, ladder_here_done

ladder_here_2:
    # ladder2: x [56,62), page [2,5)
    addi t3, zero, 56
    blt s5, t3, ladder_here_3
    addi t4, zero, 62
    bge s5, t4, ladder_here_3
    addi t5, zero, 2
    blt s6, t5, ladder_here_3
    addi t5, zero, 5
    bge s6, t5, ladder_here_3
    addi s11, zero, 1
    jal zero, ladder_here_done

ladder_here_3:
    # ladder3: x [96,102), page [1,7)
    addi t3, zero, 96
    blt s5, t3, ladder_here_r
    addi t4, zero, 102
    bge s5, t4, ladder_here_r
    addi t5, zero, 1
    blt s6, t5, ladder_here_r
    addi t5, zero, 7
    bge s6, t5, ladder_here_r
    addi s11, zero, 1
    jal zero, ladder_here_done

ladder_here_r:
    # right-map sky pole: x [112,114), page [1,7)
    beq a0, zero, ladder_here_done
    addi t3, zero, 112
    blt s5, t3, ladder_here_done
    addi t4, zero, 114
    bge s5, t4, ladder_here_done
    addi t5, zero, 1
    blt s6, t5, ladder_here_done
    addi t5, zero, 7
    bge s6, t5, ladder_here_done
    addi s11, zero, 1

ladder_here_done:
    # ladder_below flag -> t0 (used to prevent wrong downward crossing)
    addi t0, zero, 0
    addi t6, s6, 1

    # below on ladder1?
    addi t3, zero, 16
    blt s5, t3, ladder_below_2
    addi t4, zero, 22
    bge s5, t4, ladder_below_2
    addi t5, zero, 2
    blt t6, t5, ladder_below_2
    addi t5, zero, 7
    bge t6, t5, ladder_below_2
    addi t0, zero, 1
    jal zero, ladder_below_done

ladder_below_2:
    # below on ladder2?
    addi t3, zero, 56
    blt s5, t3, ladder_below_3
    addi t4, zero, 62
    bge s5, t4, ladder_below_3
    addi t5, zero, 2
    blt t6, t5, ladder_below_3
    addi t5, zero, 5
    bge t6, t5, ladder_below_3
    addi t0, zero, 1
    jal zero, ladder_below_done

ladder_below_3:
    # below on ladder3?
    addi t3, zero, 96
    blt s5, t3, ladder_below_r
    addi t4, zero, 102
    bge s5, t4, ladder_below_r
    addi t5, zero, 1
    blt t6, t5, ladder_below_r
    addi t5, zero, 7
    bge t6, t5, ladder_below_r
    addi t0, zero, 1
    jal zero, ladder_below_done

ladder_below_r:
    # below on right-map sky pole?
    beq a0, zero, ladder_below_done
    addi t3, zero, 112
    blt s5, t3, ladder_below_done
    addi t4, zero, 114
    bge s5, t4, ladder_below_done
    addi t5, zero, 1
    blt t6, t5, ladder_below_done
    addi t5, zero, 7
    bge t6, t5, ladder_below_done
    addi t0, zero, 1

ladder_below_done:

    # UP
    andi t3, t1, 1
    beq t3, zero, do_down
    beq s11, zero, do_down
    beq s10, zero, do_down
    addi s10, s10, -1
    addi t4, zero, 4
    or t2, t2, t4

# Down only when current and next page are both on ladder.
do_down:
    andi t3, t1, 2
    beq t3, zero, do_left
    beq s11, zero, do_left
    beq t0, zero, do_left
    addi t4, zero, 7
    bge s10, t4, do_left
    addi s10, s10, 1
    addi t4, zero, 8
    or t2, t2, t4

do_left:
    andi t3, t1, 4
    beq t3, zero, do_right
    bne s9, zero, left_try_move
    beq a0, zero, do_right
    addi a0, a0, -1
    addi s9, zero, 124
    addi t4, zero, 1
    or t2, t2, t4
    jal zero, do_right

left_try_move:

    # collision check for candidate x = s9 - 1, width = 4
    addi t4, s9, -1
    slli t5, s10, 7
    add t5, t5, s3

    add t6, t5, t4
    lbu t3, 0(t6)
    beq t3, zero, left_col1
    addi t6, zero, 17
    beq t3, t6, left_col1
    addi t6, zero, 255
    beq t3, t6, left_col1
    addi t6, zero, 1
    beq t3, t6, left_col1
    addi t6, zero, 16
    beq t3, t6, left_col1
    jal zero, do_right

left_col1:
    addi t6, t4, 1
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, left_col2
    addi t6, zero, 17
    beq t3, t6, left_col2
    addi t6, zero, 255
    beq t3, t6, left_col2
    addi t6, zero, 1
    beq t3, t6, left_col2
    addi t6, zero, 16
    beq t3, t6, left_col2
    jal zero, do_right

left_col2:
    addi t6, t4, 2
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, left_col3
    addi t6, zero, 17
    beq t3, t6, left_col3
    addi t6, zero, 255
    beq t3, t6, left_col3
    addi t6, zero, 1
    beq t3, t6, left_col3
    addi t6, zero, 16
    beq t3, t6, left_col3
    jal zero, do_right

left_col3:
    addi t6, t4, 3
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, left_apply
    addi t6, zero, 17
    beq t3, t6, left_apply
    addi t6, zero, 255
    beq t3, t6, left_apply
    addi t6, zero, 1
    beq t3, t6, left_apply
    addi t6, zero, 16
    beq t3, t6, left_apply
    jal zero, do_right

left_apply:
    addi s9, s9, -1
    addi t4, zero, 1
    or t2, t2, t4

do_right:
    andi t3, t1, 8
    beq t3, zero, do_gravity
    addi t4, zero, 124
    blt s9, t4, right_try_move
    bne a0, zero, do_gravity
    addi a0, zero, 1
    addi s9, zero, 0
    addi t4, zero, 2
    or t2, t2, t4
    jal zero, do_gravity

right_try_move:

    # collision check for candidate x = s9 + 1, width = 4
    addi t4, s9, 1
    slli t5, s10, 7
    add t5, t5, s3

    add t6, t5, t4
    lbu t3, 0(t6)
    beq t3, zero, right_col1
    addi t6, zero, 17
    beq t3, t6, right_col1
    addi t6, zero, 255
    beq t3, t6, right_col1
    addi t6, zero, 1
    beq t3, t6, right_col1
    addi t6, zero, 16
    beq t3, t6, right_col1
    jal zero, do_gravity

right_col1:
    addi t6, t4, 1
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, right_col2
    addi t6, zero, 17
    beq t3, t6, right_col2
    addi t6, zero, 255
    beq t3, t6, right_col2
    addi t6, zero, 1
    beq t3, t6, right_col2
    addi t6, zero, 16
    beq t3, t6, right_col2
    jal zero, do_gravity

right_col2:
    addi t6, t4, 2
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, right_col3
    addi t6, zero, 17
    beq t3, t6, right_col3
    addi t6, zero, 255
    beq t3, t6, right_col3
    addi t6, zero, 1
    beq t3, t6, right_col3
    addi t6, zero, 16
    beq t3, t6, right_col3
    jal zero, do_gravity

right_col3:
    addi t6, t4, 3
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, right_apply
    addi t6, zero, 17
    beq t3, t6, right_apply
    addi t6, zero, 255
    beq t3, t6, right_apply
    addi t6, zero, 1
    beq t3, t6, right_apply
    addi t6, zero, 16
    beq t3, t6, right_apply
    jal zero, do_gravity

right_apply:
    addi s9, s9, 1
    addi t4, zero, 2
    or t2, t2, t4

# gravity: if not on ladder and no support below, fall 1 page
do_gravity:
    # hold at ladder bottom: pressing DOWN at last ladder rung should not drop through
    andi t3, t1, 2
    beq t3, zero, gravity_normal
    beq s11, zero, gravity_normal
    bne t0, zero, gravity_normal
    jal zero, commit_pos

gravity_normal:
    bne s11, zero, commit_pos
    addi t3, zero, 7
    bge s10, t3, commit_pos

    # support check at below_page on candidate x [s9..s9+3]
    addi t4, s10, 1
    slli t5, t4, 7
    add t5, t5, s3

    add t6, t5, s9
    lbu t3, 0(t6)
    beq t3, zero, support_col1
    addi t6, zero, 17
    beq t3, t6, support_col1
    addi t6, zero, 255
    beq t3, t6, support_col1
    addi t6, zero, 1
    beq t3, t6, support_col1
    addi t6, zero, 16
    beq t3, t6, support_col1
    jal zero, support_yes

support_col1:
    addi t6, s9, 1
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, support_col2
    addi t6, zero, 17
    beq t3, t6, support_col2
    addi t6, zero, 255
    beq t3, t6, support_col2
    addi t6, zero, 1
    beq t3, t6, support_col2
    addi t6, zero, 16
    beq t3, t6, support_col2
    jal zero, support_yes

support_col2:
    addi t6, s9, 2
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, support_col3
    addi t6, zero, 17
    beq t3, t6, support_col3
    addi t6, zero, 255
    beq t3, t6, support_col3
    addi t6, zero, 1
    beq t3, t6, support_col3
    addi t6, zero, 16
    beq t3, t6, support_col3
    jal zero, support_yes

support_col3:
    addi t6, s9, 3
    add t6, t5, t6
    lbu t3, 0(t6)
    beq t3, zero, support_no
    addi t6, zero, 17
    beq t3, t6, support_no
    addi t6, zero, 255
    beq t3, t6, support_no
    addi t6, zero, 1
    beq t3, t6, support_no
    addi t6, zero, 16
    beq t3, t6, support_no
    jal zero, support_yes

support_no:
    addi s10, s10, 1
    addi t4, zero, 8
    or t2, t2, t4
    jal zero, commit_pos

support_yes:
    jal zero, commit_pos

commit_pos:
    addi s5, s9, 0
    addi s6, s10, 0

    beq a0, zero, coin_l0_chk
    jal zero, coin_r0_chk

# left map coins (bits 0..5), widened pickup window
coin_l0_chk:
    # coin0 center (30,4) -> bit0
    addi t3, zero, 4
    bne s6, t3, coin_l1_chk
    addi t4, zero, 27
    blt s5, t4, coin_l1_chk
    addi t4, zero, 35
    bge s5, t4, coin_l1_chk
    ori s7, s7, 1

coin_l1_chk:
    # coin1 center (54,3) -> bit1
    addi t3, zero, 3
    bne s6, t3, coin_l2_chk
    addi t4, zero, 51
    blt s5, t4, coin_l2_chk
    addi t4, zero, 59
    bge s5, t4, coin_l2_chk
    ori s7, s7, 2

coin_l2_chk:
    # coin2 center (74,3) -> bit2
    addi t3, zero, 3
    bne s6, t3, coin_l3_chk
    addi t4, zero, 71
    blt s5, t4, coin_l3_chk
    addi t4, zero, 79
    bge s5, t4, coin_l3_chk
    ori s7, s7, 4

coin_l3_chk:
    # coin3 center (90,2) -> bit3
    addi t3, zero, 2
    bne s6, t3, coin_l4_chk
    addi t4, zero, 87
    blt s5, t4, coin_l4_chk
    addi t4, zero, 95
    bge s5, t4, coin_l4_chk
    ori s7, s7, 8

coin_l4_chk:
    # coin4 center (23,5) -> bit4
    addi t3, zero, 5
    bne s6, t3, coin_l5_chk
    addi t4, zero, 20
    blt s5, t4, coin_l5_chk
    addi t4, zero, 28
    bge s5, t4, coin_l5_chk
    ori s7, s7, 16

coin_l5_chk:
    # coin5 center (102,5) -> bit5
    addi t3, zero, 5
    bne s6, t3, dbg_and_render
    addi t4, zero, 99
    blt s5, t4, dbg_and_render
    addi t4, zero, 107
    bge s5, t4, dbg_and_render
    ori s7, s7, 32
    jal zero, dbg_and_render

# right map coins (bits 6..9)
coin_r0_chk:
    # coin6 center (18,6) -> bit6
    addi t3, zero, 6
    bne s6, t3, coin_r1_chk
    addi t4, zero, 15
    blt s5, t4, coin_r1_chk
    addi t4, zero, 23
    bge s5, t4, coin_r1_chk
    ori s7, s7, 64

coin_r1_chk:
    # coin7 center (46,2) -> bit7
    addi t3, zero, 2
    bne s6, t3, coin_r2_chk
    addi t4, zero, 43
    blt s5, t4, coin_r2_chk
    addi t4, zero, 51
    bge s5, t4, coin_r2_chk
    ori s7, s7, 128

coin_r2_chk:
    # coin8 center (74,4) -> bit8
    addi t3, zero, 4
    bne s6, t3, coin_r3_chk
    addi t4, zero, 71
    blt s5, t4, coin_r3_chk
    addi t4, zero, 79
    bge s5, t4, coin_r3_chk
    ori s7, s7, 256

coin_r3_chk:
    # coin9 center (110,1) -> bit9
    addi t3, zero, 1
    bne s6, t3, dbg_and_render
    addi t4, zero, 107
    blt s5, t4, dbg_and_render
    addi t4, zero, 115
    bge s5, t4, dbg_and_render
    ori s7, s7, 512

# dbg_leds[3:0]=buttons, [7:4]=move flags, [11:8]=x low nibble, [15:12]=coin count(0..10)
dbg_and_render:
    andi t6, t1, 15
    slli t4, t2, 4
    or t6, t6, t4
    andi t5, s5, 15
    slli t5, t5, 8
    or t6, t6, t5

    # popcount10(s7) -> t3
    addi t3, zero, 0
    andi t4, s7, 1
    beq t4, zero, cnt_b1
    addi t3, t3, 1
cnt_b1:
    andi t4, s7, 2
    beq t4, zero, cnt_b2
    addi t3, t3, 1
cnt_b2:
    andi t4, s7, 4
    beq t4, zero, cnt_b3
    addi t3, t3, 1
cnt_b3:
    andi t4, s7, 8
    beq t4, zero, cnt_b4
    addi t3, t3, 1
cnt_b4:
    andi t4, s7, 16
    beq t4, zero, cnt_b5
    addi t3, t3, 1
cnt_b5:
    andi t4, s7, 32
    beq t4, zero, cnt_b6
    addi t3, t3, 1
cnt_b6:
    andi t4, s7, 64
    beq t4, zero, cnt_b7
    addi t3, t3, 1
cnt_b7:
    andi t4, s7, 128
    beq t4, zero, cnt_b8
    addi t3, t3, 1
cnt_b8:
    andi t4, s7, 256
    beq t4, zero, cnt_b9
    addi t3, t3, 1
cnt_b9:
    andi t4, s7, 512
    beq t4, zero, cnt_done
    addi t3, t3, 1
cnt_done:
    addi a1, t3, 0
    slli t3, t3, 12
    or t6, t6, t3

    sw t6, 0(s4)

    # copy map seed to framebuffer
    addi t0, zero, 0
copy_loop:
    add t3, s3, t0
    lbu t4, 0(t3)
    add t5, s2, t0
    sb t4, 0(t5)
    addi t0, t0, 1
    addi t3, zero, 1024
    blt t0, t3, copy_loop

    # HUD at top-left: coin icon + 10-step progress bar
    addi t0, zero, 0
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

    addi t4, zero, 0
    sb t4, 4(t0)
    sb t4, 5(t0)
    sb t4, 6(t0)
    sb t4, 7(t0)
    sb t4, 8(t0)
    sb t4, 9(t0)
    sb t4, 10(t0)
    sb t4, 11(t0)
    sb t4, 12(t0)
    sb t4, 13(t0)

    addi t5, zero, 0
    blt t5, a1, hud_1
    jal zero, hud_done
hud_1:
    addi t4, zero, 24
    sb t4, 4(t0)
    addi t5, zero, 1
    blt t5, a1, hud_2
    jal zero, hud_done
hud_2:
    sb t4, 5(t0)
    addi t5, zero, 2
    blt t5, a1, hud_3
    jal zero, hud_done
hud_3:
    sb t4, 6(t0)
    addi t5, zero, 3
    blt t5, a1, hud_4
    jal zero, hud_done
hud_4:
    sb t4, 7(t0)
    addi t5, zero, 4
    blt t5, a1, hud_5
    jal zero, hud_done
hud_5:
    sb t4, 8(t0)
    addi t5, zero, 5
    blt t5, a1, hud_6
    jal zero, hud_done
hud_6:
    sb t4, 9(t0)
    addi t5, zero, 6
    blt t5, a1, hud_7
    jal zero, hud_done
hud_7:
    sb t4, 10(t0)
    addi t5, zero, 7
    blt t5, a1, hud_8
    jal zero, hud_done
hud_8:
    sb t4, 11(t0)
    addi t5, zero, 8
    blt t5, a1, hud_9
    jal zero, hud_done
hud_9:
    sb t4, 12(t0)
    addi t5, zero, 9
    blt t5, a1, hud_10
    jal zero, hud_done
hud_10:
    sb t4, 13(t0)

hud_done:
    # page indicator: right map mark near top-right
    beq a0, zero, draw_coins_dispatch
    addi t0, zero, 127
    add t0, t0, s2
    addi t4, zero, 24
    sb t4, 0(t0)

    # right-map sky pole visual at x=112..113, pages 1..6
    addi t4, zero, 17
    addi t0, zero, 112
    add t0, t0, s2
    sb t4, 128(t0)
    sb t4, 129(t0)
    sb t4, 256(t0)
    sb t4, 257(t0)
    sb t4, 384(t0)
    sb t4, 385(t0)
    sb t4, 512(t0)
    sb t4, 513(t0)
    sb t4, 640(t0)
    sb t4, 641(t0)
    sb t4, 768(t0)
    sb t4, 769(t0)

draw_coins_dispatch:
    beq a0, zero, draw_coins_left
    jal zero, draw_coins_right

draw_coins_left:
    # draw larger coins 3x8 (0x3C,0x7E,0x3C)
    andi t3, s7, 1
    bne t3, zero, coin_l_draw_1
    addi t0, zero, 4
    slli t0, t0, 7
    addi t4, zero, 29
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_l_draw_1:
    andi t3, s7, 2
    bne t3, zero, coin_l_draw_2
    addi t0, zero, 3
    slli t0, t0, 7
    addi t4, zero, 53
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_l_draw_2:
    andi t3, s7, 4
    bne t3, zero, coin_l_draw_3
    addi t0, zero, 3
    slli t0, t0, 7
    addi t4, zero, 73
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_l_draw_3:
    andi t3, s7, 8
    bne t3, zero, coin_l_draw_4
    addi t0, zero, 2
    slli t0, t0, 7
    addi t4, zero, 89
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_l_draw_4:
    andi t3, s7, 16
    bne t3, zero, coin_l_draw_5
    addi t0, zero, 5
    slli t0, t0, 7
    addi t4, zero, 22
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_l_draw_5:
    andi t3, s7, 32
    bne t3, zero, after_coin_draw
    addi t0, zero, 5
    slli t0, t0, 7
    addi t4, zero, 101
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)
    jal zero, after_coin_draw

draw_coins_right:
    andi t3, s7, 64
    bne t3, zero, coin_r_draw_1
    addi t0, zero, 6
    slli t0, t0, 7
    addi t4, zero, 17
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_r_draw_1:
    andi t3, s7, 128
    bne t3, zero, coin_r_draw_2
    addi t0, zero, 2
    slli t0, t0, 7
    addi t4, zero, 45
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_r_draw_2:
    andi t3, s7, 256
    bne t3, zero, coin_r_draw_3
    addi t0, zero, 4
    slli t0, t0, 7
    addi t4, zero, 73
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_r_draw_3:
    andi t3, s7, 512
    bne t3, zero, after_coin_draw
    addi t0, zero, 1
    slli t0, t0, 7
    addi t4, zero, 109
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

after_coin_draw:
    # draw player sprite 4x8, closer to original lode-runner style
    slli t0, s6, 7
    add t0, t0, s5
    add t0, t0, s2

    addi t3, zero, 24      # 0x18 head/hat
    sb t3, 0(t0)
    addi t3, zero, 60      # 0x3C torso
    sb t3, 1(t0)
    addi t3, zero, 102     # 0x66 arms
    sb t3, 2(t0)

    andi t3, s8, 32
    beq t3, zero, player_leg_a
    addi t3, zero, 66      # 0x42 legs frame B
    sb t3, 3(t0)
    jal zero, player_done

player_leg_a:
    addi t3, zero, 36      # 0x24 legs frame A
    sb t3, 3(t0)

player_done:
    # draw WIN bar when all 10 coins collected
    addi t3, zero, 1023
    bne s7, t3, render_commit
    addi t0, zero, 0
    add t0, t0, s2
    addi t4, zero, 126
    sb t4, 0(t0)
    sb t4, 1(t0)
    sb t4, 2(t0)
    sb t4, 3(t0)

render_commit:
    sw zero, 0(s1)
    jal zero, main_loop
