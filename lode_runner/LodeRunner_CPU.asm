# Lode Runner lite minimal (128x64)
# Goal: guaranteed movement first.
# buttons[3:0] = {RIGHT, LEFT, DOWN, UP}
# IO:
#   0x00008000 buttons
#   0x00009000 display busy/read, redraw trigger/write
#   0x0000A000..0x0000A3FF OLED framebuffer (1024 bytes)
# RAM:
#   0x00000000 player_x
#   0x00000004 player_y
#   0x00000008 prev_x
#   0x0000000C prev_y
#   0x00001000..0x000013FF map framebuffer seed

start:
    lui s0, 0x8           # buttons
    lui s1, 0x9           # display
    lui s2, 0xA           # oled fb
    lui s3, 0x1           # map base (0x1000)

    addi t0, zero, 8
    sw t0, 0(zero)        # x
    sw t0, 8(zero)        # prev_x
    addi t0, zero, 40
    sw t0, 4(zero)        # y
    sw t0, 12(zero)       # prev_y

    jal ra, copy_map_to_oled

    lw a0, 0(zero)
    lw a1, 4(zero)
    jal ra, plot_toggle_2x2
    sw zero, 0(s1)

main_loop:
    lw t0, 0(s0)          # buttons

    # erase old sprite (toggle old position)
    lw a0, 8(zero)
    lw a1, 12(zero)
    jal ra, plot_toggle_2x2

    lw t2, 0(zero)        # x
    lw t3, 4(zero)        # y

check_up:
    andi t1, t0, 1
    beq t1, zero, check_down
    beq t3, zero, check_down
    addi t3, t3, -1

check_down:
    andi t1, t0, 2
    beq t1, zero, check_left
    addi t4, zero, 62
    bge t3, t4, check_left
    addi t3, t3, 1

check_left:
    andi t1, t0, 4
    beq t1, zero, check_right
    beq t2, zero, check_right
    addi t2, t2, -1

check_right:
    andi t1, t0, 8
    beq t1, zero, save_pos
    addi t4, zero, 126
    bge t2, t4, save_pos
    addi t2, t2, 1

save_pos:
    sw t2, 0(zero)
    sw t3, 4(zero)
    sw t2, 8(zero)
    sw t3, 12(zero)

    addi a0, t2, 0
    addi a1, t3, 0
    jal ra, plot_toggle_2x2

    # trigger one full refresh
    sw zero, 0(s1)

    # simple frame delay
    addi t5, zero, 6
frame_delay_outer:
    addi t6, zero, 2000
frame_delay_inner:
    addi t6, t6, -1
    bne t6, zero, frame_delay_inner
    addi t5, t5, -1
    bne t5, zero, frame_delay_outer

    jal zero, main_loop

# copy 1024-byte map to OLED framebuffer shadow
copy_map_to_oled:
    addi t0, zero, 0
copy_loop:
    add t1, s3, t0
    lbu t2, 0(t1)
    add t3, s2, t0
    sb t2, 0(t3)
    addi t0, t0, 1
    addi t4, zero, 1024
    blt t0, t4, copy_loop
    jalr zero, 0(ra)

# a0=x, a1=y top-left, toggle a 2x2 sprite
plot_toggle_2x2:
    addi s10, ra, 0

    jal ra, toggle_pixel

    addi a0, a0, 1
    jal ra, toggle_pixel

    addi a0, a0, -1
    addi a1, a1, 1
    jal ra, toggle_pixel

    addi a0, a0, 1
    jal ra, toggle_pixel

    addi ra, s10, 0
    jalr zero, 0(ra)

# a0=x(0..127), a1=y(0..63): toggle bit in OLED shadow
toggle_pixel:
    srli t0, a1, 3
    slli t0, t0, 7
    add t0, t0, a0
    add t0, t0, s2

    andi t1, a1, 7
    addi t2, zero, 1
pixel_shift_loop:
    beq t1, zero, pixel_shift_done
    slli t2, t2, 1
    addi t1, t1, -1
    jal zero, pixel_shift_loop
pixel_shift_done:
    lbu t3, 0(t0)
    xor t3, t3, t2
    sb t3, 0(t0)
    jalr zero, 0(ra)
