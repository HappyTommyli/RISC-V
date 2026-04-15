# Lode Runner (CPU version) for pipeline.v
# MMIO:
# 0x8000: buttons [3:0] => [UP,DOWN,LEFT,RIGHT]
# 0x8004: timer
# 0xA000..0xA07F: OLED 32x32 framebuffer bytes (page-major)

_start:
    addi x10, x0, 16      # player_x
    addi x11, x0, 8       # player_y
    addi x12, x0, 0       # last_timer
    lui  x30, 0x8         # IO base 0x8000
    lui  x31, 0xA         # FB base 0xA000

_main:
    lw   t0, 4(x30)       # timer
    sub  t1, t0, x12
    srli t1, t1, 20
    beq  t1, x0, _main
    addi x12, t0, 0

    lw   t2, 0(x30)       # buttons

_chk_right:
    andi t3, t2, 8
    beq  t3, x0, _chk_left
    addi t4, x10, -30
    bge  t4, x0, _chk_left
    addi x10, x10, 1

_chk_left:
    andi t3, t2, 4
    beq  t3, x0, _chk_up
    addi t4, x10, -1
    beq  t4, x0, _chk_up
    addi x10, x10, -1

_chk_up:
    andi t3, t2, 1
    beq  t3, x0, _chk_down
    addi t4, x10, -8
    bne  t4, x0, _chk_down
    addi t4, x11, -1
    beq  t4, x0, _chk_down
    addi x11, x11, -1

_chk_down:
    andi t3, t2, 2
    beq  t3, x0, _gravity
    addi t4, x11, -30
    bge  t4, x0, _gravity
    addi x11, x11, 1

_gravity:
    addi t4, x10, -8
    beq  t4, x0, _render
    addi t4, x11, -30
    bge  t4, x0, _render
    addi x11, x11, 1

_render:
    # clear 128 bytes
    addi t0, x0, 0
_clr_loop:
    add  t1, x31, t0
    sb   x0, 0(t1)
    addi t0, t0, 1
    addi t2, x0, 128
    blt  t0, t2, _clr_loop

    # floor: addr 96..127 = 0x80
    addi t0, x0, 96
_floor_loop:
    add  t1, x31, t0
    addi t3, x0, 128
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t2, x0, 128
    blt  t0, t2, _floor_loop

    # platform: addr 68..91 = 0x80
    addi t0, x0, 68
_plat_loop:
    add  t1, x31, t0
    addi t3, x0, 128
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t2, x0, 92
    blt  t0, t2, _plat_loop

    # ladder at x=8: page2 addr72 and page3 addr104 = 0xFF
    addi t3, x0, -1
    addi t0, x0, 72
    add  t1, x31, t0
    sb   t3, 0(t1)
    addi t0, x0, 104
    add  t1, x31, t0
    sb   t3, 0(t1)

    # coins: precomposed bytes
    addi t3, x0, 192
    addi t0, x0, 84
    add  t1, x31, t0
    sb   t3, 0(t1)
    addi t0, x0, 101
    add  t1, x31, t0
    sb   t3, 0(t1)

    # player pixel
    srli t0, x11, 3
    slli t0, t0, 5
    add  t0, t0, x10
    add  t1, x31, t0
    andi t2, x11, 7
    addi t3, x0, 1

_shift_loop:
    beq  t2, x0, _store_player
    slli t3, t3, 1
    addi t2, t2, -1
    jal  x0, _shift_loop

_store_player:
    sb   t3, 0(t1)
    jal  x0, _main
