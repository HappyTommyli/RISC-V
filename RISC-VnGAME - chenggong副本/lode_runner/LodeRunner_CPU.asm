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
    addi s7, zero, 0      # collected coins bitmask (3 bits)
    addi s8, zero, 0      # throttle / animation counter
    addi a0, zero, 0      # world page: 0=left map, 1=right map
    addi a2, zero, 0      # center gold animation timer

main_loop:
    addi s8, s8, 1
    lw t1, 0(s0)          # buttons
    addi t2, zero, 0      # move flags

    # update every 32 loops (smoother response)
    andi t3, s8, 31
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
    blt s5, t3, ladder_here_4
    addi t4, zero, 102
    bge s5, t4, ladder_here_4
    addi t5, zero, 1
    blt s6, t5, ladder_here_4
    addi t5, zero, 7
    bge s6, t5, ladder_here_4
    addi s11, zero, 1
    jal zero, ladder_here_done

ladder_here_4:
    # ladder4: x [64,66), page [5,7)
    addi t3, zero, 64
    blt s5, t3, ladder_here_r
    addi t4, zero, 66
    bge s5, t4, ladder_here_r
    addi t5, zero, 5
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
    blt s5, t3, ladder_below_4
    addi t4, zero, 102
    bge s5, t4, ladder_below_4
    addi t5, zero, 1
    blt t6, t5, ladder_below_4
    addi t5, zero, 7
    bge t6, t5, ladder_below_4
    addi t0, zero, 1
    jal zero, ladder_below_done

ladder_below_4:
    # below on ladder4?
    addi t3, zero, 64
    blt s5, t3, ladder_below_r
    addi t4, zero, 66
    bge s5, t4, ladder_below_r
    addi t5, zero, 5
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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
    addi t6, zero, 2
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

    # keep previous coin state in t0 for "new pickup" detection
    addi t0, s7, 0

    # coin0 reachable: center (24,4), bit0
    addi t3, zero, 4
    bne s6, t3, coin1_chk
    addi t4, zero, 22
    blt s5, t4, coin1_chk
    addi t4, zero, 27
    bge s5, t4, coin1_chk
    ori s7, s7, 1

coin1_chk:
    # coin1 reachable: center (54,4), bit1
    addi t3, zero, 4
    bne s6, t3, coin2_chk
    addi t4, zero, 52
    blt s5, t4, coin2_chk
    addi t4, zero, 57
    bge s5, t4, coin2_chk
    ori s7, s7, 2

coin2_chk:
    # coin2 reachable: center (98,5), bit2
    addi t3, zero, 5
    bne s6, t3, coin_anim_chk
    addi t4, zero, 96
    blt s5, t4, coin_anim_chk
    addi t4, zero, 101
    bge s5, t4, coin_anim_chk
    ori s7, s7, 4

coin_anim_chk:
    beq s7, t0, dbg_and_render
    addi a2, zero, 180     # show center "GOLD COIN" for about 3 seconds

# dbg_leds coin lamps: pick N coins => low N LEDs on
dbg_and_render:
    # popcount3(s7) -> t3
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
    beq t4, zero, cnt_done
    addi t3, t3, 1
cnt_done:
    # LED lamps: 0->0b000, 1->0b001, 2->0b011, 3->0b111
    addi t6, zero, 0
    beq t3, zero, led_done
    addi t4, zero, 1
    beq t3, t4, led_1
    addi t4, zero, 2
    beq t3, t4, led_2
    addi t6, zero, 7
    jal zero, led_done
led_1:
    addi t6, zero, 1
    jal zero, led_done
led_2:
    addi t6, zero, 3
led_done:
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

    # right-map sky pole visual (visible + climbable)
    beq a0, zero, draw_coins
    addi t4, zero, 17
    addi t5, zero, 112
    add t5, t5, s2
    sb t4, 128(t5)
    sb t4, 129(t5)
    sb t4, 256(t5)
    sb t4, 257(t5)
    sb t4, 384(t5)
    sb t4, 385(t5)
    sb t4, 512(t5)
    sb t4, 513(t5)
    sb t4, 640(t5)
    sb t4, 641(t5)
    sb t4, 768(t5)
    sb t4, 769(t5)

draw_coins:
    # draw 3 larger coins (3x8) if not collected
    andi t3, s7, 1
    bne t3, zero, coin_draw_1
    addi t0, zero, 4
    slli t0, t0, 7
    addi t4, zero, 23
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

coin_draw_1:
    andi t3, s7, 2
    bne t3, zero, coin_draw_2
    addi t0, zero, 4
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

coin_draw_2:
    andi t3, s7, 4
    bne t3, zero, center_anim
    addi t0, zero, 5
    slli t0, t0, 7
    addi t4, zero, 97
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

center_anim:
    # if all 3 coins collected -> only show WIN panel (no GOLD COIN)
    addi t3, zero, 7
    beq s7, t3, win_panel

    # GOLD COIN center overlay on top layer
    beq a2, zero, draw_player
    andi t3, s8, 15
    bne t3, zero, gold_panel
    addi a2, a2, -1

gold_panel:
    # draw white border + black panel body on page3, x [24..103]
    addi t0, zero, 24
gold_panel_loop:
    add t5, s2, t0
    addi t4, zero, 24
    beq t0, t4, gold_panel_edge
    addi t4, zero, 103
    beq t0, t4, gold_panel_edge
    addi t4, zero, 129
    sb t4, 384(t5)
    jal zero, gold_panel_next
gold_panel_edge:
    addi t4, zero, 255
    sb t4, 384(t5)
gold_panel_next:
    addi t0, t0, 1
    addi t3, zero, 104
    blt t0, t3, gold_panel_loop

    # draw text "GOLD COIN" (5x7 font columns) at page3
    addi t0, zero, 37
    add t0, t0, s2
    addi t0, t0, 384

    # G
    addi t4, zero, 62
    sb t4, 0(t0)
    addi t4, zero, 65
    sb t4, 1(t0)
    addi t4, zero, 73
    sb t4, 2(t0)
    addi t4, zero, 77
    sb t4, 3(t0)
    addi t4, zero, 46
    sb t4, 4(t0)
    # O
    addi t4, zero, 62
    sb t4, 6(t0)
    addi t4, zero, 65
    sb t4, 7(t0)
    addi t4, zero, 65
    sb t4, 8(t0)
    addi t4, zero, 65
    sb t4, 9(t0)
    addi t4, zero, 62
    sb t4, 10(t0)
    # L
    addi t4, zero, 127
    sb t4, 12(t0)
    addi t4, zero, 1
    sb t4, 13(t0)
    addi t4, zero, 1
    sb t4, 14(t0)
    addi t4, zero, 1
    sb t4, 15(t0)
    addi t4, zero, 1
    sb t4, 16(t0)
    # D
    addi t4, zero, 127
    sb t4, 18(t0)
    addi t4, zero, 65
    sb t4, 19(t0)
    addi t4, zero, 65
    sb t4, 20(t0)
    addi t4, zero, 34
    sb t4, 21(t0)
    addi t4, zero, 28
    sb t4, 22(t0)
    # C
    addi t4, zero, 62
    sb t4, 30(t0)
    addi t4, zero, 65
    sb t4, 31(t0)
    addi t4, zero, 65
    sb t4, 32(t0)
    addi t4, zero, 65
    sb t4, 33(t0)
    addi t4, zero, 34
    sb t4, 34(t0)
    # O
    addi t4, zero, 62
    sb t4, 36(t0)
    addi t4, zero, 65
    sb t4, 37(t0)
    addi t4, zero, 65
    sb t4, 38(t0)
    addi t4, zero, 65
    sb t4, 39(t0)
    addi t4, zero, 62
    sb t4, 40(t0)
    # I
    addi t4, zero, 65
    sb t4, 42(t0)
    addi t4, zero, 65
    sb t4, 43(t0)
    addi t4, zero, 127
    sb t4, 44(t0)
    addi t4, zero, 65
    sb t4, 45(t0)
    addi t4, zero, 65
    sb t4, 46(t0)
    # N
    addi t4, zero, 127
    sb t4, 48(t0)
    addi t4, zero, 32
    sb t4, 49(t0)
    addi t4, zero, 16
    sb t4, 50(t0)
    addi t4, zero, 8
    sb t4, 51(t0)
    addi t4, zero, 127
    sb t4, 52(t0)

    jal zero, draw_player

win_panel:
    # draw same style panel and "WIN" text on top layer
    addi t0, zero, 24
win_panel_loop:
    add t5, s2, t0
    addi t4, zero, 24
    beq t0, t4, win_panel_edge
    addi t4, zero, 103
    beq t0, t4, win_panel_edge
    addi t4, zero, 129
    sb t4, 384(t5)
    jal zero, win_panel_next
win_panel_edge:
    addi t4, zero, 255
    sb t4, 384(t5)
win_panel_next:
    addi t0, t0, 1
    addi t3, zero, 104
    blt t0, t3, win_panel_loop

    # "WIN" centered in panel
    addi t0, zero, 55
    add t0, t0, s2
    addi t0, t0, 384
    # W
    addi t4, zero, 127
    sb t4, 0(t0)
    addi t4, zero, 2
    sb t4, 1(t0)
    addi t4, zero, 12
    sb t4, 2(t0)
    addi t4, zero, 2
    sb t4, 3(t0)
    addi t4, zero, 127
    sb t4, 4(t0)
    # I
    addi t4, zero, 65
    sb t4, 6(t0)
    addi t4, zero, 65
    sb t4, 7(t0)
    addi t4, zero, 127
    sb t4, 8(t0)
    addi t4, zero, 65
    sb t4, 9(t0)
    addi t4, zero, 65
    sb t4, 10(t0)
    # N
    addi t4, zero, 127
    sb t4, 12(t0)
    addi t4, zero, 32
    sb t4, 13(t0)
    addi t4, zero, 16
    sb t4, 14(t0)
    addi t4, zero, 8
    sb t4, 15(t0)
    addi t4, zero, 127
    sb t4, 16(t0)

draw_player:
    # draw player sprite 4x8
    slli t0, s6, 7
    add t0, t0, s5
    add t0, t0, s2
    addi t3, zero, 24
    sb t3, 0(t0)
    addi t3, zero, 60
    sb t3, 1(t0)
    addi t3, zero, 102
    sb t3, 2(t0)
    andi t3, s8, 32
    beq t3, zero, player_leg_a
    addi t3, zero, 66
    sb t3, 3(t0)
    jal zero, win_check
player_leg_a:
    addi t3, zero, 36
    sb t3, 3(t0)

win_check:
    # all 3 coins: small win mark
    addi t3, zero, 7
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

