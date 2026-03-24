# Pet Game (pipeline_opt)
# Memory map:
# 0x0000-0x7FFF : internal RAM (32KB)
# 0x8000        : buttons (bit0 feed, bit1 play, bit2 switch)
# 0x8004        : timer
# 0x9000        : display cmd (bit31 busy on read)
#
# Register usage:
# x10: current pet index (0-4)
# x11: (unused, reserved)
# x12: (unused, reserved)
# x20: buttons
# x21: last timer value

.text
.globl _game_start
_game_start:
    # Init 5 pets at 0x4000, each 8 bytes (Sat, Hap)
    addi t0, x0, 100       # initial value 100
    lui  t1, 0x4           # base = 0x4000
    addi t2, x0, 5         # count = 5
init_loop:
    sw   t0, 0(t1)         # Sat
    sw   t0, 4(t1)         # Hap
    addi t1, t1, 8
    addi t2, t2, -1
    bne  t2, x0, init_loop

    addi x10, x0, 0        # current pet = 0
    addi x21, x0, 0        # last timer = 0
    lui  x30, 0x8          # IO base = 0x8000

_main_loop:
    # Timer check
    lw   t2, 4(x30)        # timer
    sub  t3, t2, x21
    srli t3, t3, 20        # adjust speed
    beq  t3, x0, _check_input

    jal  x1, _decrease_stats
    add  x21, t2, x0       # update last timer

_check_input:
    lw   x20, 0(x30)       # buttons

    andi t4, x20, 1        # feed
    bne  t4, x0, _feed_pet

    andi t4, x20, 2        # play
    bne  t4, x0, _play_pet

    andi t4, x20, 4        # switch
    bne  t4, x0, _switch_pet

    jal  x1, _update_expression
    jal  x0, _main_loop

# --- decrease stats (Sat/Hap -= 1, clamp at 0) ---
_decrease_stats:
    slli t5, x10, 3
    lui  t6, 0x4
    add  t5, t5, t6        # t5 = base + idx*8

    lw   t0, 0(t5)         # Sat
    addi t0, t0, -1
    bge  t0, x0, ds_store_sat
    addi t0, x0, 0
 ds_store_sat:
    sw   t0, 0(t5)

    lw   t0, 4(t5)         # Hap
    addi t0, t0, -1
    bge  t0, x0, ds_store_hap
    addi t0, x0, 0
 ds_store_hap:
    sw   t0, 4(t5)
    jalr x0, 0(x1)

# --- feed pet (Sat += 10, clamp at 100) ---
_feed_pet:
    slli t5, x10, 3
    lui  t6, 0x4
    add  t5, t5, t6
    lw   t0, 0(t5)
    addi t0, t0, 10
    addi t1, x0, 100
    blt  t0, t1, feed_store
    addi t0, x0, 100
 feed_store:
    sw   t0, 0(t5)
    jal  x0, _main_loop

# --- play pet (Hap += 10, clamp at 100) ---
_play_pet:
    slli t5, x10, 3
    lui  t6, 0x4
    add  t5, t5, t6
    lw   t0, 4(t5)
    addi t0, t0, 10
    addi t1, x0, 100
    blt  t0, t1, play_store
    addi t0, x0, 100
 play_store:
    sw   t0, 4(t5)
    jal  x0, _main_loop

# --- update expression and display ---
_update_expression:
    slli t5, x10, 3
    lui  t6, 0x4
    add  t5, t5, t6

    lw   t0, 0(t5)         # Sat
    addi t1, x0, 30
    blt  t0, t1, _exp_hungry

    lw   t0, 4(t5)         # Hap
    blt  t0, t1, _exp_sad

    addi a0, x0, 0         # happy
    jal  x0, _display_out

_exp_hungry:
    addi a0, x0, 1
    jal  x0, _display_out

_exp_sad:
    addi a0, x0, 2
    jal  x0, _display_out

_display_out:
    lui  t4, 0x9           # 0x9000
    slli t5, x10, 8        # PetID << 8
    or   t5, t5, a0        # + ExpID
    sw   t5, 0(t4)
    jalr x0, 0(x1)

# --- switch pet ---
_switch_pet:
    addi x10, x10, 1
    addi t4, x0, 5
    blt  x10, t4, _switch_done
    addi x10, x0, 0
_switch_done:
    jal  x0, _main_loop
