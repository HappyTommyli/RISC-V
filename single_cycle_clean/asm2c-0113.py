import re
import os


class RV32IAssembler:
    def __init__(self):
        # Register mapping
        self.registers = {
            'zero': 0, 'x0': 0,
            'ra': 1, 'x1': 1, 'sp': 2, 'x2': 2, 'gp': 3, 'x3': 3, 'tp': 4, 'x4': 4,
            't0': 5, 'x5': 5, 't1': 6, 'x6': 6, 't2': 7, 'x7': 7,
            's0': 8, 'x8': 8, 'fp': 8, 's1': 9, 'x9': 9,
            'a0': 10, 'x10': 10, 'a1': 11, 'x11': 11, 'a2': 12, 'x12': 12,
            'a3': 13, 'x13': 13, 'a4': 14, 'x14': 14, 'a5': 15, 'x15': 15,
            'a6': 16, 'x16': 16, 'a7': 17, 'x17': 17,
            's2': 18, 'x18': 18, 's3': 19, 'x19': 19, 's4': 20, 'x20': 20,
            's5': 21, 'x21': 21, 's6': 22, 'x22': 22, 's7': 23, 'x23': 23,
            's8': 24, 'x24': 24, 's9': 25, 'x25': 25,
            's10': 26, 'x26': 26, 's11': 27, 'x27': 27,
            't3': 28, 'x28': 28, 't4': 29, 'x29': 29,
            't5': 30, 'x30': 30, 't6': 31, 'x31': 31
        }

        # Opcode / funct3 / funct7 (只保留你目前用到的核心指令；可以再擴充)
        self.opcodes = {
            'lui':   0b0110111, 'auipc': 0b0010111,
            'jal':   0b1101111,
            'jalr':  0b1100111,
            'lb':    0b0000011, 'lh': 0b0000011, 'lw': 0b0000011,
            'sb':    0b0100011, 'sh': 0b0100011, 'sw': 0b0100011,
            'addi':  0b0010011, 'slti': 0b0010011, 'sltiu': 0b0010011,
            'xori':  0b0010011, 'ori': 0b0010011, 'andi': 0b0010011,
            'slli':  0b0010011, 'srli': 0b0010011, 'srai': 0b0010011,
            'beq':   0b1100011, 'bne': 0b1100011, 'blt': 0b1100011,
            'bge':   0b1100011, 'bltu': 0b1100011, 'bgeu': 0b1100011,
            'add':   0b0110011, 'sub': 0b0110011, 'sll': 0b0110011,
            'slt':   0b0110011, 'sltu': 0b0110011, 'xor': 0b0110011,
            'srl':   0b0110011, 'sra': 0b0110011, 'or':  0b0110011,
            'and':   0b0110011,
        }

        self.funct3 = {
            'jalr': 0b000,
            'beq': 0b000, 'bne': 0b001, 'blt': 0b100,
            'bge': 0b101, 'bltu': 0b110, 'bgeu': 0b111,
            'lb': 0b000, 'lh': 0b001, 'lw': 0b010,
            'sb': 0b000, 'sh': 0b001, 'sw': 0b010,
            'addi': 0b000, 'slti': 0b010, 'sltiu': 0b011,
            'xori': 0b100, 'ori': 0b110, 'andi': 0b111,
            'slli': 0b001, 'srli': 0b101, 'srai': 0b101,
            'add': 0b000, 'sub': 0b000, 'sll': 0b001,
            'slt': 0b010, 'sltu': 0b011, 'xor': 0b100,
            'srl': 0b101, 'sra': 0b101, 'or': 0b110, 'and': 0b111,
        }

        self.funct7 = {
            'slli': 0b0000000, 'srli': 0b0000000, 'srai': 0b0100000,
            'add':  0b0000000, 'sub':  0b0100000,
            'sll':  0b0000000, 'slt':  0b0000000, 'sltu': 0b0000000,
            'xor':  0b0000000, 'srl':  0b0000000, 'sra':  0b0100000,
            'or':   0b0000000, 'and':  0b0000000,
        }

    # --- 基本 parse ---

    def parse_register(self, s):
        s = s.strip().lower()
        if s in self.registers:
            return self.registers[s]
        if s.startswith('x'):
            v = int(s[1:])
            if 0 <= v <= 31:
                return v
        raise ValueError(f"Invalid register '{s}'")

    def parse_immediate(self, s):
        s = s.strip()
        if re.fullmatch(r'-?0x[0-9a-fA-F]+', s):
            return int(s, 16)
        return int(s, 10)

    # --- encode helpers ---

    def enc_r(self, instr, rd, rs1, rs2):
        return ((self.funct7[instr] & 0x7F) << 25) | \
               ((rs2 & 0x1F) << 20) | \
               ((rs1 & 0x1F) << 15) | \
               ((self.funct3[instr] & 0x7) << 12) | \
               ((rd & 0x1F) << 7) | \
               (self.opcodes[instr] & 0x7F)

    def enc_i(self, instr, rd, rs1, imm):
        imm12 = imm & 0xFFF
        funct7_val = self.funct7[instr] if instr in ['slli', 'srli', 'srai'] else 0
        return ((funct7_val & 0x7F) << 25) | \
               (imm12 << 20) | \
               ((rs1 & 0x1F) << 15) | \
               ((self.funct3[instr] & 0x7) << 12) | \
               ((rd & 0x1F) << 7) | \
               (self.opcodes[instr] & 0x7F)

    def enc_s(self, instr, rs2, rs1, imm):
        imm12 = imm & 0xFFF
        imm_11_5 = (imm12 >> 5) & 0x7F
        imm_4_0 = imm12 & 0x1F
        return (imm_11_5 << 25) | \
               ((rs2 & 0x1F) << 20) | \
               ((rs1 & 0x1F) << 15) | \
               ((self.funct3[instr] & 0x7) << 12) | \
               (imm_4_0 << 7) | \
               (self.opcodes[instr] & 0x7F)

    def enc_b(self, instr, rs1, rs2, imm):
        if imm % 2 != 0:
            raise ValueError(f"B-type imm must be 2-byte aligned, got {imm}")
        imm13 = imm & 0x1FFF
        return (((imm13 >> 12) & 0x1) << 31) | \
               (((imm13 >> 5) & 0x3F) << 25) | \
               ((rs2 & 0x1F) << 20) | \
               ((rs1 & 0x1F) << 15) | \
               ((self.funct3[instr] & 0x7) << 12) | \
               (((imm13 >> 1) & 0xF) << 8) | \
               (((imm13 >> 11) & 0x1) << 7) | \
               (self.opcodes[instr] & 0x7F)

    def enc_u(self, instr, rd, imm):
        imm20 = imm & 0xFFFFF
        return (imm20 << 12) | ((rd & 0x1F) << 7) | (self.opcodes[instr] & 0x7F)

    def enc_j(self, instr, rd, imm):
        if imm % 2 != 0:
            raise ValueError(f"J-type imm must be 2-byte aligned, got {imm}")
        imm21 = imm & 0x1FFFFF
        return (((imm21 >> 20) & 0x1) << 31) | \
               (((imm21 >> 12) & 0xFF) << 12) | \
               (((imm21 >> 11) & 0x1) << 20) | \
               (((imm21 >> 1) & 0x3FF) << 21) | \
               ((rd & 0x1F) << 7) | \
               (self.opcodes[instr] & 0x7F)

    # --- 兩 pass：pass1 解析 label / 指令 ---

    def preprocess(self, lines):
        """去掉註解，拆 label，返回 (指令列表, label地址表)"""
        cleaned = []
        labels = {}
        pc = 0  # 以 byte 為單位

        for raw in lines:
            line = re.sub(r'//.*$|#.*$', '', raw).strip()
            if not line:
                continue

            # 允許一行多個 label，例如: loop0: loop1: addi ...
            while True:
                m = re.match(r'^([A-Za-z_]\w*):', line)
                if not m:
                    break
                label = m.group(1)
                if label in labels:
                    raise ValueError(f"Duplicate label '{label}'")
                labels[label] = pc  # 這個 label 指向當前指令地址
                line = line[m.end():].strip()

            if not line:
                # 只有 label，沒有指令
                continue

            # 剩下的是一條真正指令
            cleaned.append((pc, line))
            pc += 4

        return cleaned, labels

    # --- pass2：真正 encode，一行一行轉 machine code ---

    def assemble_instr(self, pc, line, labels):
        parts = re.split(r'[,\s]+', line.strip())
        instr = parts[0].lower()
        ops = [p for p in parts[1:] if p]

        # pseudo: nop = addi x0, x0, 0
        if instr == 'nop':
            return self.enc_i('addi', 0, 0, 0)

        # label or immediate?
        def parse_imm_or_label(token, pc_now, is_branch=False):
            # token 是數字
            if re.fullmatch(r'-?(0x[0-9a-fA-F]+|\d+)', token):
                return self.parse_immediate(token)
            # token 是 label
            if token not in labels:
                raise ValueError(f"Unknown label '{token}'")
            target = labels[token]
            # offset = target_pc - current_pc
            return target - pc_now

        # U-type
        if instr in ['lui', 'auipc']:
            if len(ops) != 2:
                raise ValueError(f"{instr} needs rd, imm")
            rd = self.parse_register(ops[0])
            imm = self.parse_immediate(ops[1])
            return self.enc_u(instr, rd, imm)

        # JAL (rd, imm/label)
        if instr == 'jal':
            if len(ops) != 2:
                raise ValueError("jal rd, offset/label")
            rd = self.parse_register(ops[0])
            imm = parse_imm_or_label(ops[1], pc, is_branch=False)
            return self.enc_j(instr, rd, imm)

        # JALR
        if instr == 'jalr':
            if len(ops) != 2:
                raise ValueError("jalr rd, offset(rs1)")
            rd = self.parse_register(ops[0])
            m = re.match(r'^(-?\w+)\((\w+)\)$', ops[1])
            if not m:
                raise ValueError(f"jalr offset(rs1) format error: {ops[1]}")
            imm = parse_imm_or_label(m.group(1), pc, is_branch=False)
            rs1 = self.parse_register(m.group(2))
            return self.enc_i(instr, rd, rs1, imm)

        # Load
        if instr in ['lb', 'lh', 'lw']:
            if len(ops) != 2:
                raise ValueError(f"{instr} rd, offset(rs1)")
            rd = self.parse_register(ops[0])
            m = re.match(r'^(-?\w+)\((\w+)\)$', ops[1])
            if not m:
                raise ValueError(f"{instr} offset(rs1) format error: {ops[1]}")
            imm = parse_imm_or_label(m.group(1), pc, is_branch=False)
            rs1 = self.parse_register(m.group(2))
            return self.enc_i(instr, rd, rs1, imm)

        # Store
        if instr in ['sb', 'sh', 'sw']:
            if len(ops) != 2:
                raise ValueError(f"{instr} rs2, offset(rs1)")
            rs2 = self.parse_register(ops[0])
            m = re.match(r'^(-?\w+)\((\w+)\)$', ops[1])
            if not m:
                raise ValueError(f"{instr} offset(rs1) format error: {ops[1]}")
            imm = parse_imm_or_label(m.group(1), pc, is_branch=False)
            rs1 = self.parse_register(m.group(2))
            return self.enc_s(instr, rs2, rs1, imm)

        # I-type ALU
        if instr in ['addi', 'slti', 'sltiu', 'xori', 'ori', 'andi']:
            if len(ops) != 3:
                raise ValueError(f"{instr} rd, rs1, imm")
            rd = self.parse_register(ops[0])
            rs1 = self.parse_register(ops[1])
            imm = parse_imm_or_label(ops[2], pc, is_branch=False)
            return self.enc_i(instr, rd, rs1, imm)

        # Shift
        if instr in ['slli', 'srli', 'srai']:
            if len(ops) != 3:
                raise ValueError(f"{instr} rd, rs1, shamt")
            rd = self.parse_register(ops[0])
            rs1 = self.parse_register(ops[1])
            imm = self.parse_immediate(ops[2])
            if not (0 <= imm <= 31):
                raise ValueError("shift imm 0..31")
            return self.enc_i(instr, rd, rs1, imm)

        # Branch
        if instr in ['beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu']:
            if len(ops) != 3:
                raise ValueError(f"{instr} rs1, rs2, offset/label")
            rs1 = self.parse_register(ops[0])
            rs2 = self.parse_register(ops[1])
            imm = parse_imm_or_label(ops[2], pc, is_branch=True)
            return self.enc_b(instr, rs1, rs2, imm)

        # R-type
        if instr in ['add', 'sub', 'sll', 'slt', 'sltu',
                     'xor', 'srl', 'sra', 'or', 'and']:
            if len(ops) != 3:
                raise ValueError(f"{instr} rd, rs1, rs2")
            rd = self.parse_register(ops[0])
            rs1 = self.parse_register(ops[1])
            rs2 = self.parse_register(ops[2])
            return self.enc_r(instr, rd, rs1, rs2)

        raise ValueError(f"Unsupported instruction '{instr}' (in line: {line})")

    # --- 組整個檔案並輸出 txt/coe ---

    def assemble_file(self, input_path, out_txt, out_coe=None):
        if out_coe is None:
            out_coe = os.path.splitext(out_txt)[0] + '.coe'

        with open(input_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # pass1
        instr_list, labels = self.preprocess(lines)

        machine = []
        print("=" * 80)
        print(f"RV32I Assembler (labels) - {input_path}")
        print("=" * 80)
        print(f"{'PC':<6} {'Asm':<40} {'Code':<12}")
        print("-" * 80)

        # pass2
        for pc, text in instr_list:
            code = self.assemble_instr(pc, text, labels)
            machine.append(code)
            print(f"0x{pc:04x} {text:<40} 0x{code:08x}")

        # txt (binary)
        with open(out_txt, 'w', encoding='utf-8') as f:
            for code in machine:
                f.write(f"{code:032b}\n")

        # coe (hex)
        with open(out_coe, 'w', encoding='utf-8') as f:
            f.write("memory_initialization_radix=16;\n")
            f.write("memory_initialization_vector=\n")
            for i, code in enumerate(machine):
                if i == len(machine) - 1:
                    f.write(f"{code:08x};")
                else:
                    f.write(f"{code:08x},\n")

        print("=" * 80)
        print(f"Generated {len(machine)} instructions")
        print(f"TXT: {out_txt}")
        print(f"COE: {out_coe}")
        print("=" * 80)


def main():
    asm = RV32IAssembler()
    inp = input("ASM 路徑: ").strip()
    out = input("輸出 TXT 路徑: ").strip()
    asm.assemble_file(inp, out)


if __name__ == "__main__":
    main()
