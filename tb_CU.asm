# =====================================================
# =====================================================

# =====================================================
# Group 1: R-type instructions (10)
# Opcode: 0110011
# =====================================================

# 1. ADD rd, rs1, rs2 → ADD x1, x2, x3
# Machine Code: 0x003100B3
add x1, x2, x3

# 2. SUB rd, rs1, rs2 → SUB x1, x2, x3  
# Machine Code: 0x403100B3
sub x1, x2, x3

# 3. SLL rd, rs1, rs2 → SLL x1, x2, x3
# Machine Code: 0x003110B3
sll x1, x2, x3

# 4. SLT rd, rs1, rs2 → SLT x1, x2, x3
# Machine Code: 0x003120B3
slt x1, x2, x3

# 5. SLTU rd, rs1, rs2 → SLTU x1, x2, x3
# Machine Code: 0x003130B3
sltu x1, x2, x3

# 6. XOR rd, rs1, rs2 → XOR x1, x2, x3
# Machine Code: 0x003140B3
xor x1, x2, x3

# 7. SRL rd, rs1, rs2 → SRL x1, x2, x3
# Machine Code: 0x003150B3
srl x1, x2, x3

# 8. SRA rd, rs1, rs2 → SRA x1, x2, x3
# Machine Code: 0x403150B3
sra x1, x2, x3

# 9. OR rd, rs1, rs2 → OR x1, x2, x3
# Machine Code: 0x003160B3
or x1, x2, x3

# 10. AND rd, rs1, rs2 → AND x1, x2, x3
# Machine Code: 0x003170B3
and x1, x2, x3


# =====================================================
# Group 2: I-type instructions (Arithmetic/Shift) - 9
# Opcode: 0010011
# =====================================================

# 11. ADDI rd, rs1, imm → ADDI x1, x2, 4
# Machine Code: 
addi x1, x2, 4

# 12. SLTI rd, rs1, imm → SLTI x1, x2, 4
# Machine Code:
slti x1, x2, 4

# 13. SLTIU rd, rs1, imm → SLTIU x1, x2, 4
# Machine Code: 
sltiu x1, x2, 4

# 14. XORI rd, rs1, imm → XORI x1, x2, 4
# Machine Code: 
xori x1, x2, 4

# 15. ORI rd, rs1, imm → ORI x1, x2, 4
# Machine Code: 
ori x1, x2, 4

# 16. ANDI rd, rs1, imm → ANDI x1, x2, 4
# Machine Code: 
andi x1, x2, 4

# 17. SLLI rd, rs1, imm → SLLI x1, x2, 4
# Machine Code: 
slli x1, x2, 4

# 18. SRLI rd, rs1, imm → SRLI x1, x2, 4
# Machine Code: 
srli x1, x2, 4

# 19. SRAI rd, rs1, imm → SRAI x1, x2, 4
# Machine Code: 
srai x1, x2, 4


# =====================================================
# Group 3: Load instructions - 5
# Opcode: 0000011
# =====================================================

# 20. LB rd, imm(rs1) → LB x1, 4(x2)
# Machine Code: 
lb x1, 4(x2)

# 21. LH rd, imm(rs1) → LH x1, 4(x2)
# Machine Code: 
lh x1, 4(x2)

# 22. LW rd, imm(rs1) → LW x1, 4(x2)
# Machine Code: 
lw x1, 4(x2)

# 23. LBU rd, imm(rs1) → LBU x1, 4(x2)
# Machine Code: 
lbu x1, 4(x2)

# 24. LHU rd, imm(rs1) → LHU x1, 4(x2)
# Machine Code: 
lhu x1, 4(x2)


# =====================================================
# Group 4: Store instructions - 3
# Opcode: 0100011
# =====================================================

# 25. SB rs2, imm(rs1) → SB x3, 4(x2)
# Machine Code: 
sb x3, 4(x2)

# 26. SH rs2, imm(rs1) → SH x3, 4(x2)
# Machine Code: 
sh x3, 4(x2)

# 27. SW rs2, imm(rs1) → SW x3, 4(x2)
# Machine Code: 
sw x3, 4(x2)


# =====================================================
# Group 5: B-type instructions - 6
# Opcode: 1100011
# =====================================================

# 28. BEQ rs1, rs2, imm → BEQ x2, x3, 4
# Machine Code: 
beq x2, x3, 4

# 29. BNE rs1, rs2, imm → BNE x2, x3, 4
# Machine Code: 
bne x2, x3, 4

# 30. BLT rs1, rs2, imm → BLT x2, x3, 4
# Machine Code: 
blt x2, x3, 4

# 31. BGE rs1, rs2, imm → BGE x2, x3, 4
# Machine Code: 
bge x2, x3, 4

# 32. BLTU rs1, rs2, imm → BLTU x2, x3, 4
# Machine Code: 
bltu x2, x3, 4

# 33. BGEU rs1, rs2, imm → BGEU x2, x3, 4
# Machine Code:
bgeu x2, x3, 4


# =====================================================
# Group 6: Jump instructions - 2
# =====================================================

# 34. JAL rd, imm → JAL x1, 4
# Machine Code: 
jal x1, 4

# 35. JALR rd, imm(rs1) → JALR x1, 4(x2)
# Machine Code: 
jalr x1, 4(x2)


# =====================================================
# Group 7: Barrier instructions - 2
# Opcode: 0001111
# =====================================================

# 36. FENCE → FENCE
# Machine Code: 0x0000000F
fence

# 37. FENCE.I → FENCE.I
# Machine Code: 0x0000100F
fence.i


# =====================================================
# Group 8: Upper instructions - 2
# =====================================================

# 38. LUI rd, imm → LUI x1, 4
# Machine Code:
lui x1, 4

# 39. AUIPC rd, imm → AUIPC x1, 4
# Machine Code: 
auipc x1, 4


# =====================================================
# Group 9: SYSTEM instructions - 8
# Opcode: 1110011
# =====================================================

# 40. ECALL → ECALL
# Machine Code: 0x00000073
ecall

# 41. EBREAK → EBREAK
# Machine Code: 0x00100073
ebreak

# 42. CSRRW rd, csr, rs1 → CSRRW x1, 0x123, x2
# Machine Code: 0x12320073
csrrw x1, 0x123, x2

# 43. CSRRS rd, csr, rs1 → CSRRS x1, 0x123, x2
# Machine Code: 0x12311073
csrrs x1, 0x123, x2

# 44. CSRRC rd, csr, rs1 → CSRRC x1, 0x123, x2
# Machine Code: 0x12312073
csrrc x1, 0x123, x2

# 45. CSRRWI rd, csr, imm → CSRRWI x1, 0x123, 5
# Machine Code: 0x1232D0F3
csrrwi x1, 0x123, 5

# 46. CSRRSI rd, csr, imm → CSRRSI x1, 0x123, 5
# Machine Code: 0x1232E0F3
csrrsi x1, 0x123, 5

# 47. CSRRCI rd, csr, imm → CSRRCI x1, 0x123, 5
# Machine Code: 0x1232F0F3
csrrci x1, 0x123, 5

# =====================================================
# End of tb_CU.asm - 47 RV32I Instructions 
# =====================================================