`timescale 1ns / 1ps

module tb_CU;

    // Input and output signals
    reg [31:0] instruction;
    wire reg_write, mem_to_reg, mem_write, mem_read, alu_src, branch, jump, jalr_enable, csr_write_enable;
    wire [3:0] alu_op;
    wire [11:0] csr_addr;
    wire [1:0] csr_op;
    wire [4:0] csr_imm;
    wire [2:0] csr_funct3;

    // Expected signals
    reg exp_reg_write, exp_mem_to_reg, exp_mem_write, exp_mem_read, exp_alu_src, exp_branch, exp_jump, exp_jalr_enable, exp_csr_write_enable;
    reg [3:0] exp_alu_op;
    reg [11:0] exp_csr_addr;
    reg [1:0] exp_csr_op;
    reg [4:0] exp_csr_imm;
    reg [2:0] exp_csr_funct3;

    // Instantiate the Device Under Test (DUT) - Control Unit
    CU uut (
        .instruction(instruction),
        .reg_write(reg_write), .mem_to_reg(mem_to_reg), .mem_write(mem_write), .mem_read(mem_read),
        .alu_src(alu_src), .alu_op(alu_op), .branch(branch), .jump(jump), .jalr_enable(jalr_enable),
        .csr_addr(csr_addr), .csr_write_enable(csr_write_enable), .csr_op(csr_op), .csr_imm(csr_imm), .csr_funct3(csr_funct3)
    );

    // Test sequence: 47 instructions
    initial begin
        // Step 1: 1000ns idle state initially
        $display("=====================================================");
        $display("CU Test Case (47 Instructions) - Initial 1000ns Idle");
        $display("=====================================================");
        instruction = 32'h00000000;
        #1000;
        $display("\nIdle state ended - Starting 47-instruction test\n");


        // =====================================================
        // Group 1: R-type instructions (10)
        // Opcode: 0110011
        // =====================================================
        // 1. ADD rd, rs1, rs2 → ADD x1, x2, x3 (0b 0000000 00011 00010 000 00001 0110011 = 0x003100B3)
        $display("-----------------------------------------------------");
        $display("Instruction 1/47: R-type - ADD x1, x2, x3");
        $display("Encoding: 0x003100B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 000");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0000; others=0");
        instruction = 32'h003100B3;
        exp_reg_write=1; exp_mem_to_reg=0; exp_mem_write=0; exp_mem_read=0; exp_alu_src=0; exp_alu_op=4'b0000;
        exp_branch=0; exp_jump=0; exp_jalr_enable=0; exp_csr_addr=12'h000; exp_csr_write_enable=0; exp_csr_op=2'b00; exp_csr_imm=5'h00; exp_csr_funct3=3'b000;
        #10; 
        display_all_outputs("ADD", 1);
        check_all_signals("ADD", 1);
        #100;

        // 2. SUB rd, rs1, rs2 → SUB x1, x2, x3 (0b 0100000 00011 00010 000 00001 0110011 = 0x403100B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 2/47: R-type - SUB x1, x2, x3");
        $display("Encoding: 0x403100B3 | Opcode: 0110011 | Funct7: 0100000 | Funct3: 000");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0001; others=0");
        instruction = 32'h403100B3;
        exp_alu_op=4'b0001;
        #10; 
        display_all_outputs("SUB", 2);
        check_all_signals("SUB", 2);
        #100;

        // 3. SLL rd, rs1, rs2 → SLL x1, x2, x3 (0b 0000000 00011 00010 001 00001 0110011 = 0x003110B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 3/47: R-type - SLL x1, x2, x3");
        $display("Encoding: 0x003110B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 001");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0100; others=0");
        instruction = 32'h003110B3;
        exp_alu_op=4'b0100;
        #10; 
        display_all_outputs("SLL", 3);
        check_all_signals("SLL", 3);
        #100;

        // 4. SLT rd, rs1, rs2 → SLT x1, x2, x3 (0b 0000000 00011 00010 010 00001 0110011 = 0x003120B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 4/47: R-type - SLT x1, x2, x3");
        $display("Encoding: 0x003120B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 010");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0010; others=0");
        instruction = 32'h003120B3;
        exp_alu_op=4'b0010;
        #10; 
        display_all_outputs("SLT", 4);
        check_all_signals("SLT", 4);
        #100;

        // 5. SLTU rd, rs1, rs2 → SLTU x1, x2, x3 (0b 0000000 00011 00010 011 00001 0110011 = 0x003130B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 5/47: R-type - SLTU x1, x2, x3");
        $display("Encoding: 0x003130B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 011");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0011; others=0");
        instruction = 32'h003130B3;
        exp_alu_op=4'b0011;
        #10; 
        display_all_outputs("SLTU", 5);
        check_all_signals("SLTU", 5);
        #100;

        // 6. XOR rd, rs1, rs2 → XOR x1, x2, x3 (0b 0000000 00011 00010 100 00001 0110011 = 0x003140B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 6/47: R-type - XOR x1, x2, x3");
        $display("Encoding: 0x003140B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 100");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0101; others=0");
        instruction = 32'h003140B3;
        exp_alu_op=4'b0101;
        #10; 
        display_all_outputs("XOR", 6);
        check_all_signals("XOR", 6);
        #100;

        // 7. SRL rd, rs1, rs2 → SRL x1, x2, x3 (0b 0000000 00011 00010 101 00001 0110011 = 0x003150B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 7/47: R-type - SRL x1, x2, x3");
        $display("Encoding: 0x003150B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 101");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0110; others=0");
        instruction = 32'h003150B3;
        exp_alu_op=4'b0110;
        #10; 
        display_all_outputs("SRL", 7);
        check_all_signals("SRL", 7);
        #100;

        // 8. SRA rd, rs1, rs2 → SRA x1, x2, x3 (0b 0100000 00011 00010 101 00001 0110011 = 0x403150B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 8/47: R-type - SRA x1, x2, x3");
        $display("Encoding: 0x403150B3 | Opcode: 0110011 | Funct7: 0100000 | Funct3: 101");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0111; others=0");
        instruction = 32'h403150B3;
        exp_alu_op=4'b0111;
        #10; 
        display_all_outputs("SRA", 8);
        check_all_signals("SRA", 8);
        #100;

        // 9. OR rd, rs1, rs2 → OR x1, x2, x3 (0b 0000000 00011 00010 110 00001 0110011 = 0x003160B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 9/47: R-type - OR x1, x2, x3");
        $display("Encoding: 0x003160B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 110");
        $display("Expected: reg_write=1, alu_src=0, alu_op=1000; others=0");
        instruction = 32'h003160B3;
        exp_alu_op=4'b1000;
        #10; 
        display_all_outputs("OR", 9);
        check_all_signals("OR", 9);
        #100;

        // 10. AND rd, rs1, rs2 → AND x1, x2, x3 (0b 0000000 00011 00010 111 00001 0110011 = 0x003170B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 10/47: R-type - AND x1, x2, x3");
        $display("Encoding: 0x003170B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 111");
        $display("Expected: reg_write=1, alu_src=0, alu_op=1001; others=0");
        instruction = 32'h003170B3;
        exp_alu_op=4'b1001;
        #10; 
        display_all_outputs("AND", 10);
        check_all_signals("AND", 10);
        #100;


        // =====================================================
        // Group 2: I-type instructions (Arithmetic/Shift) - 9
        // Opcode: 0010011
        // =====================================================
        // 11. ADDI rd, rs1, imm → ADDI x1, x2, 4 (0b 000000000100 00010 000 00001 0010011 = 0x00410093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 11/47: I-type - ADDI x1, x2, 4");
        $display("Encoding: 0x00410093 | Opcode: 0010011 | Funct3: 000");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00410093;
        exp_alu_src=1; exp_alu_op=4'b0000; exp_reg_write=1;
        #10; 
        display_all_outputs("ADDI", 11);
        check_all_signals("ADDI", 11);
        #100;

        // 12. SLTI rd, rs1, imm → SLTI x1, x2, 4 (0b 000000000100 00010 010 00001 0010011 = 0x00412093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 12/47: I-type - SLTI x1, x2, 4");
        $display("Encoding: 0x00412093 | Opcode: 0010011 | Funct3: 010");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0010; others=0");
        instruction = 32'h00412093;
        exp_alu_op=4'b0010;
        #10; 
        display_all_outputs("SLTI", 12);
        check_all_signals("SLTI", 12);
        #100;

        // 13. SLTIU rd, rs1, imm → SLTIU x1, x2, 4 (0b 000000000100 00010 011 00001 0010011 = 0x00413093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 13/47: I-type - SLTIU x1, x2, 4");
        $display("Encoding: 0x00413093 | Opcode: 0010011 | Funct3: 011");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0011; others=0");
        instruction = 32'h00413093;
        exp_alu_op=4'b0011;
        #10; 
        display_all_outputs("SLTIU", 13);
        check_all_signals("SLTIU", 13);
        #100;

        // 14. XORI rd, rs1, imm → XORI x1, x2, 4 (0b 000000000100 00010 100 00001 0010011 = 0x00414093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 14/47: I-type - XORI x1, x2, 4");
        $display("Encoding: 0x00414093 | Opcode: 0010011 | Funct3: 100");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0105; others=0");
        instruction = 32'h00414093;
        exp_alu_op=4'b0105;
        #10; 
        display_all_outputs("XORI", 14);
        check_all_signals("XORI", 14);
        #100;

        // 15. ORI rd, rs1, imm → ORI x1, x2, 4 (0b 000000000100 00010 110 00001 0010011 = 0x00416093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 15/47: I-type - ORI x1, x2, 4");
        $display("Encoding: 0x00416093 | Opcode: 0010011 | Funct3: 110");
        $display("Expected: reg_write=1, alu_src=1, alu_op=1000; others=0");
        instruction = 32'h00416093;
        exp_alu_op=4'b1000;
        #10; 
        display_all_outputs("ORI", 15);
        check_all_signals("ORI", 15);
        #100;

        // 16. ANDI rd, rs1, imm → ANDI x1, x2, 4 (0b 000000000100 00010 111 00001 0010011 = 0x00417093) 
        $display("\n-----------------------------------------------------");
        $display("Instruction 16/47: I-type - ANDI x1, x2, 4");
        $display("Encoding: 0x00417093 | Opcode: 0010011 | Funct3: 111");
        $display("Expected: reg_write=1, alu_src=1, alu_op=1009; others=0");
        instruction = 32'h00417093;
        exp_alu_op=4'b1009;  
        #10; 
        display_all_outputs("ANDI", 16);
        check_all_signals("ANDI", 16);
        #100;

        // 17. SLLI rd, rs1, imm → SLLI x1, x2, 4 (0b 000000000100 00010 001 00001 0010011 = 0x00411093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 17/47: I-type - SLLI x1, x2, 4");
        $display("Encoding: 0x00411093 | Opcode: 0010011 | Funct3: 001 | Funct7: 0000000");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0100; others=0");
        instruction = 32'h00411093;
        exp_alu_op=4'b0100;
        #10; 
        display_all_outputs("SLLI", 17);
        check_all_signals("SLLI", 17);
        #100;

        // 18. SRLI rd, rs1, imm → SRLI x1, x2, 4 (0b 000000000100 00010 101 00001 0010011 = 0x00415093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 18/47: I-type - SRLI x1, x2, 4");
        $display("Encoding: 0x00415093 | Opcode: 0010011 | Funct3: 101 | Funct7: 0000000");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0110; others=0");
        instruction = 32'h00415093;
        exp_alu_op=4'b0110;
        #10; 
        display_all_outputs("SRLI", 18);
        check_all_signals("SRLI", 18);
        #100;

        // 19. SRAI rd, rs1, imm → SRAI x1, x2, 4 (0b 010000000100 00010 101 00001 0010011 = 0x40415093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 19/47: I-type - SRAI x1, x2, 4");
        $display("Encoding: 0x40415093 | Opcode: 0010011 | Funct3: 101 | Funct7: 0100000");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0111; others=0");
        instruction = 32'h40415093; // 注：用户原表Line91为0x00415093，修正为SRAI专属编码（Funct7=0100000）
        exp_alu_op=4'b0111;
        #10; 
        display_all_outputs("SRAI", 19);
        check_all_signals("SRAI", 19);
        #100;


        // =====================================================
        // Group 3: Load instructions - 5
        // Opcode: 0000011
        // =====================================================
        // 20. LB rd, imm(rs1) → LB x1, 4(x2) (0b 000000000100 00010 000 00001 0000011 = 0x00410083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 20/47: Load - LB x1, 4(x2)");
        $display("Encoding: 0x00410083 | Opcode: 0000011 | Funct3: 000");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00410083;
        exp_reg_write=1; exp_mem_to_reg=1; exp_mem_read=1; exp_alu_src=1; exp_alu_op=4'b0000;
        exp_mem_write=0; exp_branch=0; exp_jump=0; exp_jalr_enable=0;
        #10; 
        display_all_outputs("LB", 20);
        check_all_signals("LB", 20);
        #100;

        // 21. LH rd, imm(rs1) → LH x1, 4(x2) (0b 000000000100 00010 001 00001 0000011 = 0x00411083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 21/47: Load - LH x1, 4(x2)");
        $display("Encoding: 0x00411083 | Opcode: 0000011 | Funct3: 001");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00411083;
        // 继承Group3默认预期信号，无需重复赋值
        #10; 
        display_all_outputs("LH", 21);
        check_all_signals("LH", 21);
        #100;

        // 22. LW rd, imm(rs1) → LW x1, 4(x2) (0b 000000000100 00010 010 00001 0000011 = 0x00412083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 22/47: Load - LW x1, 4(x2)");
        $display("Encoding: 0x00412083 | Opcode: 0000011 | Funct3: 010");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00412083;
        #10; 
        display_all_outputs("LW", 22);
        check_all_signals("LW", 22);
        #100;

        // 23. LBU rd, imm(rs1) → LBU x1, 4(x2) (0b 000000000100 00010 100 00001 0000011 = 0x00414083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 23/47: Load - LBU x1, 4(x2)");
        $display("Encoding: 0x00414083 | Opcode: 0000011 | Funct3: 100");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00414083;
        #10; 
        display_all_outputs("LBU", 23);
        check_all_signals("LBU", 23);
        #100;

        // 24. LHU rd, imm(rs1) → LHU x1, 4(x2) (0b 000000000100 00010 101 00001 0000011 = 0x00415083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 24/47: Load - LHU x1, 4(x2)");
        $display("Encoding: 0x00415083 | Opcode: 0000011 | Funct3: 101");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00415083;
        #10; 
        display_all_outputs("LHU", 24);
        check_all_signals("LHU", 24);
        #100;


        // =====================================================
        // Group 4: Store instructions - 3
        // Opcode: 0100011
        // =====================================================
        // 25. SB rs2, imm(rs1) → SB x3, 4(x2) (0b 0000000 00011 00010 000 00100 0100011 = 0x00310223)
        $display("\n-----------------------------------------------------");
        $display("Instruction 25/47: Store - SB x3, 4(x2)");
        $display("Encoding: 0x00310223 | Opcode: 0100011 | Funct3: 000");
        $display("Expected: mem_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00310223;
        exp_reg_write=0; exp_mem_to_reg=0; exp_mem_write=1; exp_mem_read=0;
        exp_alu_src=1; exp_alu_op=4'b0000; exp_branch=0; exp_jump=0;
        #10; 
        display_all_outputs("SB", 25);
        check_all_signals("SB", 25);
        #100;

        // 26. SH rs2, imm(rs1) → SH x3, 4(x2) (0b 0000000 00011 00010 001 00100 0100011 = 0x00311223)
        $display("\n-----------------------------------------------------");
        $display("Instruction 26/47: Store - SH x3, 4(x2)");
        $display("Encoding: 0x00311223 | Opcode: 0100011 | Funct3: 001");
        $display("Expected: mem_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00311223;
        // 继承Group4默认预期信号
        #10; 
        display_all_outputs("SH", 26);
        check_all_signals("SH", 26);
        #100;

        // 27. SW rs2, imm(rs1) → SW x3, 4(x2) (0b 0000000 00011 00010 010 00100 0100011 = 0x00312223)
        $display("\n-----------------------------------------------------");
        $display("Instruction 27/47: Store - SW x3, 4(x2)");
        $display("Encoding: 0x00312223 | Opcode: 0100011 | Funct3: 010");
        $display("Expected: mem_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00312223;
        #10; 
        display_all_outputs("SW", 27);
        check_all_signals("SW", 27);
        #100;


        // =====================================================
        // Group 5: B-type instructions - 6
        // Opcode: 1100011
        // =====================================================
        // 28. BEQ rs1, rs2, imm → BEQ x2, x3, 4 (0b 0 000000 00011 00010 000 0100 0 1100011 = 0x00310263)
        $display("\n-----------------------------------------------------");
        $display("Instruction 28/47: B-type - BEQ x2, x3, 4");
        $display("Encoding: 0x00310263 | Opcode: 1100011 | Funct3: 000");
        $display("Expected: branch=1, alu_src=0, alu_op=0001; others=0");
        instruction = 32'h00310263;
        exp_reg_write=0; exp_mem_to_reg=0; exp_mem_write=0; exp_mem_read=0;
        exp_branch=1; exp_alu_src=0; exp_alu_op=4'b0001; exp_jump=0; exp_jalr_enable=0;
        #10; 
        display_all_outputs("BEQ", 28);
        check_all_signals("BEQ", 28);
        #100;

        // 29. BNE rs1, rs2, imm → BNE x2, x3, 4 (0b 0 000000 00011 00010 001 0100 0 1100011 = 0x00311263)
        $display("\n-----------------------------------------------------");
        $display("Instruction 29/47: B-type - BNE x2, x3, 4");
        $display("Encoding: 0x00311263 | Opcode: 1100011 | Funct3: 001");
        $display("Expected: branch=1, alu_src=0, alu_op=0001; others=0");
        instruction = 32'h00311263;
        // 继承BEQ的alu_op=0001
        #10; 
        display_all_outputs("BNE", 29);
        check_all_signals("BNE", 29);
        #100;

        // 30. BLT rs1, rs2, imm → BLT x2, x3, 4 (0b 0 000000 00011 00010 100 0100 0 1100011 = 0x00314263)
        $display("\n-----------------------------------------------------");
        $display("Instruction 30/47: B-type - BLT x2, x3, 4");
        $display("Encoding: 0x00314263 | Opcode: 1100011 | Funct3: 100");
        $display("Expected: branch=1, alu_src=0, alu_op=0010; others=0");
        instruction = 32'h00314263;
        exp_alu_op=4'b0010;
        #10; 
        display_all_outputs("BLT", 30);
        check_all_signals("BLT", 30);
        #100;

        // 31. BGE rs1, rs2, imm → BGE x2, x3, 4 (0b 0 000000 00011 00010 101 0100 0 1100011 = 0x00315263)
        $display("\n-----------------------------------------------------");
        $display("Instruction 31/47: B-type - BGE x2, x3, 4");
        $display("Encoding: 0x00315263 | Opcode: 1100011 | Funct3: 101");
        $display("Expected: branch=1, alu_src=0, alu_op=1011; others=0");
        instruction = 32'h00315263;
        exp_alu_op=4'b1011;
        #10; 
        display_all_outputs("BGE", 31);
        check_all_signals("BGE", 31);
        #100;

        // 32. BLTU rs1, rs2, imm → BLTU x2, x3, 4 (0b 0 000000 00011 00010 110 0100 0 1100011 = 0x00316263)
        $display("\n-----------------------------------------------------");
        $display("Instruction 32/47: B-type - BLTU x2, x3, 4");
        $display("Encoding: 0x00316263 | Opcode: 1100011 | Funct3: 110");
        $display("Expected: branch=1, alu_src=0, alu_op=0011; others=0");
        instruction = 32'h00316263;
        exp_alu_op=4'b0011;
        #10; 
        display_all_outputs("BLTU", 32);
        check_all_signals("BLTU", 32);
        #100;

        // 33. BGEU rs1, rs2, imm → BGEU x2, x3, 4 (0b 0 000000 00011 00010 111 0100 0 1100011 = 0x00317263)
        $display("\n-----------------------------------------------------");
        $display("Instruction 33/47: B-type - BGEU x2, x3, 4");
        $display("Encoding: 0x00317263 | Opcode: 1100011 | Funct3: 111");
        $display("Expected: branch=1, alu_src=0, alu_op=0011; others=0");
        instruction = 32'h00317263;
        // 继承BLTU的alu_op=0011
        #10; 
        display_all_outputs("BGEU", 33);
        check_all_signals("BGEU", 33);
        #100;


        // =====================================================
        // Group 6: Jump instructions - 2
        // =====================================================
        // 34. JAL rd, imm → JAL x1, 4 (0b 0 0000000100 0 00000100 00001 1101111 = 0x004000EF)
        $display("\n-----------------------------------------------------");
        $display("Instruction 34/47: Jump - JAL x1, 4");
        $display("Encoding: 0x004000EF | Opcode: 1101111");
        $display("Expected: reg_write=1, jump=1, alu_op=1010; others=0");
        instruction = 32'h004000EF;
        exp_reg_write=1; exp_jump=1; exp_branch=0; exp_jalr_enable=0;
        exp_alu_op=4'b1010; exp_alu_src=0; exp_mem_write=0; exp_mem_read=0;
        #10; 
        display_all_outputs("JAL", 34);
        check_all_signals("JAL", 34);
        #100;

        // 35. JALR rd, imm(rs1) → JALR x1, 4(x2) (0b 000000000100 00010 000 00001 1100111 = 0x004100E7)
        $display("\n-----------------------------------------------------");
        $display("Instruction 35/47: Jump - JALR x1, 4(x2)");
        $display("Encoding: 0x004100E7 | Opcode: 1100111 | Funct3: 000");
        $display("Expected: reg_write=1, jump=1, jalr_enable=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h004100E7;
        exp_reg_write=1; exp_jump=1; exp_jalr_enable=1; exp_alu_src=1;
        exp_alu_op=4'b0000; exp_branch=0; exp_mem_write=0; exp_mem_read=0;
        #10; 
        display_all_outputs("JALR", 35);
        check_all_signals("JALR", 35);
        #100;


        // =====================================================
        // Group 7: Barrier instructions - 2
        // Opcode: 0001111
        // =====================================================
        // 36. FENCE → FENCE (0b 000011110000 00000 000 00000 0001111 = 0x0FF0000F)
        $display("\n-----------------------------------------------------");
        $display("Instruction 36/47: Barrier - FENCE");
        $display("Encoding: 0x0FF0000F | Opcode: 0001111 | Funct3: 000");
        $display("Expected: alu_op=1010; others=0");
        instruction = 32'h0FF0000F;
        exp_reg_write=0; exp_jump=0; exp_jalr_enable=0; exp_branch=0;
        exp_mem_write=0; exp_mem_read=0; exp_alu_src=0; exp_alu_op=4'b1010;
        #10; 
        display_all_outputs("FENCE", 36);
        check_all_signals("FENCE", 36);
        #100;

        // 37. FENCE.I → FENCE.I (0b 000000000001 00000 001 00000 0001111 = 0x0000100F)
        $display("\n-----------------------------------------------------");
        $display("Instruction 37/47: Barrier - FENCE.I");
        $display("Encoding: 0x0000100F | Opcode: 0001111 | Funct3: 001");
        $display("Expected: alu_op=1010; others=0");
        instruction = 32'h0000100F;
        // 继承FENCE的预期信号
        #10; 
        display_all_outputs("FENCE.I", 37);
        check_all_signals("FENCE.I", 37);
        #100;


        // =====================================================
        // Group 8: Upper instructions - 2
        // =====================================================
        // 38. LUI rd, imm → LUI x1, 4 (0b 00000000000000000100 00001 0110111 = 0x00400037)
        $display("\n-----------------------------------------------------");
        $display("Instruction 38/47: Upper - LUI x1, 4");
        $display("Encoding: 0x00400037 | Opcode: 0110111"); // 注：用户原表Line201为0x000000B7，修正为LUI正确编码
        $display("Expected: reg_write=1, alu_src=1, alu_op=1010; others=0");
        instruction = 32'h00400037;
        exp_reg_write=1; exp_alu_src=1; exp_alu_op=4'b1010;
        exp_jump=0; exp_branch=0; exp_mem_write=0; exp_mem_read=0;
        #10; 
        display_all_outputs("LUI", 38);
        check_all_signals("LUI", 38);
        #100;

        // 39. AUIPC rd, imm → AUIPC x1, 4 (0b 00000000000000000100 00001 0010111 = 0x00400017)
        $display("\n-----------------------------------------------------");
        $display("Instruction 39/47: Upper - AUIPC x1, 4");
        $display("Encoding: 0x00400017 | Opcode: 0010111"); // 注：用户原表Line205为0x00000097，修正为AUIPC正确编码
        $display("Expected: reg_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00400017;
        exp_reg_write=1; exp_alu_src=1; exp_alu_op=4'b0000;
        // 继承LUI的其他默认信号
        #10; 
        display_all_outputs("AUIPC", 39);
        check_all_signals("AUIPC", 39);
        #100;


        // =====================================================
        // Group 9: SYSTEM instructions - 8
        // Opcode: 1110011
        // =====================================================
        // 40. ECALL → ECALL (0b 000000000000 00000 000 00000 1110011 = 0x00000073)
        $display("\n-----------------------------------------------------");
        $display("Instruction 40/47: SYSTEM - ECALL");
        $display("Encoding: 0x00000073 | Opcode: 1110011 | Funct3: 000");
        $display("Expected: alu_op=1010; others=0");
        instruction = 32'h00000073;
        exp_reg_write=0; exp_alu_src=0; exp_alu_op=4'b1010;
        exp_jump=0; exp_branch=0; exp_mem_write=0; exp_mem_read=0; exp_csr_write_enable=0;
        #10; 
        display_all_outputs("ECALL", 40);
        check_all_signals("ECALL", 40);
        #100;

        // 41. EBREAK → EBREAK (0b 000000000001 00000 000 00000 1110011 = 0x00100073)
        $display("\n-----------------------------------------------------");
        $display("Instruction 41/47: SYSTEM - EBREAK");
        $display("Encoding: 0x00100073 | Opcode: 1110011 | Funct3: 000");
        $display("Expected: alu_op=1010; others=0");
        instruction = 32'h00100073;
        // 继承ECALL的预期信号
        #10; 
        display_all_outputs("EBREAK", 41);
        check_all_signals("EBREAK", 41);
        #100;

        // 42. CSRRW rd, csr, rs1 → CSRRW x1, 0x123, x2 (0b 000100100011 00010 001 00001 1110011 = 0x123110F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 42/47: SYSTEM - CSRRW x1, 0x123, x2");
        $display("Encoding: 0x123110F3 | Opcode: 1110011 | Funct3: 001 | CSR: 0x123");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=00, csr_addr=0x123, alu_op=1010; others=0");
        instruction = 32'h123110F3;
        exp_reg_write=1; exp_csr_write_enable=1; exp_csr_op=2'b00; exp_csr_addr=12'h123;
        exp_alu_op=4'b1010; exp_alu_src=0; exp_jump=0; exp_branch=0; exp_mem_write=0; exp_mem_read=0;
        #10; 
        display_all_outputs("CSRRW", 42);
        check_all_signals("CSRRW", 42);
        #100;

        // 43. CSRRS rd, csr, rs1 → CSRRS x1, 0x123, x2 (0b 000100100011 00010 010 00001 1110011 = 0x123120F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 43/47: SYSTEM - CSRRS x1, 0x123, x2");
        $display("Encoding: 0x123120F3 | Opcode: 1110011 | Funct3: 010 | CSR: 0x123");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=01, csr_addr=0x123, alu_op=1010; others=0");
        instruction = 32'h123120F3;
        exp_csr_op=2'b01; // 仅修改csr_op，其他继承CSRRW
        #10; 
        display_all_outputs("CSRRS", 43);
        check_all_signals("CSRRS", 43);
        #100;

        // 44. CSRRC rd, csr, rs1 → CSRRC x1, 0x123, x2 (0b 000100100011 00010 011 00001 1110011 = 0x123130F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 44/47: SYSTEM - CSRRC x1, 0x123, x2");
        $display("Encoding: 0x123130F3 | Opcode: 1110011 | Funct3: 011 | CSR: 0x123");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=10, csr_addr=0x123, alu_op=1010; others=0");
        instruction = 32'h123130F3;
        exp_csr_op=2'b10;
        #10; 
        display_all_outputs("CSRRC", 44);
        check_all_signals("CSRRC", 44);
        #100;

        // 45. CSRRWI rd, csr, imm → CSRRWI x1, 0x123, 5 (0b 000100100011 00010 101 00001 1110011 = 0x1232D0F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 45/47: SYSTEM - CSRRWI x1, 0x123, 5");
        $display("Encoding: 0x1232D0F3 | Opcode: 1110011 | Funct3: 101 | CSR: 0x123 | Imm:5");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=11, csr_addr=0x123, csr_imm=5'h05, alu_op=1010; others=0");
        instruction = 32'h1232D0F3;
        exp_csr_op=2'b11; exp_csr_imm=5'h05;
        #10; 
        display_all_outputs("CSRRWI", 45);
        check_all_signals("CSRRWI", 45);
        #100;

        // 46. CSRRSI rd, csr, imm → CSRRSI x1, 0x123, 5 (0b 000100100011 00010 110 00001 1110011 = 0x1232E0F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 46/47: SYSTEM - CSRRSI x1, 0x123, 5");
        $display("Encoding: 0x1232E0F3 | Opcode: 1110011 | Funct3: 110 | CSR: 0x123 | Imm:5");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=11, csr_addr=0x123, csr_imm=5'h05, alu_op=1010; others=0");
        instruction = 32'h1232E0F3;
        // 继承CSRRWI的csr_op=11和csr_imm=5'h05
        #10; 
        display_all_outputs("CSRRSI", 46);
        check_all_signals("CSRRSI", 46);
        #100;

        // 47. CSRRCI rd, csr, imm → CSRRCI x1, 0x123, 5 (0b 000100100011 00010 111 00001 1110011 = 0x1232F0F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 47/47: SYSTEM - CSRRCI x1, 0x123, 5");
        $display("Encoding: 0x1232F0F3 | Opcode: 1110011 | Funct3: 111 | CSR: 0x123 | Imm:5");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=11, csr_addr=0x123, csr_imm=5'h05, alu_op=1010; others=0");
        instruction = 32'h1232F0F3;
        // 继承CSRRWI的预期信号
        #10; 
        display_all_outputs("CSRRCI", 47);
        check_all_signals("CSRRCI", 47);
        #100;


        // Test completion
        $display("\n=====================================================");
        $display("All 47 instructions tested - Testbench completed");
        $display("=====================================================");
        $finish;
    end

    // Task to display all outputs
    task display_all_outputs;
        input [8*20:1] instr_name;
        input integer instr_num;
        begin
            $display("--- Outputs for %s (Instruction %0d) ---", instr_name, instr_num);
            $display("reg_write = %b, mem_to_reg = %b, mem_write = %b, mem_read = %b", 
                     reg_write, mem_to_reg, mem_write, mem_read);
            $display("alu_src = %b, alu_op = 4'b%b, branch = %b, jump = %b", 
                     alu_src, alu_op, branch, jump);
            $display("jalr_enable = %b, csr_write_enable = %b", 
                     jalr_enable, csr_write_enable);
            $display("csr_addr = 12'h%h, csr_op = 2'b%b, csr_imm = 5'b%b, csr_funct3 = 3'b%b", 
                     csr_addr, csr_op, csr_imm, csr_funct3);
        end
    endtask

    // Task to check all signals against expected values
    task check_all_signals;
        input [8*20:1] instr_name;
        input integer instr_num;
        integer error_count;
        begin
            error_count = 0;
            
            if (reg_write !== exp_reg_write) begin
                $display("ERROR: reg_write = %b, expected %b", reg_write, exp_reg_write);
                error_count = error_count + 1;
            end
            if (mem_to_reg !== exp_mem_to_reg) begin
                $display("ERROR: mem_to_reg = %b, expected %b", mem_to_reg, exp_mem_to_reg);
                error_count = error_count + 1;
            end
            if (mem_write !== exp_mem_write) begin
                $display("ERROR: mem_write = %b, expected %b", mem_write, exp_mem_write);
                error_count = error_count + 1;
            end
            if (mem_read !== exp_mem_read) begin
                $display("ERROR: mem_read = %b, expected %b", mem_read, exp_mem_read);
                error_count = error_count + 1;
            end
            if (alu_src !== exp_alu_src) begin
                $display("ERROR: alu_src = %b, expected %b", alu_src, exp_alu_src);
                error_count = error_count + 1;
            end
            if (alu_op !== exp_alu_op) begin
                $display("ERROR: alu_op = 4'b%b, expected 4'b%b", alu_op, exp_alu_op);
                error_count = error_count + 1;
            end
            if (branch !== exp_branch) begin
                $display("ERROR: branch = %b, expected %b", branch, exp_branch);
                error_count = error_count + 1;
            end
            if (jump !== exp_jump) begin
                $display("ERROR: jump = %b, expected %b", jump, exp_jump);
                error_count = error_count + 1;
            end
            if (jalr_enable !== exp_jalr_enable) begin
                $display("ERROR: jalr_enable = %b, expected %b", jalr_enable, exp_jalr_enable);
                error_count = error_count + 1;
            end
            if (csr_write_enable !== exp_csr_write_enable) begin
                $display("ERROR: csr_write_enable = %b, expected %b", csr_write_enable, exp_csr_write_enable);
                error_count = error_count + 1;
            end
            if (csr_addr !== exp_csr_addr) begin
                $display("ERROR: csr_addr = 12'h%h, expected 12'h%h", csr_addr, exp_csr_addr);
                error_count = error_count + 1;
            end
            if (csr_op !== exp_csr_op) begin
                $display("ERROR: csr_op = 2'b%b, expected 2'b%b", csr_op, exp_csr_op);
                error_count = error_count + 1;
            end
            if (csr_imm !== exp_csr_imm) begin
                $display("ERROR: csr_imm = 5'b%b, expected 5'b%b", csr_imm, exp_csr_imm);
                error_count = error_count + 1;
            end
            if (csr_funct3 !== exp_csr_funct3) begin
                $display("ERROR: csr_funct3 = 3'b%b, expected 3'b%b", csr_funct3, exp_csr_funct3);
                error_count = error_count + 1;
            end
            
            if (error_count == 0) begin
                $display("✓ All signals match expected values");
            end else begin
                $display("✗ Found %0d errors in %s", error_count, instr_name);
            end
        end
    endtask

endmodule

