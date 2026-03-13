    # 8x8 Matrix Multiply (Stress Test)
    # A = [1..64], B = A, C = A * B

    # Base addresses
    lui t0, 0x1          # t0 = 0x1000 (A)
    addi t0, t0, 0x0
    lui t1, 0x1          # t1 = 0x1100 (B)
    addi t1, t1, 0x100
    lui t2, 0x1          # t2 = 0x1200 (C)
    addi t2, t2, 0x200

    # Init A with 1..64
    addi t3, zero, 64
    addi a0, zero, 1
init_A:
    sw a0, 0(t0)
    addi t0, t0, 4
    addi a0, a0, 1
    addi t3, t3, -1
    bne t3, zero, init_A

    # Reset A base
    lui t0, 0x1
    addi t0, t0, 0x0

    # Copy A -> B
    lui t1, 0x1
    addi t1, t1, 0x100
    addi t3, zero, 64
copy_A_to_B:
    lw a0, 0(t0)
    sw a0, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t3, t3, -1
    bne t3, zero, copy_A_to_B

    # Reset bases
    lui t0, 0x1
    addi t0, t0, 0x0
    lui t1, 0x1
    addi t1, t1, 0x100
    lui t2, 0x1
    addi t2, t2, 0x200

    # C = A * B
    addi s3, zero, 8     # const 8
    addi s0, zero, 0     # i = 0
loop_i:
    slli t6, s0, 5       # i * 32
    add t3, t0, t6       # row_ptr_A
    add t4, t2, t6       # row_ptr_C
    addi s1, zero, 0     # j = 0
loop_j:
    addi a4, zero, 0     # sum = 0
    addi a2, t3, 0       # A_ptr
    slli t5, s1, 2
    add a3, t1, t5       # B_ptr (col j)
    addi s2, zero, 8     # k = 8
loop_k:
    lw a0, 0(a2)         # A[i][k]
    lw a1, 0(a3)         # B[k][j]
    addi a6, zero, 0     # product = 0
    addi a5, a1, 0       # counter = B
mul_loop:
    beq a5, zero, mul_done
    add a6, a6, a0
    addi a5, a5, -1
    jal x0, mul_loop
mul_done:
    add a4, a4, a6       # sum += product
    addi a2, a2, 4       # A_ptr++
    addi a3, a3, 32      # B_ptr += 8*4
    addi s2, s2, -1
    bne s2, zero, loop_k

    slli t5, s1, 2
    add t6, t4, t5
    sw a4, 0(t6)         # C[i][j] = sum

    addi s1, s1, 1
    bne s1, s3, loop_j
    addi s0, s0, 1
    bne s0, s3, loop_i

done:
    jal x0, done
