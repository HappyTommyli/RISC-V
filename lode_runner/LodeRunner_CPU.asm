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
    addi s8, zero, 0      # throttle

main_loop:
    addi s8, s8, 1
    lw t1, 0(s0)          # buttons
    addi t0, zero, 0
    addi t0, zero, 0

    addi t2, zero, 0      # move flags

    # update every 16 loops
    andi t0, s8, 15
    bne t0, zero, dbg_and_render

    # candidate positions
    addi s9, s5, 0        # nx
    addi s10, s6, 0        # ny

    # ladder_here at current (s5,s6) -> s11
    addi s11, zero, 0

    # ladder1: x [24,28), page [5,8)
    addi t3, zero, 24
    blt s5, t3, ladder2_chk
    addi t4, zero, 28
    bge s5, t4, ladder2_chk
    addi t5, zero, 5
    blt s6, t5, ladder2_chk
    addi s11, zero, 1
    jal zero, ladder_chk_done

ladder2_chk:
    # ladder2: x [52,56), page [3,6)
    addi t3, zero, 52
    blt s5, t3, ladder3_chk
    addi t4, zero, 56
    bge s5, t4, ladder3_chk
    addi t5, zero, 3
    blt s6, t5, ladder3_chk
    addi t5, zero, 6
    bge s6, t5, ladder3_chk
    addi s11, zero, 1
    jal zero, ladder_chk_done

ladder3_chk:
    # ladder3: x [88,92), page [1,4)
    addi t3, zero, 88
    blt s5, t3, ladder_chk_done
    addi t4, zero, 92
    bge s5, t4, ladder_chk_done
    addi t5, zero, 1
    blt s6, t5, ladder_chk_done
    addi t5, zero, 4
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

left_apply:
    addi s9, s9, -1
    addi t4, zero, 1
    or t2, t2, t4

do_right:
    andi t3, t1, 8
    beq t3, zero, commit_pos
    addi t4, zero, 124
    bge s9, t4, commit_pos

right_apply:
    addi s9, s9, 1
    addi t4, zero, 2
    or t2, t2, t4

commit_pos:
    addi s5, s9, 0
    addi s6, s10, 0

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
