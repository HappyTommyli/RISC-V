module CU  ( input wire [31:0] instruction,
               output reg reg_write,
               output reg mem_to_reg,
               output reg mem_write,
               output reg mem_read,
               output reg alu_src,
               output reg [3:0] alu_op,
               output reg branch,
               output reg jump
             );
  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;
  assign opcode = instruction[6:0];
  assign funct3 = instruction[14:12];
  assign funct7 = instruction[31:25];
  always @(*)
  begin
    // Default values
    reg_write = 0;
    mem_to_reg = 0;
    mem_write = 0;
    mem_read = 0;
    alu_src = 0;
    alu_op = 4'b0000;
    branch = 0;
    jump = 0;

    case (opcode)
      7'b0110011:
      begin // R-type
        reg_write = 1;
        alu_src = 0;
        case ({funct7, funct3})
          10'b0000000000:
            alu_op = 4'b0000; // ADD
          10'b0100000000:
            alu_op = 4'b0001; // SUB
          10'b0000000001:
            alu_op = 4'b0100; // SLL
          10'b0000000010:
            alu_op = 4'b0010; // SLT
          10'b0000000011:
            alu_op = 4'b0011; // SLTU
          10'b0000000100:
            alu_op = 4'b0101; // XOR
          10'b0000000101:
            alu_op = 4'b0110; // SRL
          10'b0100000101:
            alu_op = 4'b0111; // SRA
          10'b0000000110:
            alu_op = 4'b1000; // OR
          10'b0000000111:
            alu_op = 4'b1001; // AND
          default:
            alu_op = 4'b1111; // no-operation
        endcase
      end
      7'b0010011:
      begin // I-type
        reg_write = 1;
        alu_src = 1;
        case (funct3)
          3'b000:
            alu_op = 4'b0010; // ADDI
          3'b001:
            alu_op = 4'b0100; // SLLI
          3'b101:
          begin
            if (funct7 == 7'b0000000)
              alu_op = 4'b0110; // SRLI
            else if (funct7 == 7'b0100000)
              alu_op = 4'b0111; // SRAI
            else
              alu_op = 4'b1111; // no operation
          end
          3'b010:
            alu_op = 4'b0010; // SLTI
          3'b011:
            alu_op = 4'b0011; // SLTIU
          3'b100:
            alu_op = 4'b0101; // XORI
          3'b110:
            alu_op = 4'b1000; // ORI
          3'b111:
            alu_op = 4'b1001; // ANDI
          default:
            alu_op = 4'b1111; // no operation
        endcase
      end
      7'b0000011:
      begin // Load
        reg_write = 1;
        mem_to_reg = 1;
        mem_read = 1;
        alu_src = 1;
        alu_op = 4'b0000; // ADD for address calculation
      end
      7'b0100011:
      begin // Store
        mem_write = 1;
        alu_src = 1;
        alu_op = 4'b0000; // ADD for address calculation
      end
      7'b1100011:
      begin // Branch
        branch = 1;
        alu_src = 0;
        case (funct3)
          3'b000:
            alu_op = 4'b0001; // BEQ
          3'b001:
            alu_op = 4'b0001; // BNE
          3'b100:
            alu_op = 4'b0010; // BLT
          3'b101:
            alu_op = 4'b0010; // BGE
          3'b110:
            alu_op = 4'b0011; // BLTU
          3'b111:
            alu_op = 4'b0011; // BGEU
          default:
            alu_op = 4'b1111; // no operation
        endcase
      end
      7'b1101111:
      begin // JAL
        reg_write = 1;
        jump = 1;
        alu_op = 4'b1111; // no ALU operation needed
      end
      7'b1100111:
      begin // JALR
        reg_write = 1;
        jump = 1;
        alu_src = 1;
        alu_op = 4'b0000; // ADD for address calculation
      end
      7'b0001111:
      begin // FENCE & FENCE.I
        // No operations needed for control signals
      end
      7'b1110011:
      begin //
        case (funct3)
          3'b000:
          begin
            // ECALL or EBREAK
            // No operations needed for control signals
          end
          3'b001:
          begin
            // CSRRW
            reg_write = 1;
            alu_src = 1;
            alu_op = 4'b0000; // ADD for address calculation
          end
          3'b010:
          begin
            // CSRRS
            reg_write = 1;
            alu_src = 1;
            alu_op = 4'b0000; // ADD for address calculation
          end
          3'b011:
          begin
            // CSRRC
            reg_write = 1;
            alu_src = 1;
            alu_op = 4'b0000; // ADD for address calculation
          end
          3'b101:
          begin
            // CSRRWI
            reg_write = 1;
            alu_src = 1;
            alu_op = 4'b0000; // ADD for address calculation
          end
          3'b110:
          begin
            // CSRRSI
            reg_write = 1;
            alu_src = 1;
            alu_op = 4'b0000; // ADD for address calculation
          end
          3'b111:
          begin
            // CSRRCI
            reg_write = 1;
            alu_src = 1;
            alu_op = 4'b0000; // ADD for address calculation
          end
          default:
          begin
            // Other SYSTEM instructions
            // No operations needed for control signals
          end
        end
        7'b0010111:
        begin // AUIPC
          reg_write = 1;
          alu_src = 1;
          alu_op = 4'b0000; // ADD for address calculation
        end
        7'b0110111:
        begin // LUI
          reg_write = 1;
          alu_src = 1;
          alu_op = 4'b1111; // no ALU operation needed
        end
        default:
        begin
          // Unknown instruction
          // All control signals remain at default (0)
        end
      endcase
    end
  endmodule


