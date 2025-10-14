# Example RV32I instructions (no pseudoinstructions)
addi    x20, x0, -16     # Load -16 into x20 using addi (replaces li)
srai    x18, x20, 3      # Arithmetic shift right, verify funct7=0100000
add     x5, x18, x20     # Addition operation
sw      x5, 0(x2)        # Store result
