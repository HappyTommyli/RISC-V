# Unified RV32I single-cycle test (labels supported)
# PASS: x31 = 1, FAIL: x31 = 255

start:
    addi x1, x0, 10        # x1 = 10
    addi x2, x0, 5         # x2 = 5
    add  x3, x1, x2        # x3 = 15
    sub  x4, x1, x2        # x4 = 5
    slli x5, x2, 2         # x5 = 20
    srli x6, x5, 1         # x6 = 10
    addi x7, x0, -1        # x7 = 0xFFFFFFFF
    srai x8, x7, 1         # x8 = 0xFFFFFFFF
    slt  x9, x2, x1        # x9 = 1
    sltu x10, x7, x0       # x10 = 0
    xor  x11, x1, x2       # x11 = 15
    or   x12, x1, x2       # x12 = 15
    and  x13, x1, x2       # x13 = 0

    # Data memory base = 0x100
    lui  x5, 0x0
    addi x5, x5, 0x100     # x5 = 0x100

    sw   x1, 0(x5)         # [0x100] = 10
    sh   x2, 4(x5)         # [0x104] = 5
    sb   x2, 6(x5)         # [0x106] = 5
    lw   x14, 0(x5)        # x14 = 10
    lh   x15, 4(x5)        # x15 = 5
    lhu  x16, 4(x5)        # x16 = 5
    lb   x17, 6(x5)        # x17 = 5
    lbu  x18, 6(x5)        # x18 = 5

    # Branch tests
    beq  x1, x1, br_ok1
    jal  x0, fail
br_ok1:
    bne  x1, x2, br_ok2
    jal  x0, fail
br_ok2:
    blt  x2, x1, br_ok3
    jal  x0, fail
br_ok3:
    bge  x1, x2, br_ok4
    jal  x0, fail
br_ok4:
    bltu x2, x1, br_ok5
    jal  x0, fail
br_ok5:
    bgeu x1, x2, br_ok6
    jal  x0, fail
br_ok6:

    # JAL / JALR tests
    jal  x21, subroutine
    addi x22, x0, 77       # should execute after return
    jal  x0, done

subroutine:
    addi x23, x0, 1
    jalr x0, 0(x21)        # return

done:
    addi x31, x0, 1        # PASS
    jal  x0, done          # loop here

fail:
    addi x31, x0, 255      # FAIL
    jal  x0, fail          # loop here
