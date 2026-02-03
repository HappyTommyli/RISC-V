import re
import os

class RV32IAssembler:
    def __init__(self):
        # Register mapping (standard aliases and x0-x31)
        self.registers = {
            'zero': 0, 'x0': 0,
            'ra': 1, 'x1': 1, 'sp': 2, 'x2': 2, 'gp': 3, 'x3': 3, 'tp': 4, 'x4': 4,
            't0': 5, 'x5': 5, 't1': 6, 'x6': 6, 't2': 7, 'x7': 7,
            's0': 8, 'x8': 8, 'fp': 8, 's1': 9, 'x9': 9,
            'a0': 10, 'x10': 10, 'a1': 11, 'x11': 11, 'a2': 12, 'x12': 12, 'a3': 13, 'x13': 13,
            'a4': 14, 'x14': 14, 'a5': 15, 'x15': 15, 'a6': 16, 'x16': 16, 'a7': 17, 'x17': 17,
            's2': 18, 'x18': 18, 's3': 19, 'x19': 19, 's4': 20, 'x20': 20, 's5': 21, 'x21': 21,
            's6': 22, 'x22': 22, 's7': 23, 'x23': 23, 's8': 24, 'x24': 24, 's9': 25, 'x25': 25,
            's10': 26, 'x26': 26, 's11': 27, 'x27': 27, 't3': 28, 'x28': 28, 't4': 29, 'x29': 29,
            't5': 30, 'x30': 30, 't6': 31, 'x31': 31
        }

        # Standard RV32I instruction opcode mapping (no pseudoinstructions)
        self.opcodes = {
            'lui': 0b0110111, 'auipc': 0b0010111,
            'jal': 0b1101111,
            'jalr': 0b1100111,
            'lb': 0b0000011, 'lh': 0b0000011, 'lw': 0b0000011, 'lbu': 0b0000011, 'lhu': 0b0000011,
            'addi': 0b0010011, 'slti': 0b0010011, 'sltiu': 0b0010011, 'xori': 0b0010011, 'ori': 0b0010011, 'andi': 0b0010011,
            'slli': 0b0010011, 'srli': 0b0010011, 'srai': 0b0010011, 'fence.i': 0b0001111,
            'beq': 0b1100011, 'bne': 0b1100011, 'blt': 0b1100011, 'bge': 0b1100011, 'bltu': 0b1100011, 'bgeu': 0b1100011,
            'sb': 0b0100011, 'sh': 0b0100011, 'sw': 0b0100011,
            'add': 0b0110011, 'sub': 0b0110011, 'sll': 0b0110011, 'slt': 0b0110011, 'sltu': 0b0110011,
            'xor': 0b0110011, 'srl': 0b0110011, 'sra': 0b0110011, 'or': 0b0110011, 'and': 0b0110011,
            'fence': 0b0001111,
            'ecall': 0b1110011, 'ebreak': 0b1110011,
            'csrrw': 0b1110011, 'csrrs': 0b1110011, 'csrrc': 0b1110011,
            'csrrwi': 0b1110011, 'csrrsi': 0b1110011, 'csrrci': 0b1110011
        }

        # funct3 mapping
        self.funct3 = {
            'jalr': 0b000,
            'beq': 0b000, 'bne': 0b001, 'blt': 0b100, 'bge': 0b101, 'bltu': 0b110, 'bgeu': 0b111,
            'lb': 0b000, 'lh': 0b001, 'lw': 0b010, 'lbu': 0b100, 'lhu': 0b101,
            'sb': 0b000, 'sh': 0b001, 'sw': 0b010,
            'addi': 0b000, 'slti': 0b010, 'sltiu': 0b011, 'xori': 0b100, 'ori': 0b110, 'andi': 0b111,
            'slli': 0b001, 'srli': 0b101, 'srai': 0b101,
            'add': 0b000, 'sub': 0b000, 'sll': 0b001, 'slt': 0b010, 'sltu': 0b011,
            'xor': 0b100, 'srl': 0b101, 'sra': 0b101, 'or': 0b110, 'and': 0b111,
            'fence': 0b000, 'fence.i': 0b001,
            'ecall': 0b000, 'ebreak': 0b000,
            'csrrw': 0b001, 'csrrs': 0b010, 'csrrc': 0b011,
            'csrrwi': 0b101, 'csrrsi': 0b110, 'csrrci': 0b111
        }

        # funct7 mapping (SRAI exclusive 0100000)
        self.funct7 = {
            'slli': 0b0000000,
            'srli': 0b0000000,
            'srai': 0b0100000,
            'add': 0b0000000,
            'sub': 0b0100000,
            'sll': 0b0000000,
            'slt': 0b0000000,
            'sltu': 0b0000000,
            'xor': 0b0000000,
            'srl': 0b0000000,
            'sra': 0b0100000,
            'or': 0b0000000,
            'and': 0b0000000
        }

        # CSR register mapping
        self.csr_registers = {
            'mstatus': 0x300, 'mie': 0x304, 'mtvec': 0x305, 'mepc': 0x341, 'mcause': 0x342, 'mtval': 0x343,
            'mip': 0x344, 'cycle': 0xC00, 'time': 0xC01, 'instret': 0xC02, 'cycleh': 0xC80, 'timeh': 0xC81, 'instreth': 0xC82
        }

    # Parse register names/numbers
    def parse_register(self, reg_str):
        reg_str = reg_str.strip().lower()
        if reg_str in self.registers:
            return self.registers[reg_str]
        elif reg_str.startswith('x'):
            try:
                reg_num = int(reg_str[1:])
                if 0 <= reg_num <= 31:
                    return reg_num
                raise ValueError(f"Register number {reg_num} out of range (0-31)")
            except ValueError:
                pass
        raise ValueError(f"Invalid register: '{reg_str}'")

    # Parse immediate values (signed integer)
    def parse_immediate(self, imm_str):
        imm_str = imm_str.strip()
        try:
            if imm_str.startswith(('0x', '-0x')):
                return int(imm_str, 16)
            return int(imm_str, 10)
        except ValueError:
            raise ValueError(f"Invalid immediate: '{imm_str}'")

    def _check_signed_range(self, imm, bits, label):
        min_val = -(1 << (bits - 1))
        max_val = (1 << (bits - 1)) - 1
        if not (min_val <= imm <= max_val):
            raise ValueError(f"{label} immediate out of range ({min_val}..{max_val}), got {imm}")

    def _normalize_u_immediate(self, imm):
        # Accept either 20-bit value or 32-bit value aligned by 12 bits (auto >> 12)
        if -(1 << 19) <= imm <= (1 << 19) - 1:
            return imm & 0xFFFFF
        if (imm & 0xFFF) == 0:
            shifted = imm >> 12
            if -(1 << 19) <= shifted <= (1 << 19) - 1:
                return shifted & 0xFFFFF
        raise ValueError(f"U-type immediate out of range; use 20-bit or 12-bit-aligned value, got {imm}")

    def _parse_label_or_imm(self, token, labels, curr_addr):
        try:
            return self.parse_immediate(token)
        except ValueError:
            if labels is not None and token in labels:
                return labels[token] - curr_addr
            raise ValueError(f"Unknown label or immediate: '{token}'")

    # Parse CSR registers
    def parse_csr(self, csr_str):
        csr_str = csr_str.strip().lower()
        if csr_str in self.csr_registers:
            return self.csr_registers[csr_str]
        try:
            csr_addr = int(csr_str, 16) if csr_str.startswith('0x') else int(csr_str)
            if 0 <= csr_addr <= 0xFFF:
                return csr_addr
            raise ValueError(f"CSR address {hex(csr_addr)} out of range (0-0xFFF)")
        except ValueError:
            raise ValueError(f"Invalid CSR: '{csr_str}'")

    # Instruction encoding functions (by type)
    def encode_r_type(self, instr, rd, rs1, rs2):
        return (
            ((self.funct7[instr] & 0x7F) << 25) |
            ((rs2 & 0x1F) << 20) |
            ((rs1 & 0x1F) << 15) |
            ((self.funct3[instr] & 0x7) << 12) |
            ((rd & 0x1F) << 7) |
            (self.opcodes[instr] & 0x7F)
        )

    def encode_i_type(self, instr, rd, rs1, imm):
        imm_12 = imm & 0xFFF
        funct7_val = self.funct7[instr] if instr in ['slli', 'srli', 'srai'] else 0x00

        return (
            ((funct7_val & 0x7F) << 25) |
            (imm_12 << 20) |
            ((rs1 & 0x1F) << 15) |
            ((self.funct3[instr] & 0x7) << 12) |
            ((rd & 0x1F) << 7) |
            (self.opcodes[instr] & 0x7F)
        )

    def encode_s_type(self, instr, rs2, rs1, imm):
        imm_12 = imm & 0xFFF
        imm_11_5 = (imm_12 >> 5) & 0x7F
        imm_4_0 = imm_12 & 0x1F

        return (
            (imm_11_5 << 25) |
            ((rs2 & 0x1F) << 20) |
            ((rs1 & 0x1F) << 15) |
            ((self.funct3[instr] & 0x7) << 12) |
            (imm_4_0 << 7) |
            (self.opcodes[instr] & 0x7F)
        )

    def encode_b_type(self, instr, rs1, rs2, imm):
        if imm % 2 != 0:
            raise ValueError(f"B-type immediate must be 2-byte aligned, got {imm}")
        imm_13 = imm & 0x1FFF

        return (
            (((imm_13 >> 12) & 0x1) << 31) |
            (((imm_13 >> 5) & 0x3F) << 25) |
            ((rs2 & 0x1F) << 20) |
            ((rs1 & 0x1F) << 15) |
            ((self.funct3[instr] & 0x7) << 12) |
            (((imm_13 >> 1) & 0xF) << 8) |
            (((imm_13 >> 11) & 0x1) << 7) |
            (self.opcodes[instr] & 0x7F)
        )

    def encode_u_type(self, instr, rd, imm):
        imm_20 = imm & 0xFFFFF
        return (
            (imm_20 << 12) |
            ((rd & 0x1F) << 7) |
            (self.opcodes[instr] & 0x7F)
        )

    def encode_j_type(self, instr, rd, imm):
        if imm % 2 != 0:
            raise ValueError(f"J-type immediate must be 2-byte aligned, got {imm}")
        imm_21 = imm & 0x1FFFFF

        return (
            (((imm_21 >> 20) & 0x1) << 31) |
            (((imm_21 >> 12) & 0xFF) << 12) |
            (((imm_21 >> 11) & 0x1) << 20) |
            (((imm_21 >> 1) & 0x3FF) << 21) |
            ((rd & 0x1F) << 7) |
            (self.opcodes[instr] & 0x7F)
        )

    def encode_fence(self, pred='iorw', succ='iorw'):
        pred_map = {'i':0b1000, 'o':0b0100, 'r':0b0010, 'w':0b0001}
        pred_val = 0x0
        for c in pred.lower():
            if c in pred_map:
                pred_val |= pred_map[c]
            else:
                raise ValueError(f"Invalid FENCE predicate character: '{c}'")
        
        succ_val = 0x0
        for c in succ.lower():
            if c in pred_map:
                succ_val |= pred_map[c]
            else:
                raise ValueError(f"Invalid FENCE successor character: '{c}'")

        return (
            (((pred_val << 4) | succ_val) << 20) |
            ((self.funct3['fence'] & 0x7) << 12) |
            (self.opcodes['fence'] & 0x7F)
        )

    def encode_csr(self, instr, rd, csr, rs1_or_imm):
        csr_val = self.parse_csr(csr) if isinstance(csr, str) else csr
        if instr in ['csrrwi', 'csrrsi', 'csrrci']:
            imm = rs1_or_imm & 0x1F
            if imm != rs1_or_imm:
                raise ValueError(f"CSR immediate must be 0-31, got {rs1_or_imm}")
            rs1_or_imm = imm

        return (
            ((csr_val & 0xFFF) << 20) |
            ((rs1_or_imm & 0x1F) << 15) |
            ((self.funct3[instr] & 0x7) << 12) |
            ((rd & 0x1F) << 7) |
            (self.opcodes[instr] & 0x7F)
        )

    # Assemble a single instruction (standard instructions only)
    def assemble_instr(self, line, labels=None, curr_addr=0):
        line_clean = re.sub(r'//.*$|#.*$', '', line.strip())
        if not line_clean:
            return None

        parts = re.split(r'[,\s]+', line_clean)
        instr = parts[0].lower()
        operands = [op for op in parts[1:] if op]

        try:
            # U-type instructions
            if instr in ['lui', 'auipc']:
                if len(operands) != 2:
                    raise ValueError(f"Requires 2 operands (rd, imm), got {len(operands)}")
                rd = self.parse_register(operands[0])
                imm_raw = self.parse_immediate(operands[1])
                imm = self._normalize_u_immediate(imm_raw)
                return self.encode_u_type(instr, rd, imm)

            # J-type instructions
            elif instr == 'jal':
                if len(operands) != 2:
                    raise ValueError(f"Requires 2 operands (rd, imm), got {len(operands)}")
                rd = self.parse_register(operands[0])
                imm = self._parse_label_or_imm(operands[1], labels, curr_addr)
                self._check_signed_range(imm, 21, "J-type")
                return self.encode_j_type(instr, rd, imm)

            # I-type instructions: JALR
            elif instr == 'jalr':
                if len(operands) != 2:
                    raise ValueError(f"Requires 2 operands (rd, offset(rs1)), got {len(operands)}")
                rd = self.parse_register(operands[0])
                match = re.match(r'^(-?\w+)\((\w+)\)$', operands[1])
                if not match:
                    raise ValueError(f"Invalid format: expected 'offset(rs1)', got '{operands[1]}'")
                imm = self.parse_immediate(match.group(1))
                self._check_signed_range(imm, 12, "I-type")
                rs1 = self.parse_register(match.group(2))
                return self.encode_i_type(instr, rd, rs1, imm)

            # I-type instructions: Load
            elif instr in ['lb', 'lh', 'lw', 'lbu', 'lhu']:
                if len(operands) != 2:
                    raise ValueError(f"Requires 2 operands (rd, offset(rs1)), got {len(operands)}")
                rd = self.parse_register(operands[0])
                match = re.match(r'^(-?\w+)\((\w+)\)$', operands[1])
                if not match:
                    raise ValueError(f"Invalid format: expected 'offset(rs1)', got '{operands[1]}'")
                imm = self.parse_immediate(match.group(1))
                self._check_signed_range(imm, 12, "I-type")
                rs1 = self.parse_register(match.group(2))
                return self.encode_i_type(instr, rd, rs1, imm)

            # I-type instructions: ALU Immediate
            elif instr in ['addi', 'slti', 'sltiu', 'xori', 'ori', 'andi']:
                if len(operands) != 3:
                    raise ValueError(f"Requires 3 operands (rd, rs1, imm), got {len(operands)}")
                rd = self.parse_register(operands[0])
                rs1 = self.parse_register(operands[1])
                imm = self.parse_immediate(operands[2])
                self._check_signed_range(imm, 12, "I-type")
                return self.encode_i_type(instr, rd, rs1, imm)

            # I-type instructions: Shifts (including SRAI)
            elif instr in ['slli', 'srli', 'srai']:
                if len(operands) != 3:
                    raise ValueError(f"Requires 3 operands (rd, rs1, imm), got {len(operands)}")
                rd = self.parse_register(operands[0])
                rs1 = self.parse_register(operands[1])
                imm = self.parse_immediate(operands[2])
                if not (0 <= imm <= 31):
                    raise ValueError(f"Shift immediate must be 0-31, got {imm}")
                return self.encode_i_type(instr, rd, rs1, imm)

            # I-type instructions: FENCE.I
            elif instr == 'fence.i':
                if len(operands) != 0:
                    raise ValueError(f"Requires 0 operands, got {len(operands)}")
                return self.encode_i_type(instr, rd=0, rs1=0, imm=0)

            # B-type instructions
            elif instr in ['beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu']:
                if len(operands) != 3:
                    raise ValueError(f"Requires 3 operands (rs1, rs2, imm), got {len(operands)}")
                rs1 = self.parse_register(operands[0])
                rs2 = self.parse_register(operands[1])
                imm = self._parse_label_or_imm(operands[2], labels, curr_addr)
                self._check_signed_range(imm, 13, "B-type")
                return self.encode_b_type(instr, rs1, rs2, imm)

            # S-type instructions
            elif instr in ['sb', 'sh', 'sw']:
                if len(operands) != 2:
                    raise ValueError(f"Requires 2 operands (rs2, offset(rs1)), got {len(operands)}")
                rs2 = self.parse_register(operands[0])
                match = re.match(r'^(-?\w+)\((\w+)\)$', operands[1])
                if not match:
                    raise ValueError(f"Invalid format: expected 'offset(rs1)', got '{operands[1]}'")
                imm = self.parse_immediate(match.group(1))
                self._check_signed_range(imm, 12, "S-type")
                rs1 = self.parse_register(match.group(2))
                return self.encode_s_type(instr, rs2, rs1, imm)

            # R-type instructions
            elif instr in ['add', 'sub', 'sll', 'slt', 'sltu', 'xor', 'srl', 'sra', 'or', 'and']:
                if len(operands) != 3:
                    raise ValueError(f"Requires 3 operands (rd, rs1, rs2), got {len(operands)}")
                rd = self.parse_register(operands[0])
                rs1 = self.parse_register(operands[1])
                rs2 = self.parse_register(operands[2])
                return self.encode_r_type(instr, rd, rs1, rs2)

            # FENCE instruction
            elif instr == 'fence':
                pred = operands[0] if len(operands) >= 1 else 'iorw'
                succ = operands[1] if len(operands) >= 2 else 'iorw'
                return self.encode_fence(pred, succ)

            # System instructions: ECALL/EBREAK
            elif instr == 'ecall':
                if len(operands) != 0:
                    raise ValueError(f"Requires 0 operands, got {len(operands)}")
                return 0x00000073

            elif instr == 'ebreak':
                if len(operands) != 0:
                    raise ValueError(f"Requires 0 operands, got {len(operands)}")
                return 0x00100073

            # System instructions: CSR
            elif instr in ['csrrw', 'csrrs', 'csrrc']:
                if len(operands) != 3:
                    raise ValueError(f"Requires 3 operands (rd, csr, rs1), got {len(operands)}")
                rd = self.parse_register(operands[0])
                csr = operands[1]
                rs1 = self.parse_register(operands[2])
                return self.encode_csr(instr, rd, csr, rs1)

            elif instr in ['csrrwi', 'csrrsi', 'csrrci']:
                if len(operands) != 3:
                    raise ValueError(f"Requires 3 operands (rd, csr, imm), got {len(operands)}")
                rd = self.parse_register(operands[0])
                csr = operands[1]
                imm = self.parse_immediate(operands[2])
                return self.encode_csr(instr, rd, csr, imm)

            else:
                raise ValueError(f"Unsupported instruction (not in RV32I standard): '{instr}'")

        except Exception as e:
            raise ValueError(f"Assembly failed: {str(e)} (original instruction: {line_clean})")

    # Core functionality: Read custom ASM file and generate machine code to TXT and COE
    def assemble_file(self, input_asm_path, output_txt_path, output_coe_path=None):
        """
        Assembles a user-written ASM file into machine code and writes to TXT and COE files
        
        Parameters:
            input_asm_path: Path to input ASM file (user-defined instruction file)
            output_txt_path: Path to output TXT file (32-bit binary per line)
            output_coe_path: Path to output COE file (optional, auto-generated if None)
        """
        # Auto-generate COE path if not provided
        if output_coe_path is None:
            base_path = os.path.splitext(output_txt_path)[0]
            output_coe_path = base_path + '.coe'

        # Read user's ASM file
        try:
            with open(input_asm_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except FileNotFoundError:
            raise FileNotFoundError(f"Input ASM file not found: {input_asm_path}")

        machine_codes = []
        labels = {}
        instructions = []
        pc_addr = 0

        # First pass: collect labels and instruction lines
        for line_num, line in enumerate(lines, 1):
            line_clean = re.sub(r'//.*$|#.*$', '', line.strip())
            if not line_clean:
                continue

            # Extract labels (support multiple labels on one line)
            while True:
                match = re.match(r'^\s*([A-Za-z_]\w*):', line_clean)
                if not match:
                    break
                label = match.group(1)
                if label in labels:
                    raise ValueError(f"Duplicate label '{label}' on line {line_num}")
                labels[label] = pc_addr
                line_clean = line_clean[match.end():].strip()

            if line_clean:
                instructions.append((line_num, line, line_clean, pc_addr))
                pc_addr += 4
        print("=" * 80)
        print(f"RV32I Assembler - Processing user file: {input_asm_path}")
        print("=" * 80)
        print(f"{'Line':<4} {'Original Instruction':<50} {'Machine Code (Hex)':<12} {'Status'}")
        print("-" * 80)

        # Assemble line by line (second pass)
        for line_num, line, line_clean, pc_addr in instructions:
            try:
                code = self.assemble_instr(line_clean, labels=labels, curr_addr=pc_addr)
                if code is not None:
                    machine_codes.append(code)
                    print(f"{line_num:<4} {line.strip():<50} 0x{code:08X} {'Success'}")
                else:
                    print(f"{line_num:<4} {line.strip():<50} {'-':<12} {'Empty line/Comment'}")
            except ValueError as e:
                print(f"{line_num:<4} {line.strip():<50} {'-':<12} {'Failed: ' + str(e)}")
                raise  # Stop on error (comment to continue assembly)

        # Write machine code to TXT file (32-bit binary)
        with open(output_txt_path, 'w', encoding='utf-8') as f:
            for code in machine_codes:
                f.write(f"{code:032b}\n")

        # Write machine code to COE file (Xilinx memory initialization)
        with open(output_coe_path, 'w', encoding='utf-8') as f:
            f.write("memory_initialization_radix=16;\n")
            f.write("memory_initialization_vector=\n")
            
            for i, code in enumerate(machine_codes):
                # Last entry ends with semicolon, others with comma
                if i == len(machine_codes) - 1:
                    f.write(f"{code:08x};")
                else:
                    f.write(f"{code:08x},\n")
        
        # Output summary
        print("=" * 80)
        print(f"Assembly completed! Generated {len(machine_codes)} machine code instructions")
        print(f"Machine code saved to:")
        print(f"  - Binary TXT file: {output_txt_path}")
        print(f"  - COE file: {output_coe_path}")
        print("=" * 80)
        return True

# Get user input for file names with validation
def get_user_file_paths():
    print("\nRV32I Assembler - File Input")
    print("---------------------------")
    
    # Get input file path
    while True:
        input_path = input("Enter path to your ASM file: ").strip()
        if not input_path:
            print("Error: File path cannot be empty")
            continue
        if os.path.exists(input_path) and os.path.isfile(input_path):
            break
        print(f"Error: File '{input_path}' does not exist. Please try again.")
    
    # Get output file path
    while True:
        output_path = input("Enter path for output machine code file: ").strip()
        if not output_path:
            print("Error: Output path cannot be empty")
            continue
        
        # Check if output directory exists
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            print(f"Error: Directory '{output_dir}' does not exist. Please try again.")
            continue
            
        # Check if user wants to overwrite existing file
        if os.path.exists(output_path):
            overwrite = input(f"File '{output_path}' already exists. Overwrite? (y/n): ").strip().lower()
            if overwrite == 'y':
                break
            else:
                print("Please enter a different output path")
                continue
        break
    
    return input_path, output_path

# Main execution with user input
def main():
    try:
        # Get file paths from user
        input_asm_path, output_txt_path = get_user_file_paths()
        
        # Create assembler instance and run
        assembler = RV32IAssembler()
        assembler.assemble_file(input_asm_path, output_txt_path)
        
    except Exception as e:
        print(f"\nAssembly process terminated: {str(e)}")

if __name__ == "__main__":
    main()
     
