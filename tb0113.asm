    #######################################
    # 初始化 base 指標
    #######################################
    nop

    # t0 = base of A = 0x1000
    lui   t0, 0x1
    addi  t0, t0, 0          # A: 0x1000

    # t1 = base of B = 0x1010
    lui   t1, 0x1
    addi  t1, t1, 16         # B: 0x1010

    # t2 = base of C = 0x1020
    lui   t2, 0x1
    addi  t2, t2, 32         # C: 0x1020

    #######################################
    # A, B 初始化（和你原先那段一致）
    #######################################
    addi  a0, zero, 1
    sw    a0, 0(t0)          # A[0,0] = 1
    addi  a0, zero, 2
    sw    a0, 4(t0)          # A[0,1] = 2
    addi  a0, zero, 3
    sw    a0, 8(t0)          # A[1,0] = 3
    addi  a0, zero, 4
    sw    a0, 12(t0)         # A[1,1] = 4

    addi  a1, zero, 5
    sw    a1, 0(t1)          # B[0,0] = 5
    addi  a1, zero, 6
    sw    a1, 4(t1)          # B[0,1] = 6
    addi  a1, zero, 7
    sw    a1, 8(t1)          # B[1,0] = 7
    addi  a1, zero, 8
    sw    a1, 12(t1)         # B[1,1] = 8

    #######################################
    # C[0,0] = A[0,0]*B[0,0] + A[0,1]*B[1,0]
    #######################################

    # -------- inner0: a3 = A[0,0]*B[0,0] --------
    lw    a0, 0(t0)          # A[0,0]
    lw    a1, 0(t1)          # B[0,0]
    addi  a3, zero, 0        # acc = 0

inner0_loop:
    beq   a1, zero, inner0_end
    add   a3, a3, a0
    addi  a1, a1, -1
    jal   x0, inner0_loop

inner0_end:
    # -------- inner1: a4 = A[0,1]*B[1,0] --------
    lw    a0, 4(t0)          # A[0,1]
    lw    a1, 8(t1)          # B[1,0]
    addi  a4, zero, 0        # acc2 = 0

inner1_loop:
    beq   a1, zero, inner1_end
    add   a4, a4, a0
    addi  a1, a1, -1
    jal   x0, inner1_loop

inner1_end:
    add   a3, a3, a4         # C[0,0] = a3 + a4
    sw    a3, 0(t2)

    #######################################
    # C[0,1] = A[0,0]*B[0,1] + A[0,1]*B[1,1]
    #######################################

    # inner2: A[0,0]*B[0,1]
    lw    a0, 0(t0)
    lw    a1, 4(t1)
    addi  a3, zero, 0

inner2_loop:
    beq   a1, zero, inner2_end
    add   a3, a3, a0
    addi  a1, a1, -1
    jal   x0, inner2_loop

inner2_end:
    # inner3: A[0,1]*B[1,1]
    lw    a0, 4(t0)
    lw    a1, 12(t1)
    addi  a4, zero, 0

inner3_loop:
    beq   a1, zero, inner3_end
    add   a4, a4, a0
    addi  a1, a1, -1
    jal   x0, inner3_loop

inner3_end:
    add   a3, a3, a4         # C[0,1]
    sw    a3, 4(t2)

    #######################################
    # C[1,0] = A[1,0]*B[0,0] + A[1,1]*B[1,0]
    #######################################

    # inner4: A[1,0]*B[0,0]
    lw    a0, 8(t0)
    lw    a1, 0(t1)
    addi  a3, zero, 0

inner4_loop:
    beq   a1, zero, inner4_end
    add   a3, a3, a0
    addi  a1, a1, -1
    jal   x0, inner4_loop

inner4_end:
    # inner5: A[1,1]*B[1,0]
    lw    a0, 12(t0)
    lw    a1, 8(t1)
    addi  a4, zero, 0

inner5_loop:
    beq   a1, zero, inner5_end
    add   a4, a4, a0
    addi  a1, a1, -1
    jal   x0, inner5_loop

inner5_end:
    add   a3, a3, a4
    sw    a3, 8(t2)

    #######################################
    # C[1,1] = A[1,0]*B[0,1] + A[1,1]*B[1,1]
    #######################################

    # inner6: A[1,0]*B[0,1]
    lw    a0, 8(t0)
    lw    a1, 4(t1)
    addi  a3, zero, 0

inner6_loop:
    beq   a1, zero, inner6_end
    add   a3, a3, a0
    addi  a1, a1, -1
    jal   x0, inner6_loop

inner6_end:
    # inner7: A[1,1]*B[1,1]
    lw    a0, 12(t0)
    lw    a1, 12(t1)
    addi  a4, zero, 0

inner7_loop:
    beq   a1, zero, inner7_end
    add   a4, a4, a0
    addi  a1, a1, -1
    jal   x0, inner7_loop

inner7_end:
    add   a3, a3, a4
    sw    a3, 12(t2)

done:
    jal   x0, done           # 停在這裡
