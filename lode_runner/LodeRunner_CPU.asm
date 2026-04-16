# Lode Runner lite (map + manual movement, observable speed)
# buttons[3:0] = {RIGHT, LEFT, DOWN, UP}
# IO:
#   0x00008000 buttons
#   0x00009000 redraw/status
#   0x0000A000..0x0000A3FF oled framebuffer
#   0x0000B000 debug leds
# RAM map seed:
#   0x00001000..0x000013FF (lode_runner_map_128x64_mem_init.vh)

start:
    lui s0, 0x8           # buttons
    lui s1, 0x9           # display
    lui s2, 0xA           # oled fb
    lui s3, 0x1           # map seed base
    lui s4, 0xB           # dbg leds

    addi s5, zero, 40     # player x (0..124)
    addi s6, zero, 3      # player page y (0..7)
    addi s8, zero, 0      # movement throttle counter

main_loop:
    # throttle movement so human can observe
    addi s8, s8, 1

    lw t1, 0(s0)          # buttons
    addi t0, zero, 0      # pipeline safety nop
    addi t0, zero, 0      # pipeline safety nop

    # led debug: low nibble = buttons
    andi t6, t1, 15

    # only update position every 256 loops
    andi t0, s8, 255
    bne t0, zero, do_render

    addi t2, zero, 0      # move flags [0]=L [1]=R [2]=U [3]=D

chk_up:
    andi t3, t1, 1
    beq t3, zero, chk_down
    beq s6, zero, chk_down
    addi s6, s6, -1
    addi t4, zero, 4
    or t2, t2, t4

chk_down:
    andi t3, t1, 2
    beq t3, zero, chk_left
    addi t4, zero, 7
    bge s6, t4, chk_left
    addi s6, s6, 1
    addi t4, zero, 8
    or t2, t2, t4

chk_left:
    andi t3, t1, 4
    beq t3, zero, chk_right
    beq s5, zero, chk_right
    addi s5, s5, -1
    addi t4, zero, 1
    or t2, t2, t4

chk_right:
    andi t3, t1, 8
    beq t3, zero, dbg_out
    addi t4, zero, 124
    bge s5, t4, dbg_out
    addi s5, s5, 1
    addi t4, zero, 2
    or t2, t2, t4

dbg_out:
    slli t4, t2, 4
    or t6, t6, t4

    # also show x low nibble on led[11:8]
    andi t5, s5, 15
    slli t5, t5, 8
    or t6, t6, t5

    sw t6, 0(s4)

# render every loop (smooth refresh)
do_render:
    addi s11, ra, 0

    # copy map seed to oled framebuffer
    addi t0, zero, 0
copy_loop:
    add t3, s3, t0
    lbu t4, 0(t3)
    add t5, s2, t0
    sb t4, 0(t5)
    addi t0, t0, 1
    addi t3, zero, 1024
    blt t0, t3, copy_loop

    # draw player as 4x8 solid white block (page-aligned)
    slli t0, s6, 7
    add t0, t0, s5
    add t0, t0, s2

    addi t3, zero, -1
    sb t3, 0(t0)
    sb t3, 1(t0)
    sb t3, 2(t0)
    sb t3, 3(t0)

    # trigger display redraw
    sw zero, 0(s1)

    addi ra, s11, 0
    jalr zero, 0(ra)

    jal zero, main_loop
