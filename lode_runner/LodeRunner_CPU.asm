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

    # clear 3 spike piles in map seed so they are not treated as walls
    # pile0: page3 x32..35  (0x1000 + 416..419)
    sb zero, 416(s3)
    sb zero, 417(s3)
    sb zero, 418(s3)
    sb zero, 419(s3)
    # pile1: page6 x65..68  (0x1000 + 833..836)
    sb zero, 833(s3)
    sb zero, 834(s3)
    sb zero, 835(s3)
    sb zero, 836(s3)
    # pile2: page3 x102..105 (0x1000 + 486..489)
    sb zero, 486(s3)
    sb zero, 487(s3)
    sb zero, 488(s3)
    sb zero, 489(s3)

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

    # keep previous coin state in t0 for "new pickup" detection
    addi t0, s7, 0

    # coin0 at original left spike pile: center (33,3), bit0
    addi t3, zero, 3
    bne s6, t3, coin1_chk
    addi t4, zero, 31
    blt s5, t4, coin1_chk
    addi t4, zero, 36
    bge s5, t4, coin1_chk
    ori s7, s7, 1

coin1_chk:
    # coin1 at original middle spike pile: center (66,6), bit1
    addi t3, zero, 6
    bne s6, t3, coin2_chk
    addi t4, zero, 64
    blt s5, t4, coin2_chk
    addi t4, zero, 69
    bge s5, t4, coin2_chk
    ori s7, s7, 2

coin2_chk:
    # coin2 at original right spike pile: center (103,3), bit2
    addi t3, zero, 3
    bne s6, t3, coin_anim_chk
    addi t4, zero, 101
    blt s5, t4, coin_anim_chk
    addi t4, zero, 106
    bge s5, t4, coin_anim_chk
    ori s7, s7, 4

coin_anim_chk:
    beq s7, t0, dbg_and_render
    addi a2, zero, 24      # show center "gold coin" for a short time

# dbg_leds[3:0]=buttons, [7:4]=move flags, [11:8]=x low nibble, [15:12]=coin count(0..3)
dbg_and_render:
    andi t6, t1, 15
    slli t4, t2, 4
    or t6, t6, t4
    andi t5, s5, 15
    slli t5, t5, 8
    or t6, t6, t5

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
    addi a1, t3, 0         # save for HUD
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

    # HUD at top-left: coin icon + 3 progress pips
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
    addi t5, zero, 0
    blt t5, a1, hud1
    jal zero, draw_coins
hud1:
    addi t4, zero, 24
    sb t4, 4(t0)
    addi t5, zero, 1
    blt t5, a1, hud2
    jal zero, draw_coins
hud2:
    sb t4, 5(t0)
    addi t5, zero, 2
    blt t5, a1, hud3
    jal zero, draw_coins
hud3:
    sb t4, 6(t0)

draw_coins:
    # draw 3 larger coins (3x8) if not collected
    andi t3, s7, 1
    bne t3, zero, coin_draw_1
    addi t0, zero, 3
    slli t0, t0, 7
    addi t4, zero, 32
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
    addi t0, zero, 6
    slli t0, t0, 7
    addi t4, zero, 65
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
    addi t0, zero, 3
    slli t0, t0, 7
    addi t4, zero, 102
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)
    addi t4, zero, 126
    sb t4, 1(t0)
    addi t4, zero, 60
    sb t4, 2(t0)

center_anim:
    # original-like short center flash after pickup
    beq a2, zero, draw_player
    addi a2, a2, -1
    addi t0, zero, 3
    slli t0, t0, 7
    addi t4, zero, 62
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 24
    sb t4, 0(t0)
    addi t4, zero, 60
    sb t4, 1(t0)
    addi t4, zero, 126
    sb t4, 2(t0)
    addi t4, zero, 60
    sb t4, 3(t0)
    addi t4, zero, 24
    sb t4, 4(t0)

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
