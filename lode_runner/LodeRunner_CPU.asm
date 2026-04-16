# Lode Runner lite for RV32I pipeline + OLED framebuffer
# IO map:
#   0x00008000 : buttons [3:0] = {RIGHT, LEFT, DOWN, UP}
#   0x00009000 : display busy/status (read), redraw trigger (write)
#   0x0000A000 : OLED framebuffer [128 bytes]
# RAM map:
#   0x00000000 : player_x
#   0x00000004 : player_y
#   0x00000200 : shadow framebuffer (128 bytes)
#   0x00000300 : background framebuffer (128 bytes)

start:
    lui s0, 0x8          # buttons base
    lui s1, 0x9          # display status/command base
    lui s2, 0xA          # oled fb base
    addi s3, zero, 0x200 # shadow base
    addi s4, zero, 0x300 # background base

    addi t0, zero, 2
    sw t0, 0(zero)       # player_x = 2
    addi t0, zero, 30
    sw t0, 4(zero)       # player_y = 30

    jal ra, init_bg
    jal ra, draw_frame

main_loop:
    lw t0, 0(s0)

check_up:
    andi t1, t0, 1
    beq t1, zero, check_down
    lw a0, 0(zero)
    lw a1, 4(zero)
    jal ra, is_ladder
    beq a0, zero, check_down
    lw t2, 4(zero)
    beq t2, zero, check_down
    addi t2, t2, -1
    sw t2, 4(zero)

check_down:
    andi t1, t0, 2
    beq t1, zero, check_left
    lw t2, 4(zero)
    addi t3, zero, 31
    bge t2, t3, check_left
    lw a0, 0(zero)
    lw a1, 4(zero)
    addi a1, a1, 1
    jal ra, is_ladder
    beq a0, zero, check_left
    lw t2, 4(zero)
    addi t2, t2, 1
    sw t2, 4(zero)

check_left:
    andi t1, t0, 4
    beq t1, zero, check_right
    lw t2, 0(zero)
    beq t2, zero, check_right
    addi a0, t2, -1
    lw a1, 4(zero)
    jal ra, is_solid
    bne a0, zero, check_right
    lw t2, 0(zero)
    addi t2, t2, -1
    sw t2, 0(zero)

check_right:
    andi t1, t0, 8
    beq t1, zero, apply_gravity
    lw t2, 0(zero)
    addi t3, zero, 31
    bge t2, t3, apply_gravity
    addi a0, t2, 1
    lw a1, 4(zero)
    jal ra, is_solid
    bne a0, zero, apply_gravity
    lw t2, 0(zero)
    addi t2, t2, 1
    sw t2, 0(zero)

apply_gravity:
    lw t2, 4(zero)
    addi t3, zero, 31
    bge t2, t3, frame_and_delay
    lw a0, 0(zero)
    lw a1, 4(zero)
    jal ra, is_ladder
    bne a0, zero, frame_and_delay
    lw a0, 0(zero)
    lw a1, 4(zero)
    addi a1, a1, 1
    jal ra, is_solid
    bne a0, zero, frame_and_delay
    lw t2, 4(zero)
    addi t2, t2, 1
    sw t2, 4(zero)

frame_and_delay:
    jal ra, draw_frame

    addi t0, zero, 120
outer_delay:
    addi t1, zero, 200
inner_delay:
    addi t1, t1, -1
    bne t1, zero, inner_delay
    addi t0, t0, -1
    bne t0, zero, outer_delay

    jal zero, main_loop

# Build static level into background framebuffer (0x300~0x37F)
init_bg:
    addi s11, ra, 0

    addi t0, zero, 0
clear_bg_loop:
    add t1, s4, t0
    sb zero, 0(t1)
    addi t0, t0, 1
    addi t2, zero, 128
    blt t0, t2, clear_bg_loop

    # floor y=31, x=0..31
    addi t0, zero, 0
hline_floor:
    addi a0, t0, 0
    addi a1, zero, 31
    jal ra, set_pixel_bg
    addi t0, t0, 1
    addi t2, zero, 32
    blt t0, t2, hline_floor

    # platform y=24, x=0..23
    addi t0, zero, 0
hline_p24:
    addi a0, t0, 0
    addi a1, zero, 24
    jal ra, set_pixel_bg
    addi t0, t0, 1
    addi t2, zero, 24
    blt t0, t2, hline_p24

    # platform y=16, x=8..31
    addi t0, zero, 8
hline_p16:
    addi a0, t0, 0
    addi a1, zero, 16
    jal ra, set_pixel_bg
    addi t0, t0, 1
    addi t2, zero, 32
    blt t0, t2, hline_p16

    # platform y=8, x=0..19
    addi t0, zero, 0
hline_p8:
    addi a0, t0, 0
    addi a1, zero, 8
    jal ra, set_pixel_bg
    addi t0, t0, 1
    addi t2, zero, 20
    blt t0, t2, hline_p8

    # ladder x=6, y=17..24
    addi t0, zero, 17
vline_l1:
    addi a0, zero, 6
    addi a1, t0, 0
    jal ra, set_pixel_bg
    addi t0, t0, 1
    addi t2, zero, 25
    blt t0, t2, vline_l1

    # ladder x=13, y=9..16
    addi t0, zero, 9
vline_l2:
    addi a0, zero, 13
    addi a1, t0, 0
    jal ra, set_pixel_bg
    addi t0, t0, 1
    addi t2, zero, 17
    blt t0, t2, vline_l2

    # ladder x=22, y=1..8
    addi t0, zero, 1
vline_l3:
    addi a0, zero, 22
    addi a1, t0, 0
    jal ra, set_pixel_bg
    addi t0, t0, 1
    addi t2, zero, 9
    blt t0, t2, vline_l3

    addi ra, s11, 0
    jalr zero, 0(ra)

# a0=x, a1=y -> set pixel in background framebuffer
set_pixel_bg:
    srli t0, a1, 3
    slli t0, t0, 5
    add t0, t0, a0
    add t0, t0, s4

    andi t1, a1, 7
    addi t2, zero, 1
set_bg_shift:
    beq t1, zero, set_bg_shift_done
    slli t2, t2, 1
    addi t1, t1, -1
    jal zero, set_bg_shift
set_bg_shift_done:
    lbu t3, 0(t0)
    or t3, t3, t2
    sb t3, 0(t0)
    jalr zero, 0(ra)

# Copy bg->shadow, draw player, copy shadow->OLED, trigger redraw
draw_frame:
    addi s11, ra, 0

    addi t0, zero, 0
copy_bg_to_shadow:
    add t1, s4, t0
    lbu t2, 0(t1)
    add t3, s3, t0
    sb t2, 0(t3)
    addi t0, t0, 1
    addi t4, zero, 128
    blt t0, t4, copy_bg_to_shadow

    lw a0, 0(zero)
    lw a1, 4(zero)

    srli t0, a1, 3
    slli t0, t0, 5
    add t0, t0, a0
    add t0, t0, s3

    andi t1, a1, 7
    addi t2, zero, 1
player_shift:
    beq t1, zero, player_shift_done
    slli t2, t2, 1
    addi t1, t1, -1
    jal zero, player_shift
player_shift_done:
    lbu t3, 0(t0)
    or t3, t3, t2
    sb t3, 0(t0)

    addi t0, zero, 0
copy_shadow_to_oled:
    add t1, s3, t0
    lbu t2, 0(t1)
    add t3, s2, t0
    sb t2, 0(t3)
    addi t0, t0, 1
    addi t4, zero, 128
    blt t0, t4, copy_shadow_to_oled

wait_display_idle:
    lw t0, 0(s1)
    bne t0, zero, wait_display_idle
    sw zero, 0(s1)

    addi ra, s11, 0
    jalr zero, 0(ra)

# a0=x, a1=y -> return a0=1 if solid, else 0
is_solid:
    addi t0, zero, 31
    beq a1, t0, solid_yes

    addi t0, zero, 24
    bne a1, t0, solid_check_16
    addi t1, zero, 24
    blt a0, t1, solid_yes
    jal zero, solid_no

solid_check_16:
    addi t0, zero, 16
    bne a1, t0, solid_check_8
    addi t1, zero, 8
    blt a0, t1, solid_no
    jal zero, solid_yes

solid_check_8:
    addi t0, zero, 8
    bne a1, t0, solid_no
    addi t1, zero, 20
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
    addi t0, zero, 6
    bne a0, t0, ladder_check_2
    addi t1, zero, 17
    blt a1, t1, ladder_check_2
    addi t2, zero, 25
    blt a1, t2, ladder_yes

ladder_check_2:
    addi t0, zero, 13
    bne a0, t0, ladder_check_3
    addi t1, zero, 9
    blt a1, t1, ladder_check_3
    addi t2, zero, 17
    blt a1, t2, ladder_yes

ladder_check_3:
    addi t0, zero, 22
    bne a0, t0, ladder_no
    addi t1, zero, 1
    blt a1, t1, ladder_no
    addi t2, zero, 9
    blt a1, t2, ladder_yes

ladder_no:
    addi a0, zero, 0
    jalr zero, 0(ra)

ladder_yes:
    addi a0, zero, 1
    jalr zero, 0(ra)
