import re
from pathlib import Path

REG_ALIASES = {
    **{f"x{i}": i for i in range(32)},
    "zero":0,"ra":1,"sp":2,"gp":3,"tp":4,
    "t0":5,"t1":6,"t2":7,
    "s0":8,"fp":8,"s1":9,
    "a0":10,"a1":11,"a2":12,"a3":13,"a4":14,"a5":15,"a6":16,"a7":17,
    "s2":18,"s3":19,"s4":20,"s5":21,"s6":22,"s7":23,"s8":24,"s9":25,"s10":26,"s11":27,
    "t3":28,"t4":29,"t5":30,"t6":31,
}

OPC = {
    "lui":0b0110111, "auipc":0b0010111, "jal":0b1101111, "jalr":0b1100111,
    "beq":0b1100011, "bne":0b1100011, "blt":0b1100011, "bge":0b1100011, "bltu":0b1100011, "bgeu":0b1100011,
    "lb":0b0000011, "lh":0b0000011, "lw":0b0000011, "lbu":0b0000011, "lhu":0b0000011,
    "sb":0b0100011, "sh":0b0100011, "sw":0b0100011,
    "addi":0b0010011, "slti":0b0010011, "sltiu":0b0010011, "xori":0b0010011, "ori":0b0010011, "andi":0b0010011,
    "slli":0b0010011, "srli":0b0010011, "srai":0b0010011,
    "add":0b0110011, "sub":0b0110011, "sll":0b0110011, "slt":0b0110011, "sltu":0b0110011,
    "xor":0b0110011, "srl":0b0110011, "sra":0b0110011, "or":0b0110011, "and":0b0110011,
}

FUNCT3 = {
    "beq":0,"bne":1,"blt":4,"bge":5,"bltu":6,"bgeu":7,
    "lb":0,"lh":1,"lw":2,"lbu":4,"lhu":5,
    "sb":0,"sh":1,"sw":2,
    "addi":0,"slti":2,"sltiu":3,"xori":4,"ori":6,"andi":7,
    "slli":1,"srli":5,"srai":5,
    "add":0,"sub":0,"sll":1,"slt":2,"sltu":3,"xor":4,"srl":5,"sra":5,"or":6,"and":7,
    "jalr":0,
}

FUNCT7 = {
    "add":0,"sub":0b0100000,"sll":0,"slt":0,"sltu":0,"xor":0,"srl":0,"sra":0b0100000,"or":0,"and":0,
    "slli":0,"srli":0,"srai":0b0100000,
}

def reg(x):
    x=x.strip()
    if x not in REG_ALIASES:
        raise ValueError(f"bad reg {x}")
    return REG_ALIASES[x]

def imm(v, bits):
    n = int(v,0)
    minv = -(1<<(bits-1))
    maxv = (1<<(bits-1))-1
    if n < minv or n > maxv:
        raise ValueError(f"imm out of range {n} for {bits}")
    return n & ((1<<bits)-1)

def parse_lines(text):
    raw=[]
    for line in text.splitlines():
        line=line.split('#',1)[0].strip()
        if line:
            raw.append(line)
    return raw

def first_pass(lines):
    labels={}
    inst=[]
    pc=0
    for line in lines:
        if line.endswith(':'):
            labels[line[:-1]]=pc
            continue
        if ':' in line:
            lb,rest=line.split(':',1)
            labels[lb.strip()]=pc
            line=rest.strip()
            if not line:
                continue
        inst.append((pc,line))
        pc+=4
    return labels,inst

def enc_i(op, rd, rs1, im):
    return (im<<20)|(rs1<<15)|(FUNCT3[op]<<12)|(rd<<7)|OPC[op]

def enc_r(op, rd, rs1, rs2):
    return (FUNCT7[op]<<25)|(rs2<<20)|(rs1<<15)|(FUNCT3[op]<<12)|(rd<<7)|OPC[op]

def enc_s(op, rs1, rs2, im):
    return ((im>>5)<<25)|(rs2<<20)|(rs1<<15)|(FUNCT3[op]<<12)|((im&0x1F)<<7)|OPC[op]

def enc_b(op, rs1, rs2, im):
    return (((im>>12)&1)<<31)|(((im>>5)&0x3F)<<25)|(rs2<<20)|(rs1<<15)|(FUNCT3[op]<<12)|(((im>>1)&0xF)<<8)|(((im>>11)&1)<<7)|OPC[op]

def enc_u(op, rd, im):
    return ((im & 0xFFFFF)<<12)|(rd<<7)|OPC[op]

def enc_j(rd, im):
    return (((im>>20)&1)<<31)|(((im>>1)&0x3FF)<<21)|(((im>>11)&1)<<20)|(((im>>12)&0xFF)<<12)|(rd<<7)|OPC["jal"]

def assemble(insts, labels):
    out=[]
    for pc,line in insts:
        t=re.split(r"[\s,]+", line)
        op=t[0]
        args=[a for a in t[1:] if a]

        if op in ["add","sub","sll","slt","sltu","xor","srl","sra","or","and"]:
            rd,rs1,rs2=map(reg,args)
            code=enc_r(op,rd,rs1,rs2)
        elif op in ["addi","slti","sltiu","xori","ori","andi","slli","srli","srai"]:
            rd,rs1=reg(args[0]),reg(args[1])
            im = imm(args[2], 12)
            code=enc_i(op,rd,rs1,im)
        elif op in ["lb","lh","lw","lbu","lhu"]:
            rd=reg(args[0])
            m=re.match(r"(.+)\((.+)\)", args[1])
            im=imm(m.group(1),12); rs1=reg(m.group(2))
            code=enc_i(op,rd,rs1,im)
        elif op in ["sb","sh","sw"]:
            rs2=reg(args[0])
            m=re.match(r"(.+)\((.+)\)", args[1])
            im=imm(m.group(1),12); rs1=reg(m.group(2))
            code=enc_s(op,rs1,rs2,im)
        elif op in ["beq","bne","blt","bge","bltu","bgeu"]:
            rs1,rs2=reg(args[0]),reg(args[1])
            target=labels[args[2]]
            off=target-pc
            if off % 2 != 0:
                raise ValueError("branch align")
            im=imm(str(off),13)
            code=enc_b(op,rs1,rs2,im)
        elif op in ["lui","auipc"]:
            rd=reg(args[0])
            im=int(args[1],0)
            code=enc_u(op,rd,im)
        elif op=="jal":
            rd=reg(args[0])
            target=labels[args[1]]
            off=target-pc
            im=imm(str(off),21)
            code=enc_j(rd,im)
        elif op=="jalr":
            rd=reg(args[0])
            m=re.match(r"(.+)\((.+)\)", args[1])
            im=imm(m.group(1),12); rs1=reg(m.group(2))
            code=enc_i(op,rd,rs1,im)
        else:
            raise ValueError(f"unsupported op {op}")
        out.append(code & 0xFFFFFFFF)
    return out

def main():
    asm = Path('LodeRunner_CPU.asm').read_text(encoding='ascii')
    lines=parse_lines(asm)
    labels,insts=first_pass(lines)
    words=assemble(insts,labels)

    tmpl = Path('CPU/Inst_Mem.v').read_text(encoding='ascii')
    pre = tmpl.split('// paste your instructions here (generated by python)')[0]
    new = pre + '// paste your instructions here (generated by python)\n'
    for i,w in enumerate(words):
        new += f"    memory[{i}] = 32'h{w:08x};\n"
    new += "  end\n\n  always @(*) begin\n    instruction = memory[word_addr];\n  end\nendmodule\n"
    Path('CPU/Inst_Mem.v').write_text(new,encoding='ascii')
    print(f"wrote {len(words)} instructions")

if __name__ == '__main__':
    main()
