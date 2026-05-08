# Mini Tetris (O-piece core) for pipeline_lut_opt
# MMIO map:
#   0x80000000 UART TX (write byte)
#   0x80000004 UART RX (read byte)
#   0x80000008 UART RX status bit0
#   0x8000000C timer (1 tick/sec in current Data_Mem.v)
#
# Controls:
#   A/D : move left/right
#   S   : soft drop
#   W   : rotate (no-op for O piece)
#   Space: hard drop
#   Q   : quit

# RAM usage
#   0x00000000 cur_x
#   0x00000004 cur_y
#   0x00000008 score
#   0x0000000C last_timer
#   0x00000010 game_over
# board at 0x00001000 .. 0x000010C7 (10*20 bytes)

start:
    lui s0, 0x80000         # MMIO base
    lui s1, 0x1             # board base = 0x1000

    sw zero, 8(zero)        # score = 0
    sw zero, 16(zero)       # game_over = 0

    jal ra, clear_board
    jal ra, spawn_piece

    lw t0, 12(s0)           # timer
    sw t0, 12(zero)         # last_timer

main_loop:
    # non-blocking input
    lw t0, 8(s0)            # rx status
    andi t0, t0, 1
    beq t0, zero, check_gravity

    lw t1, 4(s0)            # key

    addi t2, zero, 97       # 'a'
    beq t1, t2, key_left
    addi t2, zero, 65       # 'A'
    beq t1, t2, key_left

    addi t2, zero, 100      # 'd'
    beq t1, t2, key_right
    addi t2, zero, 68       # 'D'
    beq t1, t2, key_right

    addi t2, zero, 115      # 's'
    beq t1, t2, key_down
    addi t2, zero, 83       # 'S'
    beq t1, t2, key_down

    addi t2, zero, 119      # 'w'
    beq t1, t2, key_rot
    addi t2, zero, 87       # 'W'
    beq t1, t2, key_rot

    addi t2, zero, 32       # space
    beq t1, t2, key_drop

    addi t2, zero, 113      # 'q'
    beq t1, t2, key_quit
    addi t2, zero, 81       # 'Q'
    beq t1, t2, key_quit
    jal zero, check_gravity

key_left:
    jal ra, try_move_left
    jal zero, check_gravity

key_right:
    jal ra, try_move_right
    jal zero, check_gravity

key_down:
    jal ra, step_down_once
    jal zero, check_gravity

key_rot:
    # O-piece rotate no-op
    jal zero, check_gravity

key_drop:
hard_drop_loop:
    jal ra, can_move_down
    beq a0, zero, hard_drop_lock
    lw t0, 4(zero)
    addi t0, t0, 1
    sw t0, 4(zero)
    jal zero, hard_drop_loop

hard_drop_lock:
    jal ra, lock_piece
    jal ra, clear_lines
    jal ra, spawn_piece
    jal zero, check_gravity

key_quit:
    addi t0, zero, 1
    sw t0, 16(zero)

check_gravity:
    lw t0, 12(s0)           # now
    lw t1, 12(zero)         # last
    sub t2, t0, t1
    addi t3, zero, 1        # gravity ticks
    blt t2, t3, loop_tail

    jal ra, step_down_once
    lw t0, 12(s0)
    sw t0, 12(zero)

loop_tail:
    jal ra, render
    lw t0, 16(zero)
    beq t0, zero, main_loop

end_game:
    jal ra, print_game_over
halt:
    jal zero, halt

# ------------------------------------------------------------
# step_down_once:
# if can down -> y++
# else lock, clear, spawn
step_down_once:
    addi sp, sp, -16
    sw ra, 12(sp)

    jal ra, can_move_down
    beq a0, zero, step_down_lock

    lw t0, 4(zero)
    addi t0, t0, 1
    sw t0, 4(zero)
    jal zero, step_down_done

step_down_lock:
    jal ra, lock_piece
    jal ra, clear_lines
    jal ra, spawn_piece

step_down_done:
    lw ra, 12(sp)
    addi sp, sp, 16
    jalr zero, 0(ra)

# ------------------------------------------------------------
# spawn_piece: O piece spawn at x=4,y=0 and collision check
spawn_piece:
    addi t0, zero, 4
    sw t0, 0(zero)
    sw zero, 4(zero)

    jal ra, collides_current
    beq a0, zero, spawn_ok

    addi t0, zero, 1
    sw t0, 16(zero)
spawn_ok:
    jalr zero, 0(ra)

# ------------------------------------------------------------
# try_move_left
try_move_left:
    lw t0, 0(zero)
    beq t0, zero, tml_ret

    addi t0, t0, -1
    sw t0, 0(zero)
    jal ra, collides_current
    beq a0, zero, tml_ret

    lw t0, 0(zero)
    addi t0, t0, 1
    sw t0, 0(zero)

tml_ret:
    jalr zero, 0(ra)

# try_move_right
try_move_right:
    lw t0, 0(zero)
    addi t1, zero, 8        # max x for 2-wide piece in 10 cols
    bge t0, t1, tmr_ret

    addi t0, t0, 1
    sw t0, 0(zero)
    jal ra, collides_current
    beq a0, zero, tmr_ret

    lw t0, 0(zero)
    addi t0, t0, -1
    sw t0, 0(zero)

tmr_ret:
    jalr zero, 0(ra)

# can_move_down -> a0=1/0
can_move_down:
    lw t0, 4(zero)
    addi t0, t0, 1
    sw t0, 4(zero)

    jal ra, collides_current
    bne a0, zero, cmd_blocked

    lw t0, 4(zero)
    addi t0, t0, -1
    sw t0, 4(zero)
    addi a0, zero, 1
    jalr zero, 0(ra)

cmd_blocked:
    lw t0, 4(zero)
    addi t0, t0, -1
    sw t0, 4(zero)
    addi a0, zero, 0
    jalr zero, 0(ra)

# collides_current -> a0=1 collision, a0=0 no collision
# O piece cells: (x,y), (x+1,y), (x,y+1), (x+1,y+1)
collides_current:
    lw t0, 0(zero)          # x
    lw t1, 4(zero)          # y

    # boundary check x in [0,8], y in [0,18]
    blt t0, zero, cc_yes
    addi t2, zero, 8
    blt t2, t0, cc_yes
    blt t1, zero, cc_yes
    addi t2, zero, 18
    blt t2, t1, cc_yes

    # check 4 board cells
    addi a0, t0, 0
    addi a1, t1, 0
    jal ra, board_get
    bne a0, zero, cc_yes

    addi a0, t0, 1
    addi a1, t1, 0
    jal ra, board_get
    bne a0, zero, cc_yes

    addi a0, t0, 0
    addi a1, t1, 1
    jal ra, board_get
    bne a0, zero, cc_yes

    addi a0, t0, 1
    addi a1, t1, 1
    jal ra, board_get
    bne a0, zero, cc_yes

    addi a0, zero, 0
    jalr zero, 0(ra)

cc_yes:
    addi a0, zero, 1
    jalr zero, 0(ra)

# lock_piece (write value 1)
lock_piece:
    lw t0, 0(zero)
    lw t1, 4(zero)

    addi a0, t0, 0
    addi a1, t1, 0
    addi a2, zero, 1
    jal ra, board_set

    addi a0, t0, 1
    addi a1, t1, 0
    addi a2, zero, 1
    jal ra, board_set

    addi a0, t0, 0
    addi a1, t1, 1
    addi a2, zero, 1
    jal ra, board_set

    addi a0, t0, 1
    addi a1, t1, 1
    addi a2, zero, 1
    jal ra, board_set

    jalr zero, 0(ra)

# ------------------------------------------------------------
# clear_lines: full row -> shift above rows down
clear_lines:
    addi s2, zero, 19      # y
cl_row_loop:
    blt s2, zero, cl_done

    addi s3, zero, 0       # x
    addi s4, zero, 1       # full = 1
cl_full_check:
    addi a0, s3, 0
    addi a1, s2, 0
    jal ra, board_get
    bne a0, zero, cl_next_cell
    addi s4, zero, 0
    jal zero, cl_check_done

cl_next_cell:
    addi s3, s3, 1
    addi t0, zero, 10
    blt s3, t0, cl_full_check

cl_check_done:
    beq s4, zero, cl_y_dec

    # shift rows: for yy=y downto 1, board[yy][x]=board[yy-1][x]
    addi s5, s2, 0         # yy
cl_shift_rows:
    blt zero, s5, cl_shift_rows_work
    jal zero, cl_clear_top
cl_shift_rows_work:
    addi s3, zero, 0       # x
cl_shift_cols:
    addi a0, s3, 0
    addi a1, s5, -1
    jal ra, board_get      # a0 = src

    addi a2, a0, 0
    addi a0, s3, 0
    addi a1, s5, 0
    jal ra, board_set

    addi s3, s3, 1
    addi t0, zero, 10
    blt s3, t0, cl_shift_cols

    addi s5, s5, -1
    jal zero, cl_shift_rows

cl_clear_top:
    addi s3, zero, 0
cl_top_cols:
    addi a0, s3, 0
    addi a1, zero, 0
    addi a2, zero, 0
    jal ra, board_set

    addi s3, s3, 1
    addi t0, zero, 10
    blt s3, t0, cl_top_cols

    # score += 1
    lw t0, 8(zero)
    addi t0, t0, 1
    sw t0, 8(zero)

    # same y again after shift
    jal zero, cl_row_loop

cl_y_dec:
    addi s2, s2, -1
    jal zero, cl_row_loop

cl_done:
    jalr zero, 0(ra)

# ------------------------------------------------------------
# clear_board
clear_board:
    addi t0, zero, 0
    addi t1, zero, 200
cb_loop:
    add t2, s1, t0
    sb zero, 0(t2)
    addi t0, t0, 1
    blt t0, t1, cb_loop
    jalr zero, 0(ra)

# board_get(a0=x,a1=y) -> a0=value
board_get:
    # idx = y*10 + x = y*8 + y*2 + x
    slli t0, a1, 3
    slli t1, a1, 1
    add t0, t0, t1
    add t0, t0, a0
    add t0, t0, s1
    lbu a0, 0(t0)
    jalr zero, 0(ra)

# board_set(a0=x,a1=y,a2=val)
board_set:
    slli t0, a1, 3
    slli t1, a1, 1
    add t0, t0, t1
    add t0, t0, a0
    add t0, t0, s1
    sb a2, 0(t0)
    jalr zero, 0(ra)

# ------------------------------------------------------------
# render terminal via UART
render:
    addi sp, sp, -16
    sw ra, 12(sp)

    # ESC[2JESC[H
    addi a0, zero, 27
    jal ra, uart_putc
    addi a0, zero, 91
    jal ra, uart_putc
    addi a0, zero, 50
    jal ra, uart_putc
    addi a0, zero, 74
    jal ra, uart_putc
    addi a0, zero, 27
    jal ra, uart_putc
    addi a0, zero, 91
    jal ra, uart_putc
    addi a0, zero, 72
    jal ra, uart_putc

    addi s2, zero, 0       # y
r_row_loop:
    addi t0, zero, 20
    bge s2, t0, r_bottom

    addi a0, zero, 124     # '|'
    jal ra, uart_putc

    addi s3, zero, 0       # x
r_col_loop:
    addi t0, zero, 10
    bge s3, t0, r_row_end

    # overlay active O-piece
    lw t1, 0(zero)         # cur_x
    lw t2, 4(zero)         # cur_y

    addi t3, t1, 2
    blt s3, t1, r_not_active
    bge s3, t3, r_not_active

    addi t4, t2, 2
    blt s2, t2, r_not_active
    bge s2, t4, r_not_active

    addi a0, zero, 35      # '#'
    jal ra, uart_putc
    jal zero, r_next_col

r_not_active:
    addi a0, s3, 0
    addi a1, s2, 0
    jal ra, board_get
    beq a0, zero, r_empty

    addi a0, zero, 35      # '#'
    jal ra, uart_putc
    jal zero, r_next_col

r_empty:
    addi a0, zero, 46      # '.'
    jal ra, uart_putc

r_next_col:
    addi s3, s3, 1
    jal zero, r_col_loop

r_row_end:
    addi a0, zero, 124     # '|'
    jal ra, uart_putc
    jal ra, uart_nl

    addi s2, s2, 1
    jal zero, r_row_loop

r_bottom:
    addi s3, zero, 0
r_btm_loop:
    addi t0, zero, 12
    bge s3, t0, r_score
    addi a0, zero, 45      # '-'
    jal ra, uart_putc
    addi s3, s3, 1
    jal zero, r_btm_loop

r_score:
    jal ra, uart_nl
    addi a0, zero, 83      # S
    jal ra, uart_putc
    addi a0, zero, 58      # :
    jal ra, uart_putc

    lw t2, 8(zero)         # score (0..)
score_mod10:
    addi t1, zero, 10
    blt t2, t1, score_mod10_done
    addi t2, t2, -10
    jal zero, score_mod10
score_mod10_done:
    addi t2, t2, 48
    addi a0, t2, 0
    jal ra, uart_putc
    jal ra, uart_nl

    lw ra, 12(sp)
    addi sp, sp, 16
    jalr zero, 0(ra)

print_game_over:
    addi a0, zero, 71      # G
    jal ra, uart_putc
    addi a0, zero, 65      # A
    jal ra, uart_putc
    addi a0, zero, 77      # M
    jal ra, uart_putc
    addi a0, zero, 69      # E
    jal ra, uart_putc
    addi a0, zero, 32      # ' '
    jal ra, uart_putc
    addi a0, zero, 79      # O
    jal ra, uart_putc
    addi a0, zero, 86      # V
    jal ra, uart_putc
    addi a0, zero, 69      # E
    jal ra, uart_putc
    addi a0, zero, 82      # R
    jal ra, uart_putc
    jal ra, uart_nl
    jalr zero, 0(ra)

uart_nl:
    addi a0, zero, 13      # '\r'
    jal ra, uart_putc
    addi a0, zero, 10      # '\n'
    jal ra, uart_putc
    jalr zero, 0(ra)

uart_putc:
    sw a0, 0(s0)
    jalr zero, 0(ra)
