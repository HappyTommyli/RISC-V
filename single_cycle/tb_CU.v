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

    // Instantiate CU (no change to port mapping)
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
        #1000; 

        // -------------------------- Test 1: R-type (opcode=0110011) --------------------------
        $display("\n==================================== [Test 1: R-type Instructions] ====================================");
        // 1.1 ADD (opcode=0110011, funct7=0000000, funct3=000)
        instruction = 32'h00100033; // Correct R-type ADD: x1 = x0 + x1
        #200;
        $display("1.1 ADD:");
        $display("Expected: reg_write=1, mem_to_reg=0, mem_write=0, mem_read=0, alu_src=0, alu_op=4'b0000, branch=0, jump=0, jalr_enable=0");
        $display("Actual  : reg_write=%b, mem_to_reg=%b, mem_write=%b, mem_read=%b, alu_src=%b, alu_op=%4b, branch=%b, jump=%b, jalr_enable=%b",
                 reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable);
        if ( {reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable} != 13'b1_0_0_0_0_0000_0_0_0 ) 
        begin
            $error("1.1 ADD Test Failed!");
            $display("  Expected: 13'b1_0_0_0_0_0000_0_0_0");
            $display("  Actual  : 13'b%b", {reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable});
        end

        // 1.2 SUB (opcode=0110011, funct7=0100000, funct3=000)
        instruction = 32'h40100033; // Correct R-type SUB: x1 = x0 - x1
        #2000;
        $display("\n1.2 SUB:");
        $display("Expected: reg_write=1, mem_to_reg=0, mem_write=0, mem_read=0, alu_src=0, alu_op=4'b0001, branch=0, jump=0, jalr_enable=0");
        $display("Actual  : reg_write=%b, mem_to_reg=%b, mem_write=%b, mem_read=%b, alu_src=%b, alu_op=%4b, branch=%b, jump=%b, jalr_enable=%b",
                 reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable);
        if ( {reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable} != 13'b1_0_0_0_0_0001_0_0_0 )
        begin
            $error("1.2 SUB Test Failed!");
        end

        // 1.3 SLL (opcode=0110011, funct7=0000000, funct3=001)
        instruction = 32'h00101033; // R-type SLL: x1 = x0 << x1
        #2000;
        $display("\n1.3 SLL:");
        $display("Expected: reg_write=1, alu_op=4'b0100");
        $display("Actual  : reg_write=%b, alu_op=%4b", reg_write, alu_op);
        if ( {reg_write, alu_op} != 5'b1_0100 )
        begin
            $error("1.3 SLL Test Failed!");
        end

        // 1.4 SLT (opcode=0110011, funct7=0000000, funct3=010)
        instruction = 32'h00102033; // R-type SLT: x1 = (x0 < x1) ? 1 : 0
        #2000;
        if ( {reg_write, alu_op} != 5'b1_0010 )
        begin
            $error("1.4 SLT Test Failed!");
        end

        // 1.5 SLTU (opcode=0110011, funct7=0000000, funct3=011)
        instruction = 32'h00103033; // R-type SLTU
        #200;
        if ( {reg_write, alu_op} != 5'b1_0011 )
        begin
            $error("1.5 SLTU Test Failed!");
        end

        // 1.6 XOR (opcode=0110011, funct7=0000000, funct3=100)
        instruction = 32'h00104033; // R-type XOR
        #200;
        if ( {reg_write, alu_op} != 5'b1_0101 )
        begin
            $error("1.6 XOR Test Failed!");
        end

        // 1.7 SRL (opcode=0110011, funct7=0000000, funct3=105)
        instruction = 32'h00105033; // R-type SRL
        #200;
        if ( {reg_write, alu_op} != 5'b1_0110 )
        begin
            $error("1.7 SRL Test Failed!");
        end

        // 1.8 SRA (opcode=0110011, funct7=0100000, funct3=105)
        instruction = 32'h40105033; // R-type SRA
        #200;
        if ( {reg_write, alu_op} != 5'b1_0111 )
        begin
            $error("1.8 SRA Test Failed!");
        end

        // 1.9 OR (opcode=0110011, funct7=0000000, funct3=110)
        instruction = 32'h00106033; // R-type OR
        #200;
        if ( {reg_write, alu_op} != 5'b1_1000 )
        begin
            $error("1.9 OR Test Failed!");
        end

        // 1.10 AND (opcode=0110011, funct7=0000000, funct3=111)
        instruction = 32'h00107033; // R-type AND
        #200;
        if ( {reg_write, alu_op} != 5'b1_1001 )
        begin
            $error("1.10 AND Test Failed!");
        end

        // 1.11 Invalid R-type (funct7=1111111, funct3=111)
        instruction = 32'h7F107033; // Correct opcode=0110011
        #200;
        $display("\n1.11 R-type Invalid Funct:");
        $display("Expected: alu_op=4'b1111");
        $display("Actual  : alu_op=%4b", alu_op);
        if ( alu_op != 4'b1111 )
        begin
            $error("1.11 R-type Invalid Funct Test Failed!");
        end


        // -------------------------- Test 2: I-type (opcode=0010011) --------------------------
        $display("\n==================================== [Test 2: I-type Instructions] ====================================");
        // 2.1 ADDI (opcode=0010011, funct3=000)
        instruction = 32'h00100013; // Correct I-type ADDI: x1 = x0 + 1
        #200;
        $display("2.1 ADDI:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0000 )
        begin
            $error("2.1 ADDI Test Failed!");
        end

        // 2.2 SLLI (opcode=0010011, funct3=001, funct7=0000000)
        instruction = 32'h00101013; // I-type SLLI
        #200;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0100 )
        begin
            $error("2.2 SLLI Test Failed!");
        end

        // 2.3 SLTI (opcode=0010011, funct3=010)
        instruction = 32'h00102013; // I-type SLTI
        #200;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0010 )
        begin
            $error("2.3 SLTI Test Failed!");
        end

        // 2.4 SLTIU (opcode=0010011, funct3=011)
        instruction = 32'h00103013; // I-type SLTIU
        #200;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0011 )
        begin
            $error("2.4 SLTIU Test Failed!");
        end

        // 2.5 XORI (opcode=0010011, funct3=100)
        instruction = 32'h00104013; // I-type XORI
        #200;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0101 )
        begin
            $error("2.5 XORI Test Failed!");
        end

        // 2.6 SRLI (opcode=0010011, funct3=105, funct7=0000000)
        instruction = 32'h00105013; // I-type SRLI
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0110 )
        begin
            $error("2.6 SRLI Test Failed!");
        end

        // 2.7 SRAI (opcode=0010011, funct3=105, funct7=0100000)
        instruction = 32'h40105013; // I-type SRAI
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0111 )
        begin
            $error("2.7 SRAI Test Failed!");
        end

        // 2.8 ORI (opcode=0010011, funct3=110)
        instruction = 32'h00106013; // I-type ORI
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_1000 )
        begin
            $error("2.8 ORI Test Failed!");
        end

        // 2.9 ANDI (opcode=0010011, funct3=111)
        instruction = 32'h00107013; // I-type ANDI
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_1001 )
        begin
            $error("2.9 ANDI Test Failed!");
        end

        // 2.10 Invalid I-type (funct3=111)
        instruction = 32'h00108013; 
        #20;
        if ( alu_op != 4'b1111 )
        begin
            $error("2.10 I-type Invalid Funct3 Test Failed!");
        end


        // -------------------------- Test 3: Load (opcode=0000011) --------------------------
        $display("\n==================================== [Test 3: Load Instructions] ====================================");
        // 3.1 LB (opcode=0000011, funct3=000)
        instruction = 32'h00100003; // LB x1, 1(x0)
        #20;
        $display("3.1 LB:");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, mem_to_reg=%b, mem_read=%b, alu_src=%b, alu_op=%4b",
                 reg_write, mem_to_reg, mem_read, alu_src, alu_op);
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.1 LB Test Failed!");
        end

        // 3.2 LH (opcode=0000011, funct3=001)
        instruction = 32'h00101003; // LH x1, 1(x0)
        #20;
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.2 LH Test Failed!");
        end

        // 3.3 LW (opcode=0000011, funct3=010)
        instruction = 32'h00102003; // LW x1, 1(x0)
        #20;
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.3 LW Test Failed!");
        end

        // 3.4 LBU (opcode=0000011, funct3=100)
        instruction = 32'h00104003; // LBU x1, 1(x0)
        #20;
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.4 LBU Test Failed!");
        end

        // 3.5 LHU (opcode=0000011, funct3=101)
        instruction = 32'h00105003; // LHU x1, 1(x0)
        #20;
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.5 LHU Test Failed!");
        end


        // -------------------------- Test 4: Store (opcode=0100011) --------------------------
        $display("\n==================================== [Test 4: Store Instructions] ====================================");
        // 4.1 SB (opcode=0100011, funct3=000)
        instruction = 32'h00100023; // SB x1, 1(x0)
        #20;
        $display("4.1 SB:");
        $display("Expected: reg_write=0, mem_write=1, mem_read=0, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, mem_write=%b, mem_read=%b, alu_src=%b, alu_op=%4b",
                 reg_write, mem_write, mem_read, alu_src, alu_op);
        if ( {reg_write, mem_write, mem_read, alu_src, alu_op} != 9'b0_1_0_1_0000 )
        begin
            $error("4.1 SB Test Failed!");
        end

        // 4.2 SH (opcode=0100011, funct3=001)
        instruction = 32'h00101023; // SH x1, 1(x0)
        #20;
        if ( {reg_write, mem_write, mem_read, alu_src, alu_op} != 9'b0_1_0_1_0000 )
        begin
            $error("4.2 SH Test Failed!");
        end

        // 4.3 SW (opcode=0100011, funct3=010)
        instruction = 32'h00102023; // SW x1, 1(x0)
        #20;
        if ( {reg_write, mem_write, mem_read, alu_src, alu_op} != 9'b0_1_0_1_0000 )
        begin
            $error("4.3 SW Test Failed!");
        end


        // -------------------------- Test 5: B-type (opcode=1100011) --------------------------
        $display("\n==================================== [Test 5: B-type Instructions] ====================================");
        // 5.1 BEQ (opcode=1100011, funct3=000)
        instruction = 32'h00100063; // BEQ x0, x1, 1
        #20;
        $display("5.1 BEQ:");
        $display("Expected: branch=1, alu_op=4'b0001, reg_write=0");
        $display("Actual  : branch=%b, alu_op=%4b, reg_write=%b", branch, alu_op, reg_write);
        if ( {branch, alu_op, reg_write} != 6'b1_0001_0 )
        begin
            $error("5.1 BEQ Test Failed!");
        end

        // 5.2 BNE (opcode=1100011, funct3=001)
        instruction = 32'h00101063; // BNE x0, x1, 1
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_0001_0 )
        begin
            $error("5.2 BNE Test Failed!");
        end

        // 5.3 BLT (opcode=1100011, funct3=100)
        instruction = 32'h00104063; // BLT x0, x1, 1
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_0010_0 )
        begin
            $error("5.3 BLT Test Failed!");
        end

        // 5.4 BGE (opcode=1100011, funct3=105)
        instruction = 32'h00105063; // BGE x0, x1, 1
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_1011_0 )
        begin
            $error("5.4 BGE Test Failed!");
        end

        // 5.5 BLTU (opcode=1100011, funct3=110)
        instruction = 32'h00106063; // BLTU x0, x1, 1
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_0011_0 )
        begin
            $error("5.5 BLTU Test Failed!");
        end

        // 5.6 BGEU (opcode=1100011, funct3=111)
        instruction = 32'h00107063; // BGEU x0, x1, 1
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_0011_0 )
        begin
            $error("5.6 BGEU Test Failed!");
        end

        // 5.7 Invalid B-type (funct3=111)
        instruction = 32'h00108063; 
        #20;
        if ( alu_op != 4'b1111 )
        begin
            $error("5.7 B-type Invalid Funct3 Test Failed!");
        end


        // -------------------------- Test 6: Jump (JAL/JALR) --------------------------
        $display("\n==================================== [Test 6: Jump Instructions] ====================================");
        // 6.1 JAL (opcode=1101111)
        instruction = 32'h001000EF; // JAL x1, 1
        #20;
        $display("6.1 JAL:");
        $display("Expected: jump=1, reg_write=1, alu_op=4'b1010, jalr_enable=0");
        $display("Actual  : jump=%b, reg_write=%b, alu_op=%4b, jalr_enable=%b", jump, reg_write, alu_op, jalr_enable);
        if ( {jump, reg_write, alu_op, jalr_enable} != 7'b1_1_1010_0 )
        begin
            $error("6.1 JAL Test Failed!");
        end

        // 6.2 JALR (opcode=1100111)
        instruction = 32'h001000E7; // JALR x1, 1(x0)
        #20;
        $display("\n6.2 JALR:");
        $display("Expected: jump=1, reg_write=1, jalr_enable=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : jump=%b, reg_write=%b, jalr_enable=%b, alu_src=%b, alu_op=%4b",
                 jump, reg_write, jalr_enable, alu_src, alu_op);
        if ( {jump, reg_write, jalr_enable, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("6.2 JALR Test Failed!");
        end


        // -------------------------- Test 7: FENCE (opcode=0001111) --------------------------
        $display("\n==================================== [Test 7: FENCE Instructions] ====================================");
        // 7.1 FENCE (opcode=0001111, funct3=000)
        instruction = 32'h0000000F; // Correct 32-bit FENCE
        #20;
        $display("7.1 FENCE:");
        $display("Expected: alu_op=4'b1010, all control signals=0 (except alu_op)");
        $display("Actual  : alu_op=%4b, reg_write=%b, mem_write=%b, branch=%b, jump=%b",
                 alu_op, reg_write, mem_write, branch, jump);
        if ( {alu_op, reg_write, mem_write, branch, jump} != 9'b1010_0_0_0_0 )
        begin
            $error("7.1 FENCE Test Failed!");
        end

        // 7.2 FENCE.I (opcode=0001111, funct3=001)
        instruction = 32'h0010000F; // Correct 32-bit FENCE.I
        #20;
        if ( {alu_op, reg_write, mem_write, branch, jump} != 9'b1010_0_0_0_0 )
        begin
            $error("7.2 FENCE.I Test Failed!");
        end


        // -------------------------- Test 8: SYSTEM/CSR (opcode=1110011) --------------------------
        $display("\n==================================== [Test 8: SYSTEM/CSR Instructions] ====================================");
        // 8.1 ECALL (opcode=1110011, funct3=000)
        instruction = 32'h00000073; // ECALL
        #20;
        $display("8.1 ECALL:");
        $display("Expected: alu_op=4'b1010, csr_write_enable=0");
        $display("Actual  : alu_op=%4b, csr_write_enable=%b", alu_op, csr_write_enable);
        if ( {alu_op, csr_write_enable} != 5'b1010_0 )
        begin
            $error("8.1 ECALL Test Failed!");
        end

        // 8.2 EBREAK (opcode=1110011, funct3=000)
        instruction = 32'h00100073; // EBREAK
        #20;
        if ( {alu_op, csr_write_enable} != 5'b1010_0 )
        begin
            $error("8.2 EBREAK Test Failed!");
        end

        // 8.3 CSRRW (opcode=1110011, funct3=001, csr_addr=0x123)
        instruction = 32'h12300073; // CSRRW x0, 0x123, x0
        #20;
        $display("\n8.3 CSRRW:");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=2'b00, csr_addr=12'h123");
        $display("Actual  : reg_write=%b, csr_write_enable=%b, csr_op=%2b, csr_addr=%h",
                 reg_write, csr_write_enable, csr_op, csr_addr);
        if ( {reg_write, csr_write_enable, csr_op, csr_addr} != 20'b1_1_00_0000_0001_0010_0011 )
        begin
            $error("8.3 CSRRW Test Failed!");
        end

        // 8.4 CSRRS (opcode=1110011, funct3=010, csr_addr=0x456)
        instruction = 32'h45601073; // CSRRS x0, 0x456, x0
        #20;
        $display("\n8.4 CSRRS:");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=2'b01, csr_addr=12'h456");
        $display("Actual  : reg_write=%b, csr_write_enable=%b, csr_op=%2b, csr_addr=%h",
                 reg_write, csr_write_enable, csr_op, csr_addr);
        if ( {reg_write, csr_write_enable, csr_op, csr_addr} != 20'b1_1_01_00000100010110 ) // 12'h456 = 010001010110
        begin
            $error("8.4 CSRRS Test Failed!");
        end

        // 8.5 CSRRC (opcode=1110011, funct3=011, csr_addr=0x789)
        instruction = 32'h78902073; // CSRRC x0, 0x789, x0
        #20;
        $display("\n8.5 CSRRC:");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=2'b10, csr_addr=12'h789");
        $display("Actual  : reg_write=%b, csr_write_enable=%b, csr_op=%2b, csr_addr=%h",
                 reg_write, csr_write_enable, csr_op, csr_addr);
        if ( {reg_write, csr_write_enable, csr_op, csr_addr} != 20'b1_1_10_000001111001001 ) // 12'h789 = 01111001001 (padded to 12 bits)
        begin
            $error("8.5 CSRRC Test Failed!");
        end

        // 8.6 CSRRWI (opcode=1110011, funct3=101, csr_addr=0xABC, csr_imm=0x1F)
        instruction = 32'hABC1F273; // CSRRWI x0, 0xABC, 0x1F
        #20;
        $display("\n8.6 CSRRWI:");
        $display("Expected: csr_op=2'b11, csr_imm=5'h1F");
        $display("Actual  : csr_op=%2b, csr_imm=%h", csr_op, csr_imm);
        if ( {csr_op, csr_imm} != 7'b11_11111 )
        begin
            $error("8.6 CSRRWI Test Failed!");
        end

        // 8.7 CSRRSI (opcode=1110011, funct3=110, csr_addr=0xDEF, csr_imm=0x0A)
        instruction = 32'hDEF0A373; // CSRRSI x0, 0xDEF, 0x0A
        #20;
        if ( {csr_op, csr_imm} != 7'b11_01010 )
        begin
            $error("8.7 CSRRSI Test Failed!");
        end

        // 8.8 CSRRCI (opcode=1110011, funct3=111, csr_addr=0x111, csr_imm=0x05)
        instruction = 32'h11105373; // CSRRCI x0, 0x111, 0x05
        #20;
        if ( {csr_op, csr_imm} != 7'b11_00101 )
        begin
            $error("8.8 CSRRCI Test Failed!");
        end

        // 8.9 Invalid SYSTEM (funct3=100)
        instruction = 32'h00008073; 
        #20;
        if ( alu_op != 4'b1111 )
        begin
            $error("8.9 SYSTEM Invalid Funct3 Test Failed!");
        end


        // -------------------------- Test 9: AUIPC & LUI --------------------------
        $display("\n==================================== [Test 9: AUIPC & LUI] ====================================");
        // 9.1 AUIPC (opcode=0010111)
        instruction = 32'h00100093; // AUIPC x1, 1
        #20;
        $display("9.1 AUIPC:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0000 )
        begin
            $error("9.1 AUIPC Test Failed!");
        end

        // 9.2 LUI (opcode=0110111)
        instruction = 32'h001000B7; // LUI x1, 1
        #20;
        $display("\n9.2 LUI:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b1010");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_1010 )
        begin
            $error("9.2 LUI Test Failed!");
        end


        // -------------------------- Test 10: Invalid Opcode --------------------------
        $display("\n==================================== [Test 10: Invalid Opcode] ====================================");
        instruction = 32'h00000013; // opcode=0000001 (invalid)
        #20;
        $display("10.1 Invalid Opcode:");
        $display("Expected: alu_op=4'b1111, all control signals=0");
        $display("Actual  : alu_op=%4b, reg_write=%b, mem_write=%b, mem_read=%b",
                 alu_op, reg_write, mem_write, mem_read);
        if ( {alu_op, reg_write, mem_write, mem_read} != 7'b1111_0_0_0 )
        begin
            $error("10.1 Invalid Opcode Test Failed!");
        end


        $display("\n==================================== All Tests Completed! ====================================");
        $finish;
    end
endmodule