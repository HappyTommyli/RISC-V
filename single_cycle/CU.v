module CU  ( input wire [31:0] instruction, // instruction from Instruction Memory
             output reg reg_write, // whether to write to register file
             output reg mem_to_reg, // whether to write data from memory to register file
             output reg mem_write, // whether to write to memory
             output reg mem_read, // whether to read from memory
             output reg alu_src, // whether the second ALU operand is from immediate
             output reg [3:0] alu_op, // ALU operation code
             output reg branch, // whether the instruction is a branch
             output reg jump, // whether the instruction is a jump
             output reg jalr_enable, // whether the instruction is a jalr
             output reg [11:0] csr_addr, // CSR address   
             output reg csr_write_enable, // CSR write enable        
             output reg [1:0] csr_op, // CSR operation type       
             output reg [4:0] csr_imm, // immediate value for CSR instructions
             output reg [2:0] csr_funct3 // funct3 field for CSR instructions
            );
    wire [6:0] opcode; 
    wire [2:0] funct3;
    wire [6:0] funct7;
    assign opcode = instruction[6:0]; 
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];
    wire [11:0] csr_addr_raw = instruction[31:20];
    wire [4:0] csr_imm_raw = instruction[19:15];
    always @(*) begin
        // Default values
        reg_write = 0;
        mem_to_reg = 0;
        mem_write = 0;
        mem_read = 0;
        alu_src = 0;
        alu_op = 4'b0000; 
        branch = 0;
        jump = 0;
        jalr_enable = 0; 
        csr_addr = 12'h000;  
        csr_write_enable = 0;          
        csr_op = 2'b00;      
        csr_imm = 5'h00;
        csr_funct3 = 3'b000; 

        case (opcode)
            7'b0110011: begin 
                reg_write = 1;
                alu_src = 0;
                case ({funct7, funct3})
                    10'b0000000000: alu_op = 4'b0000; // ADD
                    10'b0100000000: alu_op = 4'b0001; // SUB
                    10'b0000000001: alu_op = 4'b0100; // SLL
                    10'b0000000010: alu_op = 4'b0010; // SLT
                    10'b0000000011: alu_op = 4'b0011; // SLTU
                    10'b0000000100: alu_op = 4'b0101; // XOR
                    10'b0000000101: alu_op = 4'b0110; // SRL
                    10'b0100000101: alu_op = 4'b0111; // SRA
                    10'b0000000110: alu_op = 4'b1000; // OR
                    10'b0000000111: alu_op = 4'b1001; // AND
                    default: alu_op = 4'b1111; // invaild operation
                endcase
            end
            7'b0010011: begin // I-type 
                reg_write = 1;
                alu_src = 1;
                case (funct3)
                    3'b000: alu_op = 4'b0000; // ADDI
                    3'b001: alu_op = 4'b0100; // SLLI
                    3'b010: alu_op = 4'b0010; // SLTI
                    3'b011: alu_op = 4'b0011; // SLTIU
                    3'b100: alu_op = 4'b0101; // XORI
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            alu_op = 4'b0110; // SRLI
                        else if (funct7 == 7'b0100000)
                            alu_op = 4'b0111; // SRAI
                        else
                            alu_op = 4'b1111; // invaild operation
                    end
                    3'b110: alu_op = 4'b1000; // ORI
                    3'b111: alu_op = 4'b1001; // ANDI
                    default: alu_op = 4'b1111; // invaild operation
                endcase
            end
            7'b0000011: begin // LB, LH, LW, LBU, LHU
                reg_write = 1;
                mem_to_reg = 1;
                mem_read = 1;
                alu_src = 1;
                alu_op = 4'b0000; // ADD for address calculation
            end
            7'b0100011: begin // SB, SH, SW
                mem_write = 1;
                alu_src = 1;
                alu_op = 4'b0000; // ADD for address calculation
            end
            7'b1100011: begin // B-type
                branch = 1;
                case (funct3)
                    3'b000: alu_op = 4'b0001; // BEQ
                    3'b001: alu_op = 4'b0001; // BNE
                    3'b100: alu_op = 4'b0010; // BLT
                    3'b101: alu_op = 4'b1011; // BGE
                    3'b110: alu_op = 4'b0011; // BLTU
                    3'b111: alu_op = 4'b0011; // BGEU
                    default: alu_op = 4'b1111; // invaild operation
                endcase
            end
            7'b1101111: begin // JAL
                reg_write = 1;
                jump = 1;
                alu_op = 4'b1010; // no operation              
            end
            7'b1100111: begin // JALR
                reg_write = 1;
                jump = 1;
                jalr_enable = 1; 
                alu_src = 1;
                alu_op = 4'b0000; // ADD for address calculation
            end
            7'b0001111: begin // FENCE & FENCE.I
                // No operations needed for control signals
                alu_op = 4'b1010; // no operation
            end
            7'b1110011: begin // 
                csr_funct3 = funct3;
                case (funct3)
                    3'b000: begin
                        // ECALL or EBREAK
                        alu_op = 4'b1010; // no operation
                    end
                    3'b001: begin
                        // CSRRW
                        reg_write = 1;   
                        csr_write_enable = 1;      
                        csr_op = 2'b00;  
                        csr_addr = csr_addr_raw; 
                        alu_op = 4'b1010; // no operation
                    end
                    3'b010: begin
                        // CSRRS
                        reg_write = 1;
                        csr_write_enable = 1;
                        csr_op = 2'b01;  
                        csr_addr = csr_addr_raw;
                        alu_op = 4'b1010; // no operation
                    end
                    3'b011: begin
                        // CSRRC
                        reg_write = 1;
                        csr_write_enable = 1;
                        csr_op = 2'b10;  
                        csr_addr = csr_addr_raw;
                        alu_op = 4'b1010; // no operation
                    end
                    3'b101: begin
                        // CSRRWI
                        reg_write = 1;
                        csr_write_enable = 1;
                        csr_op = 2'b11;  
                        csr_addr = csr_addr_raw;
                        csr_imm = csr_imm_raw; 
                        alu_op = 4'b1010; // no operation
                    end
                    3'b110: begin
                        // CSRRSI
                        reg_write = 1;
                        csr_write_enable = 1;
                        csr_op = 2'b11;  
                        csr_addr = csr_addr_raw;
                        csr_imm = csr_imm_raw;
                        alu_op = 4'b1010; // no operation
                    end
                    3'b111: begin
                        // CSRRCI
                        reg_write = 1;
                        csr_write_enable = 1;
                        csr_op = 2'b11;   
                        csr_addr = csr_addr_raw;
                        csr_imm = csr_imm_raw;
                        alu_op = 4'b1010; // no operation
                    end
                    default: begin
                        // Other SYSTEM instructions
                        // No operations needed for control signals
                        alu_op = 4'b1111; // invaild operation
                    end
                endcase
            end
            7'b0010111: begin // AUIPC
                reg_write = 1;
                alu_src = 1;
                alu_op = 4'b0000; // ADD for address calculation
            end
            7'b0110111: begin // LUI
                reg_write = 1;
                alu_src = 1;
                alu_op = 4'b1010; // Load Upper Immediate (no ALU operation needed)
            end
            default: begin
                // Unknown instruction
                // All control signals remain at default (0)
                alu_op = 4'b1111; // invaild operation
            end
        endcase
    end
  endmodule


// aluop = 4'b0000: ADD/ADDI/LB/LH/LW/LBU/LHU/SB/SH/SW/AUIPC/JALR (total 12 types)
// aluop = 4'b0001: SUB/BEQ/BNE (total 3 types)
// aluop = 4'b0010: SLT/SLTI/BLT (total 3 types)
// aluop = 4'b0011: SLTU/SLTIU/BLTU/BGEU (total 4 types)
// aluop = 4'b0100: SLL/SLLI (total 2 types)
// aluop = 4'b0101: XOR/XORI (total 2 types)
// aluop = 4'b0110: SRL/SRLI (total 2 types)
// aluop = 4'b0111: SRA/SRAI (total 2 types)
// aluop = 4'b1000: OR/ORI (total 2 types)
// aluop = 4'b1001: AND/ANDI (total 2 types)
// aluop = 4'b1011: BGE (total 1 type)
// aluop = 4'b1010: no operation (for JAL, FENCE, FENCE.I, CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI, LUI, ECALL, EBREAK) (total 12 types)
// aluop = 4'b1111: invaild operation

// csr_op = 2'b00: CSRRW
// csr_op = 2'b01: CSRRS
// csr_op = 2'b10: CSRRC
// csr_op = 2'b11: immediate variants (CSRRWI, CSRRSI, CSRRCI)
// can add exception handling for invaild operation if needed
            

