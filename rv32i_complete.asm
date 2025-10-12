# RV32I Complete Instruction Set Example
# Load immediate instructions
lui x1, 0x12345
auipc x2, 0x1000

# Jump instructions
jal x3, 2048
jalr x4, x1, 16

# Conditional branch instructions
beq x5, x6, -16
bne x7, x8, 32
blt x9, x10, -64
bge x11, x12, 128
bltu x13, x14, -256
bgeu x15, x16, 512

# Load instructions
lb x17, 0(x1)
lh x18, 4(x2)
lw x19, 8(x3)
lbu x20, 12(x4)
lhu x21, 16(x5)

# Store instructions
sb x6, 0(x7)
sh x8, 4(x9)
sw x10, 8(x11)

# Immediate arithmetic instructions
addi x22, x23, 42
slti x24, x25, -10
sltiu x26, x27, 100
xori x28, x29, 0xFF
ori x30, x31, 0x0F
andi x1, x2, 0x55

# Shift instructions
slli x3, x4, 3
srli x5, x6, 5
srai x7, x8, 7

# Register arithmetic instructions
add x9, x10, x11
sub x12, x13, x14
sll x15, x16, x17
slt x18, x19, x20
sltu x21, x22, x23
xor x24, x25, x26
srl x27, x28, x29
sra x30, x31, x1
or x2, x3, x4
and x5, x6, x7

# Fence instructions
fence iorw, iorw
fence.i

# System instructions
ecall
ebreak

# CSR instructions
csrrw x8, mstatus, x9
csrrs x10, mie, x11
csrrc x12, mtvec, x13
csrrwi x14, mepc, 5
csrrsi x15, mcause, 10
csrrci x16, mtval, 15