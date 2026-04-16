# Lode Runner lite - robust movement core
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
    addi s7, zero, 0      # coin collected flags bit[2:0]
    addi s8, zero, 0      # throttle

main_loop:
    addi s8, s8, 1
    lw t1, 0(s0)          # buttons
    addi t0, zero, 0
    addi t0, zero, 0

    addi t2, zero, 0      # move flags

    # update every 64 loops (slower movement for visibility)
    andi t0, s8, 63
    bne t0, zero, dbg_and_render

    # candidate positions
    addi s9, s5, 0        # nx
    addi s10, s6, 0        # ny

    # ladder_here at current (s5,s6) -> s11
    addi s11, zero, 0

    # ladder1: x [16,22), page [2,7)
    addi t3, zero, 16
    blt s5, t3, ladder2_chk
    addi t4, zero, 22
    bge s5, t4, ladder2_chk
    addi t5, zero, 2
    blt s6, t5, ladder2_chk
    addi t5, zero, 7
    bge s6, t5, ladder2_chk
    addi s11, zero, 1
    jal zero, ladder_chk_done

ladder2_chk:
    # ladder2: x [56,62), page [2,5)
    addi t3, zero, 56
    blt s5, t3, ladder3_chk
    addi t4, zero, 62
    bge s5, t4, ladder3_chk
    addi t5, zero, 2
    blt s6, t5, ladder3_chk
    addi t5, zero, 5
    bge s6, t5, ladder3_chk
    addi s11, zero, 1
    jal zero, ladder_chk_done

ladder3_chk:
    # ladder3: x [96,101), page [5,7)
    addi t3, zero, 96
    blt s5, t3, ladder_chk_done
    addi t4, zero, 101
    bge s5, t4, ladder_chk_done
    addi t5, zero, 5
    blt s6, t5, ladder_chk_done
    addi t5, zero, 7
    bge s6, t5, ladder_chk_done
    addi s11, zero, 1

ladder_chk_done:

    # UP
    andi t3, t1, 1
    beq t3, zero, do_down
    beq s11, zero, do_down
    beq s10, zero, do_down
    addi s10, s10, -1
    addi t4, zero, 4
    or t2, t2, t4

do_down:
    andi t3, t1, 2
    beq t3, zero, do_left
    beq s11, zero, do_left
    addi t4, zero, 7
    bge s10, t4, do_left
    addi s10, s10, 1
    addi t4, zero, 8
    or t2, t2, t4

do_left:
    andi t3, t1, 4
    beq t3, zero, do_right
    beq s9, zero, do_right

    # collision check: candidate rect [nx..nx+3] at current page
    # solid byte = non-zero and not ladder-pass bytes {0x11,0xFF,0x01,0x10}
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
    bge s9, t4, do_gravity

    # collision check: candidate rect [nx..nx+3] where nx=s9+1
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

# gravity: if not on ladder and no support floor under feet, fall by 1 page
do_gravity:
    bne s11, zero, commit_pos
    addi t3, zero, 7
    bge s10, t3, commit_pos

    # support check: any solid byte in rect [x..x+3] at below_page
    addi t4, s10, 1       # below_page
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
    addi t4, zero, 8      # mark as down movement
    or t2, t2, t4
    jal zero, commit_pos

support_done:
    jal zero, commit_pos

support_yes:
    jal zero, support_done

commit_pos:
    addi s5, s9, 0
    addi s6, s10, 0

    # coin collect check (3 coins)
    # coin0 at (26,5) -> bit0
    addi t3, zero, 5
    bne s6, t3, coin1_chk
    addi t4, zero, 24
    blt s5, t4, coin1_chk
    addi t4, zero, 29
    bge s5, t4, coin1_chk
    ori s7, s7, 1

coin1_chk:
    # coin1 at (54,4) -> bit1
    addi t3, zero, 4
    bne s6, t3, coin2_chk
    addi t4, zero, 52
    blt s5, t4, coin2_chk
    addi t4, zero, 57
    bge s5, t4, coin2_chk
    ori s7, s7, 2

coin2_chk:
    # coin2 at (90,2) -> bit2
    addi t3, zero, 2
    bne s6, t3, dbg_and_render
    addi t4, zero, 88
    blt s5, t4, dbg_and_render
    addi t4, zero, 93
    bge s5, t4, dbg_and_render
    ori s7, s7, 4

# dbg_leds[3:0]=buttons, [7:4]=move flags, [11:8]=x low nibble
dbg_and_render:
    andi t6, t1, 15
    slli t4, t2, 4
    or t6, t6, t4
    andi t5, s5, 15
    slli t5, t5, 8
    or t6, t6, t5
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

    # draw coins (if not collected), 1-byte marker per coin
    andi t3, s7, 1
    bne t3, zero, coin_draw_1
    addi t0, zero, 5
    slli t0, t0, 7
    addi t4, zero, 26
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)

coin_draw_1:
    andi t3, s7, 2
    bne t3, zero, coin_draw_2
    addi t0, zero, 4
    slli t0, t0, 7
    addi t4, zero, 54
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)

coin_draw_2:
    andi t3, s7, 4
    bne t3, zero, after_coin_draw
    addi t0, zero, 2
    slli t0, t0, 7
    addi t4, zero, 90
    add t0, t0, t4
    add t0, t0, s2
    addi t4, zero, 60
    sb t4, 0(t0)

after_coin_draw:
    # draw player 4x8 block (top priority over map/coins)
    slli t0, s6, 7
    add t0, t0, s5
    add t0, t0, s2
    addi t3, zero, -1
    sb t3, 0(t0)
    sb t3, 1(t0)
    sb t3, 2(t0)
    sb t3, 3(t0)

    sw zero, 0(s1)
    jal zero, main_loop
