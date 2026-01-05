    lui t0, 0x1      # 0x0: t0 = 0x1000 
    addi t0, t0, 0   # 0x4
    lui t1, 0x1      # 0x8: t1 = 0x1010 
    addi t1, t1, 16  # 0xc
    lui t2, 0x1      # 0x10: t2 = 0x1020 
    addi t2, t2, 32  # 0x14

    addi a0, zero, 1  # 0x18: a0 = 1
    sw a0, 0(t0)      # 0x1c
    addi a0, zero, 2  # 0x20: a0 = 2
    sw a0, 4(t0)      # 0x24
    addi a0, zero, 3  # 0x28: a0 = 3
    sw a0, 8(t0)      # 0x2c
    addi a0, zero, 4  # 0x30: a0 = 4
    sw a0, 12(t0)     # 0x34

    addi a1, zero, 5  # 0x38: a1 = 5
    sw a1, 0(t1)      # 0x3c
    addi a1, zero, 6  # 0x40: a1 = 6
    sw a1, 4(t1)      # 0x44
    addi a1, zero, 7  # 0x48: a1 = 7
    sw a1, 8(t1)      # 0x4c
    addi a1, zero, 8  # 0x50: a1 = 8
    sw a1, 12(t1)     # 0x54

    lw a0, 0(t0)      # 0x58: a0 = A[0,0]
    lw a1, 0(t1)      # 0x5c: a1 = B[0,0]
    addi a3, zero, 0  # 0x60: a3 = 結果 0
    beq a1, zero, 8   # 0x64: if a1==0 跳 +8 bytes (2 instr)
    add a3, a3, a0    # 0x68
    addi a1, a1, -1   # 0x6c
    jal x0, -12       # 0x70: 跳 -12 bytes (-3 instr，回 0x64)
    lw a0, 4(t0)      # 0x74: a0 = A[0,1]
    lw a1, 8(t1)      # 0x78: a1 = B[1,0]
    addi a4, zero, 0  # 0x7c: a4 = 結果 0
    beq a1, zero, 8   # 0x80: 跳 +8
    add a4, a4, a0    # 0x84
    addi a1, a1, -1   # 0x88
    jal x0, -12       # 0x8c: 跳 -12 (回 0x80)
    add a3, a3, a4    # 0x90
    sw a3, 0(t2)      # 0x94

    lw a0, 0(t0)      # 0x98: a0 = A[0,0]
    lw a1, 4(t1)      # 0x9c: a1 = B[0,1]
    addi a3, zero, 0  # 0xa0
    beq a1, zero, 8   # 0xa4: 跳 +8
    add a3, a3, a0    # 0xa8
    addi a1, a1, -1   # 0xac
    jal x0, -12       # 0xb0: 跳 -12 (回 0xa4)
    lw a0, 4(t0)      # 0xb4: a0 = A[0,1]
    lw a1, 12(t1)     # 0xb8: a1 = B[1,1]
    addi a4, zero, 0  # 0xbc
    beq a1, zero, 8   # 0xc0: 跳 +8
    add a4, a4, a0    # 0xc4
    addi a1, a1, -1   # 0xc8
    jal x0, -12       # 0xcc: 跳 -12 (回 0xc0)
    add a3, a3, a4    # 0xd0
    sw a3, 4(t2)      # 0xd4

    lw a0, 8(t0)      # 0xd8: a0 = A[1,0]
    lw a1, 0(t1)      # 0xdc: a1 = B[0,0]
    addi a3, zero, 0  # 0xe0
    beq a1, zero, 8   # 0xe4: 跳 +8
    add a3, a3, a0    # 0xe8
    addi a1, a1, -1   # 0xec
    jal x0, -12       # 0xf0: 跳 -12 (回 0xe4)
    lw a0, 12(t0)     # 0xf4: a0 = A[1,1]
    lw a1, 8(t1)      # 0xf8: a1 = B[1,0]
    addi a4, zero, 0  # 0xfc
    beq a1, zero, 8   # 0x100: 跳 +8
    add a4, a4, a0    # 0x104
    addi a1, a1, -1   # 0x108
    jal x0, -12       # 0x10c: 跳 -12 (回 0x100)
    add a3, a3, a4    # 0x110
    sw a3, 8(t2)      # 0x114

    lw a0, 8(t0)      # 0x118: a0 = A[1,0]
    lw a1, 4(t1)      # 0x11c: a1 = B[0,1]
    addi a3, zero, 0  # 0x120
    beq a1, zero, 8   # 0x124: 跳 +8
    add a3, a3, a0    # 0x128
    addi a1, a1, -1   # 0x12c
    jal x0, -12       # 0x130: 跳 -12 (回 0x124)
    lw a0, 12(t0)     # 0x134: a0 = A[1,1]
    lw a1, 12(t1)     # 0x138: a1 = B[1,1]
    addi a4, zero, 0  # 0x13c
    beq a1, zero, 8   # 0x140: 跳 +8
    add a4, a4, a0    # 0x144
    addi a1, a1, -1   # 0x148
    jal x0, -12       # 0x14c: 跳 -12 (回 0x140)
    add a3, a3, a4    # 0x150
    sw a3, 12(t2)     # 0x154

    jal x0, 0         # 0x158: 結束死迴圈 (offset 0 = 跳自己)
