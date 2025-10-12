# Simple RV32I Test Program
addi x1, x0, 10      # x1 = 10
addi x2, x0, 20      # x2 = 20
add x3, x1, x2       # x3 = x1 + x2
sw x3, 0(x0)         # Store result to memory address 0
lw x4, 0(x0)         # Load from memory to x4
beq x3, x4, 8        # If equal, jump to next instruction
addi x5, x0, 1       # This line will be skipped
addi x6, x0, 99      # x6 = 99