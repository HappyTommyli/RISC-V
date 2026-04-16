# Lode Runner lite - no-subroutine stable core
# buttons[3:0] = {RIGHT, LEFT, DOWN, UP}
# IO: 0x8000 buttons, 0x9000 redraw, 0xA000 fb, 0xB000 leds

start:
    lui s0, 0x8           # buttons
    lui s1, 0x9           # display
    lui s2, 0xA           # oled fb
    lui s3, 0x1           # map seed @0x1000
    lui s4, 0xB           # dbg leds

    addi s5, zero, 8      # player x (0..124)
    addi s6, zero, 6      # player page y (0..7)
    addi s8, zero, 0      # throttle counter

main_loop:
    addi s8, s8, 1

    lw t1, 0(s0)          # buttons
    addi t0, zero, 0      # load-use padding
    addi t0, zero, 0

    addi t2, zero, 0      # move flags [0]=L [1]=R [2]=U [3]=D

    # update every 8 loops
    andi t0, s8, 7
    bne t0, zero, dbg_and_render

    # ladder_here in s9
    addi s9, zero, 0

    # ladder1: x [24,28), page [5,8)
    addi t3, zero, 24
    blt s5, t3, ladder2
    addi t4, zero, 28
    bge s5, t4, ladder2
    addi t5, zero, 5
    blt s6, t5, ladder2
    addi s9, zero, 1
    jal zero, ladder_done

ladder2:
    # ladder2: x [52,56), page [3,6)
    addi t3, zero, 52
    blt s5, t3, ladder3
    addi t4, zero, 56
    bge s5, t4, ladder3
    addi t5, zero, 3
    blt s6, t5, ladder3
    addi t5, zero, 6
    bge s6, t5, ladder3
    addi s9, zero, 1
    jal zero, ladder_done

ladder3:
    # ladder3: x [88,92), page [1,4)
    addi t3, zero, 88
    blt s5, t3, ladder_done
    addi t4, zero, 92
    bge s5, t4, ladder_done
    addi t5, zero, 1
    blt s6, t5, ladder_done
    addi t5, zero, 4
    bge s6, t5, ladder_done
    addi s9, zero, 1

ladder_done:

chk_up:
    andi t3, t1, 1
    beq t3, zero, chk_down
    beq s9, zero, chk_down
    beq s6, zero, chk_down
    addi s6, s6, -1
    addi t4, zero, 4
    or t2, t2, t4

chk_down:
    andi t3, t1, 2
    beq t3, zero, chk_left
    beq s9, zero, chk_left
    addi t4, zero, 7
    bge s6, t4, chk_left
    addi s6, s6, 1
    addi t4, zero, 8
    or t2, t2, t4

chk_left:
    andi t3, t1, 4
    beq t3, zero, chk_right
    beq s5, zero, chk_right

    addi t0, s5, -1       # candidate x
    addi t6, zero, 0      # blocked flag

    # wall1: x [30,34), page >=2
    addi t4, zero, 2
    blt s6, t4, w1_done_l
    addi t4, zero, 30
    blt t0, t4, w1_done_l
    addi t4, zero, 34
    blt t0, t4, set_block_l
w1_done_l:
    # wall2: x [62,66), page >=3
    addi t4, zero, 3
    blt s6, t4, w2_done_l
    addi t4, zero, 62
    blt t0, t4, w2_done_l
    addi t4, zero, 66
    blt t0, t4, set_block_l
w2_done_l:
    # wall3: x [96,100), page >=1
    addi t4, zero, 1
    blt s6, t4, w3_done_l
    addi t4, zero, 96
    blt t0, t4, w3_done_l
    addi t4, zero, 100
    blt t0, t4, set_block_l
w3_done_l:
    beq t6, zero, do_left
    jal zero, chk_right
set_block_l:
    addi t6, zero, 1
    jal zero, w2_done_l

do_left:
    addi s5, s5, -1
    addi t4, zero, 1
    or t2, t2, t4

chk_right:
    andi t3, t1, 8
    beq t3, zero, dbg_and_render
    addi t4, zero, 124
    bge s5, t4, dbg_and_render

    addi t0, s5, 1        # candidate x
    addi t6, zero, 0      # blocked flag

    # wall1
    addi t4, zero, 2
    blt s6, t4, w1_done_r
    addi t4, zero, 30
    blt t0, t4, w1_done_r
    addi t4, zero, 34
    blt t0, t4, set_block_r
w1_done_r:
    # wall2
    addi t4, zero, 3
    blt s6, t4, w2_done_r
    addi t4, zero, 62
    blt t0, t4, w2_done_r
    addi t4, zero, 66
    blt t0, t4, set_block_r
w2_done_r:
    # wall3
    addi t4, zero, 1
    blt s6, t4, w3_done_r
    addi t4, zero, 96
    blt t0, t4, w3_done_r
    addi t4, zero, 100
    blt t0, t4, set_block_r
w3_done_r:
    beq t6, zero, do_right
    jal zero, dbg_and_render
set_block_r:
    addi t6, zero, 1
    jal zero, w2_done_r

do_right:
    addi s5, s5, 1
    addi t4, zero, 2
    or t2, t2, t4

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

    # draw player 4x8 block
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
