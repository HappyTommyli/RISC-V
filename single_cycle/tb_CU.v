`timescale 1ns / 1ps

module tb_CU;
    reg [31:0] instruction;  
    wire reg_write;          
    wire mem_to_reg;         
    wire mem_write;          
    wire mem_read;           
    wire alu_src;            
    wire [3:0] alu_op;       
    wire branch;             
    wire jump;              
    wire jalr_enable;        
    wire [11:0] csr_addr;   
    wire csr_write_enable;   
    wire [1:0] csr_op;       
    wire [4:0] csr_imm;      
    wire [2:0] csr_funct3;   

    CU uut(
        .instruction(instruction),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .branch(branch),
        .jump(jump),
        .jalr_enable(jalr_enable),
        .csr_addr(csr_addr),
        .csr_write_enable(csr_write_enable),
        .csr_op(csr_op),
        .csr_imm(csr_imm),
        .csr_funct3(csr_funct3)
    );

    reg clk;
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk; 
    end

    initial begin
    
        instruction = 32'h00000000;
        #20; 

        // -------------------------- opcode=0110011 --------------------------
        $display("\n==================================== [Test 1: R-type Instructions] ====================================");
        // 1.1 ADD (funct7=0000000, funct3=000)
        instruction = 32'h00100013; // add x1, x0, x1
        #20;
        $display("1.1 ADD:");
        $display("Expected: reg_write=1, mem_to_reg=0, mem_write=0, mem_read=0, alu_src=0, alu_op=4'b0000, branch=0, jump=0, jalr_enable=0");
        $display("Actual  : reg_write=%b, mem_to_reg=%b, mem_write=%b, mem_read=%b, alu_src=%b, alu_op=%4b, branch=%b, jump=%b, jalr_enable=%b",
                 reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable);
        assert({reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable} == 13'b1_0_0_0_0_0000_0_0_0) 
        else $error("1.1 ADD Test Failed!");

        // 1.2 SUB (funct7=0100000, funct3=000)
        instruction = 32'h40100013; // sub x1, x0, x1
        #20;
        $display("\n1.2 SUB:");
        $display("Expected: reg_write=1, mem_to_reg=0, mem_write=0, mem_read=0, alu_src=0, alu_op=4'b0001, branch=0, jump=0, jalr_enable=0");
        $display("Actual  : reg_write=%b, mem_to_reg=%b, mem_write=%b, mem_read=%b, alu_src=%b, alu_op=%4b, branch=%b, jump=%b, jalr_enable=%b",
                 reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable);
        assert({reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable} == 13'b1_0_0_0_0_0001_0_0_0) 
        else $error("1.2 SUB Test Failed!");

        // 1.3 SLL (funct7=0000000, funct3=001)
        instruction = 32'h00101013; // sll x1, x0, x1
        #20;
        $display("\n1.3 SLL:");
        $display("Expected: reg_write=1, alu_op=4'b0100");
        $display("Actual  : reg_write=%b, alu_op=%4b", reg_write, alu_op);
        assert({reg_write, alu_op} == 5'b1_0100) else $error("1.3 SLL Test Failed!");

        // 1.4 SLT (funct7=0000000, funct3=010)
        instruction = 32'h00102013; // slt x1, x0, x1
        #20;
        assert({reg_write, alu_op} == 5'b1_0010) else $error("1.4 SLT Test Failed!");

        // 1.5 SLTU (funct7=0000000, funct3=011)
        instruction = 32'h00103013; // sltu x1, x0, x1
        #20;
        assert({reg_write, alu_op} == 5'b1_0011) else $error("1.5 SLTU Test Failed!");

        // 1.6 XOR (funct7=0000000, funct3=100)
        instruction = 32'h00104013; // xor x1, x0, x1
        #20;
        assert({reg_write, alu_op} == 5'b1_0101) else $error("1.6 XOR Test Failed!");

        // 1.7 SRL (funct7=0000000, funct3=101)
        instruction = 32'h00105013; // srl x1, x0, x1
        #20;
        assert({reg_write, alu_op} == 5'b1_0110) else $error("1.7 SRL Test Failed!");

        // 1.8 SRA (funct7=0100000, funct3=105)
        instruction = 32'h40105013; // sra x1, x0, x1
        #20;
        assert({reg_write, alu_op} == 5'b1_0111) else $error("1.8 SRA Test Failed!");

        // 1.9 OR (funct7=0000000, funct3=110)
        instruction = 32'h00106013; // or x1, x0, x1
        #20;
        assert({reg_write, alu_op} == 5'b1_1000) else $error("1.9 OR Test Failed!");

        // 1.10 AND (funct7=0000000, funct3=111)
        instruction = 32'h00107013; // and x1, x0, x1
        #20;
        assert({reg_write, alu_op} == 5'b1_1001) else $error("1.10 AND Test Failed!");

        // 1.11 invalid funct7=1111111, funct3=111
        instruction = 32'h7F107013; 
        #20;
        $display("\n1.11 R-type Invalid Funct:");
        $display("Expected: alu_op=4'b1111");
        $display("Actual  : alu_op=%4b", alu_op);
        assert(alu_op == 4'b1111) else $error("1.11 R-type Invalid Funct Test Failed!");


        // -------------------------- opcode=0010011 --------------------------
        $display("\n==================================== [Test 2: I-type Instructions] ====================================");
        // 2.1 ADDI (funct3=000)
        instruction = 32'h00100013; // addi x1, x0, 1
        #20;
        $display("2.1 ADDI:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        assert({reg_write, alu_src, alu_op} == 6'b1_1_0000) else $error("2.1 ADDI Test Failed!");

        // 2.2 SLLI (funct3=001, funct7=0000000)
        instruction = 32'h00101013; // slli x1, x0, 1
        #20;
        assert({reg_write, alu_src, alu_op} == 6'b1_1_0100) else $error("2.2 SLLI Test Failed!");

        // 2.3 SLTI (funct3=010)
        instruction = 32'h00102013; // slti x1, x0, 1
        #20;
        assert({reg_write, alu_src, alu_op} == 6'b1_1_0010) else $error("2.3 SLTI Test Failed!");

        // 2.4 SLTIU (funct3=011)
        instruction = 32'h00103013; // sltiu x1, x0, 1
        #20;
        assert({reg_write, alu_src, alu_op} == 6'b1_1_0011) else $error("2.4 SLTIU Test Failed!");

        // 2.5 XORI (funct3=100)
        instruction = 32'h00104013; // xori x1, x0, 1
        #20;
        assert({reg_write, alu_src, alu_op} == 6'b1_1_0105) else $error("2.5 XORI Test Failed!");

        // 2.6 SRLI (funct3=105, funct7=0000000)
        instruction = 32'h00105013; // srli x1, x0, 1
        #20;
        assert({reg_write, alu_src, alu_op} == 6'b1_1_0110) else $error("2.6 SRLI Test Failed!");

        // 2.7 SRAI (funct3=105, funct7=0100000)
        instruction = 32'h40105013; // srai x1, x0, 1
        #20;
        assert({reg_write, alu_src, alu_op} == 6'b1_1_0111) else $error("2.7 SRAI Test Failed!");

        // 2.8 ORI (funct3=110)
        instruction = 32'h00106013; // ori x1, x0, 1
        #20;
        assert({reg_write, alu_src, alu_op} == 6'b1_1_1000) else $error("2.8 ORI Test Failed!");

        // 2.9 ANDI (funct3=111)
        instruction = 32'h00107013; // andi x1, x0, 1
        #20;
        assert({reg_write, alu_src, alu_op} == 6'b1_1_1001) else $error("2.9 ANDI Test Failed!");

        // 2.10 invalid funct3=111
        instruction = 32'h00108013; 
        #20;
        assert(alu_op == 4'b1111) else $error("2.10 I-type Invalid Funct3 Test Failed!");


        // -------------------------- opcode=0000011 --------------------------
        $display("\n==================================== [Test 3: Load Instructions] ====================================");
        // 3.1 LB (funct3=000)
        instruction = 32'h00100003; // lb x1, 1(x0)
        #20;
        $display("3.1 LB:");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, mem_to_reg=%b, mem_read=%b, alu_src=%b, alu_op=%4b",
                 reg_write, mem_to_reg, mem_read, alu_src, alu_op);
        assert({reg_write, mem_to_reg, mem_read, alu_src, alu_op} == 9'b1_1_1_1_0000) else $error("3.1 LB Test Failed!");

        // 3.2 LH (funct3=001)
        instruction = 32'h00101003; // lh x1, 1(x0)
        #20;
        assert({reg_write, mem_to_reg, mem_read, alu_src, alu_op} == 9'b1_1_1_1_0000) else $error("3.2 LH Test Failed!");

        // 3.3 LW (funct3=010)
        instruction = 32'h00102003; // lw x1, 1(x0)
        #20;
        assert({reg_write, mem_to_reg, mem_read, alu_src, alu_op} == 9'b1_1_1_1_0000) else $error("3.3 LW Test Failed!");

        // 3.4 LBU (funct3=100)
        instruction = 32'h00104003; // lbu x1, 1(x0)
        #20;
        assert({reg_write, mem_to_reg, mem_read, alu_src, alu_op} == 9'b1_1_1_1_0000) else $error("3.4 LBU Test Failed!");

        // 3.5 LHU (funct3=101)
        instruction = 32'h00105003; // lhu x1, 1(x0)
        #20;
        assert({reg_write, mem_to_reg, mem_read, alu_src, alu_op} == 9'b1_1_1_1_0000) else $error("3.5 LHU Test Failed!");


        // -------------------------- opcode=0100011 --------------------------
        $display("\n==================================== [Test 4: Store Instructions] ====================================");
        // 4.1 SB (funct3=000)
        instruction = 32'h00100023; // sb x1, 1(x0)
        #20;
        $display("4.1 SB:");
        $display("Expected: reg_write=0, mem_write=1, mem_read=0, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, mem_write=%b, mem_read=%b, alu_src=%b, alu_op=%4b",
                 reg_write, mem_write, mem_read, alu_src, alu_op);
        assert({reg_write, mem_write, mem_read, alu_src, alu_op} == 9'b0_1_0_1_0000) else $error("4.1 SB Test Failed!");

        // 4.2 SH (funct3=001)
        instruction = 32'h00101023; // sh x1, 1(x0)
        #20;
        assert({reg_write, mem_write, mem_read, alu_src, alu_op} == 9'b0_1_0_1_0000) else $error("4.2 SH Test Failed!");

        // 4.3 SW (funct3=010)
        instruction = 32'h00102023; // sw x1, 1(x0)
        #20;
        assert({reg_write, mem_write, mem_read, alu_src, alu_op} == 9'b0_1_0_1_0000) else $error("4.3 SW Test Failed!");


        // -------------------------- opcode=1100011 --------------------------
        $display("\n==================================== [Test 5: B-type Instructions] ====================================");
        // 5.1 BEQ (funct3=000)
        instruction = 32'h00100063; // beq x0, x1, 1
        #20;
        $display("5.1 BEQ:");
        $display("Expected: branch=1, alu_op=4'b0001, reg_write=0");
        $display("Actual  : branch=%b, alu_op=%4b, reg_write=%b", branch, alu_op, reg_write);
        assert({branch, alu_op, reg_write} == 6'b1_0001_0) else $error("5.1 BEQ Test Failed!");

        // 5.2 BNE (funct3=001)
        instruction = 32'h00101063; // bne x0, x1, 1
        #20;
        assert({branch, alu_op, reg_write} == 6'b1_0001_0) else $error("5.2 BNE Test Failed!");

        // 5.3 BLT (funct3=100)
        instruction = 32'h00104063; // blt x0, x1, 1
        #20;
        assert({branch, alu_op, reg_write} == 6'b1_0010_0) else $error("5.3 BLT Test Failed!");

        // 5.4 BGE (funct3=101)
        instruction = 32'h00105063; // bge x0, x1, 1
        #20;
        assert({branch, alu_op, reg_write} == 6'b1_1011_0) else $error("5.4 BGE Test Failed!");

        // 5.5 BLTU (funct3=110)
        instruction = 32'h00106063; // bltu x0, x1, 1
        #20;
        assert({branch, alu_op, reg_write} == 6'b1_0011_0) else $error("5.5 BLTU Test Failed!");

        // 5.6 BGEU (funct3=111)
        instruction = 32'h00107063; // bgeu x0, x1, 1
        #20;
        assert({branch, alu_op, reg_write} == 6'b1_0011_0) else $error("5.6 BGEU Test Failed!");

        // 5.7 B型无效funct3
        instruction = 32'h00108063; // 无效funct3
        #20;
        assert(alu_op == 4'b1111) else $error("5.7 B-type Invalid Funct3 Test Failed!");


        // -------------------------- JAL/JALR --------------------------
        $display("\n==================================== [Test 6: Jump Instructions] ====================================");
        // 6.1 JAL (opcode=1101111)
        instruction = 32'h001000EF; // jal x1, 1
        #20;
        $display("6.1 JAL:");
        $display("Expected: jump=1, reg_write=1, alu_op=4'b1010, jalr_enable=0");
        $display("Actual  : jump=%b, reg_write=%b, alu_op=%4b, jalr_enable=%b", jump, reg_write, alu_op, jalr_enable);
        assert({jump, reg_write, alu_op, jalr_enable} == 7'b1_1_1010_0) else $error("6.1 JAL Test Failed!");

        // 6.2 JALR (opcode=1100111)
        instruction = 32'h001000E7; // jalr x1, 1(x0)
        #20;
        $display("\n6.2 JALR:");
        $display("Expected: jump=1, reg_write=1, jalr_enable=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : jump=%b, reg_write=%b, jalr_enable=%b, alu_src=%b, alu_op=%4b",
                 jump, reg_write, jalr_enable, alu_src, alu_op);
        assert({jump, reg_write, jalr_enable, alu_src, alu_op} == 9'b1_1_1_1_0000) else $error("6.2 JALR Test Failed!");


        // -------------------------- opcode=0001111 --------------------------
        $display("\n==================================== [Test 7: FENCE Instructions] ====================================");
        // 7.1 FENCE (funct3=000)
        instruction = 32'h000000F; // fence
        #20;
        $display("7.1 FENCE:");
        $display("Expected: alu_op=4'b1010, all control signals=0 (except alu_op)");
        $display("Actual  : alu_op=%4b, reg_write=%b, mem_write=%b, branch=%b, jump=%b",
                 alu_op, reg_write, mem_write, branch, jump);
        assert({alu_op, reg_write, mem_write, branch, jump} == 9'b1010_0_0_0_0) else $error("7.1 FENCE Test Failed!");

        // 7.2 FENCE.I (funct3=001)
        instruction = 32'h001000F; // fence.i
        #20;
        assert({alu_op, reg_write, mem_write, branch, jump} == 9'b1010_0_0_0_0) else $error("7.2 FENCE.I Test Failed!");


        // -------------------------- opcode=1110011 --------------------------
        $display("\n==================================== [Test 8: SYSTEM/CSR Instructions] ====================================");
        // 8.1 ECALL (funct3=000)
        instruction = 32'h00000073; // ecall
        #20;
        $display("8.1 ECALL:");
        $display("Expected: alu_op=4'b1010, csr_write_enable=0");
        $display("Actual  : alu_op=%4b, csr_write_enable=%b", alu_op, csr_write_enable);
        assert({alu_op, csr_write_enable} == 5'b1010_0) else $error("8.1 ECALL Test Failed!");

        // 8.2 EBREAK (funct3=000)
        instruction = 32'h00100073; // ebreak
        #20;
        assert({alu_op, csr_write_enable} == 5'b1010_0) else $error("8.2 EBREAK Test Failed!");

        // 8.3 CSRRW (funct3=001, csr_addr=0x123)
        instruction = 32'h12300073; // csrrw x0, 0x123, x0
        #20;
        $display("\n8.3 CSRRW:");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=2'b00, csr_addr=12'h123");
        $display("Actual  : reg_write=%b, csr_write_enable=%b, csr_op=%2b, csr_addr=%h",
                 reg_write, csr_write_enable, csr_op, csr_addr);
        assert({reg_write, csr_write_enable, csr_op, csr_addr} == 16'b1_1_00_0000000100100011) else $error("8.3 CSRRW Test Failed!");

        // 8.4 CSRRS (funct3=010, csr_addr=0x456)
        instruction = 32'h45601073; // csrrs x0, 0x456, x0
        #20;
        assert({reg_write, csr_write_enable, csr_op, csr_addr} == 16'b1_1_01_00000001000100110) else $error("8.4 CSRRS Test Failed!");

        // 8.5 CSRRC (funct3=011, csr_addr=0x789)
        instruction = 32'h78902073; // csrrc x0, 0x789, x0
        #20;
        assert({reg_write, csr_write_enable, csr_op, csr_addr} == 16'b1_1_10_000000011110001001) else $error("8.5 CSRRC Test Failed!");

        // 8.6 CSRRWI (funct3=101, csr_addr=0xABC, csr_imm=0x1F)
        instruction = 32'hABC1F273; // csrrwi x0, 0xABC, 0x1F
        #20;
        $display("\n8.6 CSRRWI:");
        $display("Expected: csr_op=2'b11, csr_imm=5'h1F");
        $display("Actual  : csr_op=%2b, csr_imm=%h", csr_op, csr_imm);
        assert({csr_op, csr_imm} == 7'b11_11111) else $error("8.6 CSRRWI Test Failed!");

        // 8.7 CSRRSI (funct3=110, csr_addr=0xDEF, csr_imm=0x0A)
        instruction = 32'hDEF0A373; // csrrsi x0, 0xDEF, 0x0A
        #20;
        assert({csr_op, csr_imm} == 7'b11_01010) else $error("8.7 CSRRSI Test Failed!");

        // 8.8 CSRRCI (funct3=111, csr_addr=0x111, csr_imm=0x05)
        instruction = 32'h11105373; // csrrci x0, 0x111, 0x05
        #20;
        assert({csr_op, csr_imm} == 7'b11_00101) else $error("8.8 CSRRCI Test Failed!");

        // 8.9 SYSTEM Invalid funct3
        instruction = 32'h00008073; 
        #20;
        assert(alu_op == 4'b1111) else $error("8.9 SYSTEM Invalid Funct3 Test Failed!");


        // -------------------------- AUIPC & LUI --------------------------
        $display("\n==================================== [Test 9: AUIPC & LUI] ====================================");
        // 9.1 AUIPC (opcode=0010111)
        instruction = 32'h00100093; // auipc x1, 1
        #20;
        $display("9.1 AUIPC:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        assert({reg_write, alu_src, alu_op} == 6'b1_1_0000) else $error("9.1 AUIPC Test Failed!");

        // 9.2 LUI (opcode=0110111)
        instruction = 32'h001000B7; // lui x1, 1
        #20;
        $display("\n9.2 LUI:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b1010");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        assert({reg_write, alu_src, alu_op} == 6'b1_1_1010) else $error("9.2 LUI Test Failed!");


        // -------------------------- invalid opcode --------------------------
        $display("\n==================================== [Test 10: Invalid Opcode] ====================================");
        instruction = 32'h00000013; // opcode=0000001 (invalid)
        #20;
        $display("10.1 Invalid Opcode:");
        $display("Expected: alu_op=4'b1111, all control signals=0");
        $display("Actual  : alu_op=%4b, reg_write=%b, mem_write=%b, mem_read=%b",
                 alu_op, reg_write, mem_write, mem_read);
        assert({alu_op, reg_write, mem_write, mem_read} == 7'b1111_0_0_0) else $error("10.1 Invalid Opcode Test Failed!");


        // 测试结束
        $display("\n==================================== All Tests Completed! ====================================");
        $finish;
    end
endmodule