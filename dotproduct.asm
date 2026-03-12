# dot_product.asm (RV32I, no mul)
# A = [1,2,3,4], B = [5,6,7,8]
# result = 70 -> store at 0x1020

        lui   t0, 0x1         # t0 = 0x1000 (A base)
        addi  t1, t0, 16      # t1 = 0x1010 (B base)
        addi  t2, t0, 32      # t2 = 0x1020 (result addr)

# init A
        addi  a0, zero, 1
        sw    a0, 0(t0)
        addi  a0, zero, 2
        sw    a0, 4(t0)
        addi  a0, zero, 3
        sw    a0, 8(t0)
        addi  a0, zero, 4
        sw    a0, 12(t0)

# init B
        addi  a0, zero, 5
        sw    a0, 0(t1)
        addi  a0, zero, 6
        sw    a0, 4(t1)
        addi  a0, zero, 7
        sw    a0, 8(t1)
        addi  a0, zero, 8
        sw    a0, 12(t1)

# dot product
        addi  t3, zero, 4     # n = 4
        addi  a3, zero, 0     # sum = 0

loop_i:
        lw    a1, 0(t0)       # a1 = A[i]
        lw    a2, 0(t1)       # a2 = B[i]

        addi  a4, zero, 0     # prod = 0        memory[24] = 32'h00060793;
        addi  a5, a2, 0       # count = B[i]        memory[25] = 32'h00078863;

mul_loop:
        beq   a5, zero, mul_done
        add   a4, a4, a1      # prod += A[i]
        addi  a5, a5, -1
        jal   x0, mul_loop

mul_done:
        add   a3, a3, a4      # sum += prod

        addi  t0, t0, 4       # A++
        addi  t1, t1, 4       # B++
        addi  t3, t3, -1
        beq   t3, zero, done
        jal   x0, loop_i

done:
        sw    a3, 0(t2)       # store result (70)
        jal   x0, done
