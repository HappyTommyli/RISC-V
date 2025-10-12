import re

class RV32IAssembler:
    def __init__(self):
        # Register mapping
        self.registers = {
            'zero': 0, 'x0': 0,
            'ra': 1, 'x1': 1,
            'sp': 2, 'x2': 2,
            'gp': 3, 'x3': 3,
            'tp': 4, 'x4': 4,
            't0': 5, 'x5': 5, 't1': 6, 'x6': 6, 't2': 7, 'x7': 7,
            's0': 8, 'x8': 8, 'fp': 8, 's1': 9, 'x9': 9,
            'a0': 10, 'x10': 10, 'a1': 11, 'x11': 11, 
            'a2': 12, 'x12': 12, 'a3': 13, 'x13': 13,
            'a4': 14, 'x14': 14, 'a5': 15, 'x15': 15,
            'a6': 16, 'x16': 16, 'a7': 17, 'x17': 17,
            's2': 18, 'x18': 18, 's3': 19, 'x19': 19,
            's4': 20, 'x20': 20, 's5': 21, 'x21': 21,
            's6': 22, 'x22': 22, 's7': 23, 'x23': 23,
            's8': 24, 'x24': 24, 's9': 25, 'x25': 25,
            's10': 26, 'x26': 26, 's11': 27, 'x27': 27,
            't3': 28, 'x28': 28, 't4': 29, 'x29': 29,
            't5': 30, 'x30': 30, 't6': 31, 'x31': 31
        }
        
        # Instruction opcode mapping
        self.opcodes = {
            # U-type
            'lui': 0b0110111, 'auipc': 0b0010111,
            # J-type  
            'jal': 0b1101111,
            # I-type (JALR)
            'jalr': 0b1100111,
            # B-type
            'beq': 0b1100011, 'bne': 0b1100011, 'blt': 0b1100011, 
            'bge': 0b1100011, 'bltu': 0b1100011, 'bgeu': 0b1100011,
            # I-type (Load)
            'lb': 0b0000011, 'lh': 0b0000011, 'lw': 0b0000011, 
            'lbu': 0b0000011, 'lhu': 0b0000011,
            # S-type
            'sb': 0b0100011, 'sh': 0b0100011, 'sw': 0b0100011,
            # I-type (ALU)
            'addi': 0b0010011, 'slti': 0b0010011, 'sltiu': 0b0010011,
            'xori': 0b0010011, 'ori': 0b0010011, 'andi': 0b0010011,
            'slli': 0b0010011, 'srli': 0b0010011, 'srai': 0b0010011,
            # R-type
            'add': 0b0110011, 'sub': 0b0110011, 'sll': 0b0110011,
            'slt': 0b0110011, 'sltu': 0b0110011, 'xor': 0b0110011,
            'srl': 0b0110011, 'sra': 0b0110011, 'or': 0b0110011,
            'and': 0b0110011,
            # Fence
            'fence': 0b0001111, 'fence.i': 0b0001111,
            # System
            'ecall': 0b1110011, 'ebreak': 0b1110011,
            'csrrw': 0b1110011, 'csrrs': 0b1110011, 'csrrc': 0b1110011,
            'csrrwi': 0b1110011, 'csrrsi': 0b1110011, 'csrrci': 0b1110011
        }
        
        # funct3 mapping
        self.funct3 = {
            'jalr': 0b000,
            'beq': 0b000, 'bne': 0b001, 'blt': 0b100, 'bge': 0b101,
            'bltu': 0b110, 'bgeu': 0b111,
            'lb': 0b000, 'lh': 0b001, 'lw': 0b010, 'lbu': 0b100, 'lhu': 0b101,
            'sb': 0b000, 'sh': 0b001, 'sw': 0b010,
            'addi': 0b000, 'slti': 0b010, 'sltiu': 0b011, 'xori': 0b100,
            'ori': 0b110, 'andi': 0b111, 'slli': 0b001, 'srli': 0b101, 'srai': 0b101,
            'add': 0b000, 'sub': 0b000, 'sll': 0b001, 'slt': 0b010, 'sltu': 0b011,
            'xor': 0b100, 'srl': 0b101, 'sra': 0b101, 'or': 0b110, 'and': 0b111,
            'fence': 0b000, 'fence.i': 0b001,
            'ecall': 0b000, 'ebreak': 0b000,
            'csrrw': 0b001, 'csrrs': 0b010, 'csrrc': 0b011,
            'csrrwi': 0b101, 'csrrsi': 0b110, 'csrrci': 0b111
        }
        
        # funct7 mapping
        self.funct7 = {
            'slli': 0b0000000, 'srli': 0b0000000, 'srai': 0b0100000,
            'add': 0b0000000, 'sub': 0b0100000, 'sll': 0b0000000,
            'slt': 0b0000000, 'sltu': 0b0000000, 'xor': 0b0000000,
            'srl': 0b0000000, 'sra': 0b0100000, 'or': 0b0000000,
            'and': 0b0000000
        }
        
        # CSR register mapping
        self.csr_registers = {
            'mstatus': 0x300, 'mie': 0x304, 'mtvec': 0x305,
            'mepc': 0x341, 'mcause': 0x342, 'mtval': 0x343,
            'mip': 0x344, 'cycle': 0xC00, 'time': 0xC01,
            'instret': 0xC02, 'cycleh': 0xC80, 'timeh': 0xC81,
            'instreth': 0xC82
        }

    def parse_register(self, reg_str):
        """Parse register name or number"""
        reg_str = reg_str.strip().lower()
        if reg_str in self.registers:
            return self.registers[reg_str]
        elif reg_str.startswith('x'):
            try:
                reg_num = int(reg_str[1:])
                if 0 <= reg_num <= 31:
                    return reg_num
            except ValueError:
                pass
        raise ValueError(f"Invalid register: {reg_str}")

    def parse_immediate(self, imm_str):
        """Parse immediate value, support decimal and hexadecimal"""
        imm_str = imm_str.strip()
        try:
            if imm_str.startswith('0x') or imm_str.startswith('-0x'):
                return int(imm_str, 16)
            else:
                return int(imm_str, 10)
        except ValueError:
            raise ValueError(f"Invalid immediate: {imm_str}")

    def parse_csr(self, csr_str):
        """Parse CSR register"""
        csr_str = csr_str.strip().lower()
        if csr_str in self.csr_registers:
            return self.csr_registers[csr_str]
        elif csr_str.startswith('0x'):
            return int(csr_str, 16)
        else:
            try:
                return int(csr_str)
            except ValueError:
                raise ValueError(f"Invalid CSR register: {csr_str}")

    def encode_r_type(self, instruction, rd, rs1, rs2):
        """Encode R-type instruction"""
        opcode = self.opcodes[instruction]
        funct3 = self.funct3[instruction]
        funct7 = self.funct7[instruction]
        
        machine_code = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
        return machine_code

    def encode_i_type(self, instruction, rd, rs1, imm):
        """Encode I-type instruction"""
        opcode = self.opcodes[instruction]
        funct3 = self.funct3[instruction]
        
        # Sign extend immediate to 12 bits
        imm_12 = imm & 0xFFF
        if imm < 0:
            imm_12 = (abs(imm) ^ 0xFFF) + 1  # Two's complement
            
        machine_code = (imm_12 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
        return machine_code

    def encode_s_type(self, instruction, rs2, rs1, imm):
        """Encode S-type instruction"""
        opcode = self.opcodes[instruction]
        funct3 = self.funct3[instruction]
        
        imm_12 = imm & 0xFFF
        if imm < 0:
            imm_12 = (abs(imm) ^ 0xFFF) + 1
            
        imm_11_5 = (imm_12 >> 5) & 0x7F
        imm_4_0 = imm_12 & 0x1F
        
        machine_code = (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode
        return machine_code

    def encode_b_type(self, instruction, rs1, rs2, imm):
        """Encode B-type instruction"""
        opcode = self.opcodes[instruction]
        funct3 = self.funct3[instruction]
        
        # B-type immediate is 13-bit signed and 2-byte aligned
        if imm % 2 != 0:
            raise ValueError(f"B-type instruction immediate must be 2-byte aligned: {imm}")
            
        imm_13 = imm & 0x1FFF
        if imm < 0:
            imm_13 = (abs(imm) ^ 0x1FFF) + 1
            
        # B-type immediate encoding is special
        imm_12 = (imm_13 >> 12) & 0x1
        imm_11 = (imm_13 >> 11) & 0x1
        imm_10_5 = (imm_13 >> 5) & 0x3F
        imm_4_1 = (imm_13 >> 1) & 0xF
        
        machine_code = (imm_12 << 31) | (imm_11 << 30) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_1 << 8) | opcode
        return machine_code

    def encode_u_type(self, instruction, rd, imm):
        """Encode U-type instruction"""
        opcode = self.opcodes[instruction]
        
        # U-type immediate is 20 bits, placed in high 20 bits
        imm_20 = (imm >> 12) & 0xFFFFF
        
        machine_code = (imm_20 << 12) | (rd << 7) | opcode
        return machine_code

    def encode_j_type(self, instruction, rd, imm):
        """Encode J-type instruction"""
        opcode = self.opcodes[instruction]
        
        # J-type immediate is 21-bit signed and 2-byte aligned
        if imm % 2 != 0:
            raise ValueError(f"J-type instruction immediate must be 2-byte aligned: {imm}")
            
        imm_21 = imm & 0x1FFFFF
        if imm < 0:
            imm_21 = (abs(imm) ^ 0x1FFFFF) + 1
            
        # J-type immediate encoding
        imm_20 = (imm_21 >> 20) & 0x1
        imm_19_12 = (imm_21 >> 12) & 0xFF
        imm_11 = (imm_21 >> 11) & 0x1
        imm_10_1 = (imm_21 >> 1) & 0x3FF
        
        machine_code = (imm_20 << 31) | (imm_19_12 << 12) | (imm_11 << 20) | (imm_10_1 << 21) | (rd << 7) | opcode
        return machine_code

    def encode_fence(self, pred, succ):
        """Encode FENCE instruction"""
        opcode = self.opcodes['fence']
        funct3 = self.funct3['fence']
        
        # Parse pred and succ bit masks
        pred_val = self.parse_fence_mask(pred)
        succ_val = self.parse_fence_mask(succ)
        
        imm_12 = (pred_val << 4) | succ_val
        
        machine_code = (imm_12 << 20) | (funct3 << 12) | opcode
        return machine_code

    def parse_fence_mask(self, mask_str):
        """Parse FENCE instruction bit mask"""
        mask_str = mask_str.strip().lower()
        value = 0
        for char in mask_str:
            if char == 'i': value |= 0b1000
            elif char == 'o': value |= 0b0100
            elif char == 'r': value |= 0b0010
            elif char == 'w': value |= 0b0001
            else:
                raise ValueError(f"Invalid FENCE mask character: {char}")
        return value

    def encode_csr(self, instruction, rd, csr, rs1):
        """Encode CSR instruction"""
        opcode = self.opcodes[instruction]
        funct3 = self.funct3[instruction]
        
        machine_code = (csr << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
        return machine_code

    def encode_csr_imm(self, instruction, rd, csr, imm):
        """Encode CSR immediate instruction"""
        opcode = self.opcodes[instruction]
        funct3 = self.funct3[instruction]
        
        machine_code = (csr << 20) | (imm << 15) | (funct3 << 12) | (rd << 7) | opcode
        return machine_code

    def assemble_instruction(self, line):
        """Assemble single instruction"""
        # Remove comments and extra spaces
        line = re.sub(r'#.*$', '', line).strip()
        if not line:
            return None
            
        # Split instruction and operands
        parts = re.split(r'[,\s]+', line)
        instruction = parts[0].lower()
        operands = [op for op in parts[1:] if op]
        
        try:
            # U-type instructions
            if instruction == 'lui' or instruction == 'auipc':
                rd = self.parse_register(operands[0])
                imm = self.parse_immediate(operands[1])
                return self.encode_u_type(instruction, rd, imm)
                
            # J-type instructions
            elif instruction == 'jal':
                rd = self.parse_register(operands[0])
                imm = self.parse_immediate(operands[1])
                return self.encode_j_type(instruction, rd, imm)
                
            # I-type instructions (JALR)
            elif instruction == 'jalr':
                if len(operands) == 2:
                    # jalr rd, offset(rs1) format
                    rd = self.parse_register(operands[0])
                    match = re.match(r'(-?\w+)\((\w+)\)', operands[1])
                    if match:
                        imm = self.parse_immediate(match.group(1))
                        rs1 = self.parse_register(match.group(2))
                    else:
                        raise ValueError(f"Invalid JALR instruction format: {operands[1]}")
                else:
                    # jalr rd, rs1, imm format
                    rd = self.parse_register(operands[0])
                    rs1 = self.parse_register(operands[1])
                    imm = self.parse_immediate(operands[2])
                return self.encode_i_type(instruction, rd, rs1, imm)
                
            # B-type instructions
            elif instruction in ['beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu']:
                rs1 = self.parse_register(operands[0])
                rs2 = self.parse_register(operands[1])
                imm = self.parse_immediate(operands[2])
                return self.encode_b_type(instruction, rs1, rs2, imm)
                
            # Load instructions (I-type)
            elif instruction in ['lb', 'lh', 'lw', 'lbu', 'lhu']:
                rd = self.parse_register(operands[0])
                match = re.match(r'(-?\w+)\((\w+)\)', operands[1])
                if match:
                    imm = self.parse_immediate(match.group(1))
                    rs1 = self.parse_register(match.group(2))
                else:
                    raise ValueError(f"Invalid load instruction format: {operands[1]}")
                return self.encode_i_type(instruction, rd, rs1, imm)
                
            # Store instructions (S-type)
            elif instruction in ['sb', 'sh', 'sw']:
                rs2 = self.parse_register(operands[0])
                match = re.match(r'(-?\w+)\((\w+)\)', operands[1])
                if match:
                    imm = self.parse_immediate(match.group(1))
                    rs1 = self.parse_register(match.group(2))
                else:
                    raise ValueError(f"Invalid store instruction format: {operands[1]}")
                return self.encode_s_type(instruction, rs2, rs1, imm)
                
            # Immediate ALU instructions (I-type)
            elif instruction in ['addi', 'slti', 'sltiu', 'xori', 'ori', 'andi']:
                rd = self.parse_register(operands[0])
                rs1 = self.parse_register(operands[1])
                imm = self.parse_immediate(operands[2])
                return self.encode_i_type(instruction, rd, rs1, imm)
                
            # Shift instructions (I-type)
            elif instruction in ['slli', 'srli', 'srai']:
                rd = self.parse_register(operands[0])
                rs1 = self.parse_register(operands[1])
                imm = self.parse_immediate(operands[2])
                # Check shift amount range
                if imm < 0 or imm > 31:
                    raise ValueError(f"Shift amount must be in range 0-31: {imm}")
                return self.encode_i_type(instruction, rd, rs1, imm)
                
            # R-type ALU instructions
            elif instruction in ['add', 'sub', 'sll', 'slt', 'sltu', 'xor', 'srl', 'sra', 'or', 'and']:
                rd = self.parse_register(operands[0])
                rs1 = self.parse_register(operands[1])
                rs2 = self.parse_register(operands[2])
                return self.encode_r_type(instruction, rd, rs1, rs2)
                
            # FENCE instructions
            elif instruction == 'fence':
                pred = operands[0] if len(operands) > 0 else 'iorw'
                succ = operands[1] if len(operands) > 1 else 'iorw'
                return self.encode_fence(pred, succ)
                
            # FENCE.I instruction
            elif instruction == 'fence.i':
                return self.encode_i_type(instruction, 0, 0, 0)  # Register fields are 0
                
            # System instructions
            elif instruction == 'ecall':
                return 0x00000073  # Fixed encoding
                
            elif instruction == 'ebreak':
                return 0x00100073  # Fixed encoding
                
            # CSR instructions
            elif instruction in ['csrrw', 'csrrs', 'csrrc']:
                rd = self.parse_register(operands[0])
                csr = self.parse_csr(operands[1])
                rs1 = self.parse_register(operands[2])
                return self.encode_csr(instruction, rd, csr, rs1)
                
            elif instruction in ['csrrwi', 'csrrsi', 'csrrci']:
                rd = self.parse_register(operands[0])
                csr = self.parse_csr(operands[1])
                imm = self.parse_immediate(operands[2])
                if imm < 0 or imm > 31:
                    raise ValueError(f"CSR immediate must be in range 0-31: {imm}")
                return self.encode_csr_imm(instruction, rd, csr, imm)
                
            else:
                raise ValueError(f"Unsupported instruction: {instruction}")
                
        except Exception as e:
            raise ValueError(f"Assembly error: {line} - {str(e)}")

    def assemble_file(self, input_file, output_file):
        """Assemble entire file"""
        machine_codes = []
        
        with open(input_file, 'r') as f:
            lines = f.readlines()
            
        print("RV32I Assembly Process:")
        print("=" * 60)
        
        for line_num, line in enumerate(lines, 1):
            try:
                machine_code = self.assemble_instruction(line)
                if machine_code is not None:
                    machine_codes.append(machine_code)
                    print(f"Line {line_num:2d}: {line.strip():40} -> 0x{machine_code:08x}")
            except ValueError as e:
                print(f"Error at line {line_num}: {str(e)}")
                return False
                
        # Write output file
        with open(output_file, 'w') as f:
            for code in machine_codes:
                f.write(f"{code:032b}\n")  # Write 32-bit binary format
                
        print("=" * 60)
        print(f"Assembly completed! Generated {len(machine_codes)} instructions")
        print(f"Machine code saved to: {output_file}")
        
        # Show output file preview
        print("\nOutput file preview (first 10 lines):")
        with open(output_file, 'r') as f:
            for i, line in enumerate(f.readlines()[:10]):
                print(f"{i:2d}: {line.strip()}")
                
        return True

def create_sample_asm():
    """Create sample file with all RV32I instructions"""
    sample_asm = """# RV32I Complete Instruction Set Example
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
csrrci x16, mtval, 15"""
    
    with open("rv32i_complete.asm", "w") as f:
        f.write(sample_asm)
    
    return "rv32i_complete.asm"

def create_simple_program():
    """Create a simple test program"""
    simple_asm = """# Simple RV32I Test Program
addi x1, x0, 10      # x1 = 10
addi x2, x0, 20      # x2 = 20
add x3, x1, x2       # x3 = x1 + x2
sw x3, 0(x0)         # Store result to memory address 0
lw x4, 0(x0)         # Load from memory to x4
beq x3, x4, 8        # If equal, jump to next instruction
addi x5, x0, 1       # This line will be skipped
addi x6, x0, 99      # x6 = 99"""
    
    with open("simple_test.asm", "w") as f:
        f.write(simple_asm)
    
    return "simple_test.asm"

def main():
    assembler = RV32IAssembler()
    
    print("RV32I Complete Assembler")
    print("Supports all 47 RV32I base instructions")
    print("=" * 50)
    
    # Create sample files
    complete_filename = create_sample_asm()
    simple_filename = create_simple_program()
    
    print(f"Created sample assembly files:")
    print(f"  - {complete_filename} (complete instruction set)")
    print(f"  - {simple_filename} (simple test program)")
    print()
    
    # Ask user which file to assemble
    while True:
        choice = input("Which file would you like to assemble? (1=complete, 2=simple, 3=custom): ").strip()
        
        if choice == '1':
            input_file = complete_filename
            output_file = "rv32i_complete_machine_code.txt"
            break
        elif choice == '2':
            input_file = simple_filename
            output_file = "simple_test_machine_code.txt"
            break
        elif choice == '3':
            input_file = input("Enter custom input filename: ").strip()
            output_file = input("Enter output filename: ").strip()
            break
        else:
            print("Invalid choice. Please enter 1, 2, or 3.")
    
    print(f"\nAssembling: {input_file}")
    print(f"Output: {output_file}")
    print()
    
    # Perform assembly
    try:
        success = assembler.assemble_file(input_file, output_file)
        
        if success:
            print(f"\nComplete machine code saved to: {output_file}")
            print("Format: Each line contains 32-bit binary machine code")
        else:
            print("\nAssembly failed due to errors.")
            
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found.")
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
    
    return success

if __name__ == "__main__":
    main()