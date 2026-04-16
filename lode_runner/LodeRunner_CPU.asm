# Lode Runner lite (128x64)
# buttons[3:0] = {RIGHT, LEFT, DOWN, UP}
# IO:
#   0x00008000 buttons
#   0x00009000 display busy/read, redraw trigger/write
#   0x0000A000..0x0000A3FF OLED framebuffer (1024 bytes)
# RAM:
#   0x00000000 player_x
#   0x00000004 player_y
#   0x00001000..0x000013FF map framebuffer seed (from lode_runner.png)

start:
    lui s0, 0x8          # buttons
    lui s1, 0x9          # display
    lui s2, 0xA          # oled framebuffer
    lui s3, 0x1 # map base in data memory

    addi t0, zero, 8
    sw t0, 0(zero)       # player_x
    addi t0, zero, 61
    sw t0, 4(zero)       # player_y (2px sprite stands on y=63 floor)

    jal ra, frame_render

main_loop:
    lw t0, 0(s0)

check_up:
    andi t1, t0, 1
    beq t1, zero, check_down
    lw t2, 4(zero)
    beq t2, zero, check_down
    lw a0, 0(zero)
    lw a1, 4(zero)
    jal ra, is_ladder
    bne a0, zero, do_up
    lw a0, 0(zero)
    addi a0, a0, 1
    lw a1, 4(zero)
    jal ra, is_ladder
    beq a0, zero, check_down

do_up:
    lw t2, 4(zero)
    addi t2, t2, -1
    sw t2, 4(zero)

check_down:
    andi t1, t0, 2
    beq t1, zero, check_left
    lw t2, 4(zero)
    addi t3, zero, 62
    bge t2, t3, check_left
    lw a0, 0(zero)
    lw a1, 4(zero)
    addi a1, a1, 1
    jal ra, is_ladder
    bne a0, zero, do_down
    lw a0, 0(zero)
    addi a0, a0, 1
    lw a1, 4(zero)
    addi a1, a1, 1
    jal ra, is_ladder
    beq a0, zero, check_left

do_down:
    lw t2, 4(zero)
    addi t2, t2, 1
    sw t2, 4(zero)

check_left:
    andi t1, t0, 4
    beq t1, zero, check_right
    lw t2, 0(zero)
    beq t2, zero, check_right
    addi t2, t2, -1
    sw t2, 0(zero)

check_right:
    andi t1, t0, 8
    beq t1, zero, apply_gravity
    lw t2, 0(zero)
    addi t3, zero, 126
    bge t2, t3, apply_gravity
    addi t2, t2, 1
    sw t2, 0(zero)

apply_gravity:
    lw t2, 4(zero)
    addi t3, zero, 62
    bge t2, t3, do_frame

    lw a0, 0(zero)
    lw a1, 4(zero)
    jal ra, is_ladder
    bne a0, zero, do_frame
    lw a0, 0(zero)
    addi a0, a0, 1
    lw a1, 4(zero)
    jal ra, is_ladder
    bne a0, zero, do_frame

    lw a0, 0(zero)
    lw a1, 4(zero)
    addi a1, a1, 2
    jal ra, is_solid
    bne a0, zero, do_frame

    lw a0, 0(zero)
    addi a0, a0, 1
    lw a1, 4(zero)
    addi a1, a1, 2
    jal ra, is_solid
    bne a0, zero, do_frame

    lw t2, 4(zero)
    addi t2, t2, 1
    sw t2, 4(zero)

do_frame:
    jal ra, frame_render

    addi t0, zero, 8
delay_outer:
    addi t1, zero, 2000
delay_inner:
    addi t1, t1, -1
    bne t1, zero, delay_inner
    addi t0, t0, -1
    bne t0, zero, delay_outer

    jal zero, main_loop

# Copy map to OLED, draw player, trigger refresh
frame_render:
    addi s11, ra, 0

    addi t0, zero, 0
copy_map_loop:
    add t1, s3, t0
    lbu t2, 0(t1)
    add t3, s2, t0
    sb t2, 0(t3)
    addi t0, t0, 1
    addi t4, zero, 1024
    blt t0, t4, copy_map_loop

    lw a0, 0(zero)
    lw a1, 4(zero)
    jal ra, plot_player_2x2

wait_display_idle:
    lw t0, 0(s1)
    bne t0, zero, wait_display_idle
    sw zero, 0(s1)

    addi ra, s11, 0
    jalr zero, 0(ra)

# a0=x, a1=y (top-left)
plot_player_2x2:
    addi s10, ra, 0

    jal ra, set_pixel

    addi a0, a0, 1
    jal ra, set_pixel

    addi a0, a0, -1
    addi a1, a1, 1
    jal ra, set_pixel

    addi a0, a0, 1
    jal ra, set_pixel

    addi ra, s10, 0
    jalr zero, 0(ra)

# a0=x(0..127), a1=y(0..63): set pixel in OLED framebuffer shadow
set_pixel:
    srli t0, a1, 3       # page
    slli t0, t0, 7       # page * 128
    add t0, t0, a0       # byte index
    add t0, t0, s2       # oled byte addr

    andi t1, a1, 7       # bit offset
    addi t2, zero, 1
shift_mask_loop:
    beq t1, zero, shift_mask_done
    slli t2, t2, 1
    addi t1, t1, -1
    jal zero, shift_mask_loop
shift_mask_done:
    lbu t3, 0(t0)
    or t3, t3, t2
    sb t3, 0(t0)
    jalr zero, 0(ra)

# a0=x, a1=y -> return a0=1 if solid platform, else 0
is_solid:
    addi t0, zero, 63
    beq a1, t0, solid_yes

    addi t0, zero, 48
    bne a1, t0, solid_check_32
    addi t1, zero, 96
    blt a0, t1, solid_yes
    jal zero, solid_no

solid_check_32:
    addi t0, zero, 32
    bne a1, t0, solid_check_16
    addi t1, zero, 32
    blt a0, t1, solid_no
    jal zero, solid_yes

solid_check_16:
    addi t0, zero, 16
    bne a1, t0, solid_no
    addi t1, zero, 80
    blt a0, t1, solid_yes
    jal zero, solid_no

solid_yes:
    addi a0, zero, 1
    jalr zero, 0(ra)

solid_no:
    addi a0, zero, 0
    jalr zero, 0(ra)

# a0=x, a1=y -> return a0=1 if ladder, else 0
is_ladder:
    # ladder1: x=[24,28), y=[33,49)
    addi t0, zero, 24
    blt a0, t0, ladder_check_2
    addi t1, zero, 28
    bge a0, t1, ladder_check_2
    addi t2, zero, 33
    blt a1, t2, ladder_check_2
    addi t3, zero, 49
    blt a1, t3, ladder_yes

ladder_check_2:
    # ladder2: x=[52,56), y=[17,33)
    addi t0, zero, 52
    blt a0, t0, ladder_check_3
    addi t1, zero, 56
    bge a0, t1, ladder_check_3
    addi t2, zero, 17
    blt a1, t2, ladder_check_3
    addi t3, zero, 33
    blt a1, t3, ladder_yes

ladder_check_3:
    # ladder3: x=[88,92), y=[1,17)
    addi t0, zero, 88
    blt a0, t0, ladder_no
    addi t1, zero, 92
    bge a0, t1, ladder_no
    addi t2, zero, 1
    blt a1, t2, ladder_no
    addi t3, zero, 17
    blt a1, t3, ladder_yes

ladder_no:
    addi a0, zero, 0
    jalr zero, 0(ra)

ladder_yes:
    addi a0, zero, 1
    jalr zero, 0(ra)
