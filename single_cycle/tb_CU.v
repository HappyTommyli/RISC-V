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
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 2. SUB rd, rs1, rs2 → SUB x1, x2, x3 (0b 0100000 00011 00010 000 00001 0110011 = 0x403100B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 2/47: R-type - SUB x1, x2, x3");
        $display("Encoding: 0x403100B3 | Opcode: 0110011 | Funct7: 0100000 | Funct3: 000");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0001; others=0");
        instruction = 32'h403100B3;
        exp_alu_op=4'b0001;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 3. SLL rd, rs1, rs2 → SLL x1, x2, x3 (0b 0000000 00011 00010 001 00001 0110011 = 0x003110B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 3/47: R-type - SLL x1, x2, x3");
        $display("Encoding: 0x003110B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 001");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0100; others=0");
        instruction = 32'h003110B3;
        exp_alu_op=4'b0100;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 4. SLT rd, rs1, rs2 → SLT x1, x2, x3 (0b 0000000 00011 00010 010 00001 0110011 = 0x003120B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 4/47: R-type - SLT x1, x2, x3");
        $display("Encoding: 0x003120B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 010");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0010; others=0");
        instruction = 32'h003120B3;
        exp_alu_op=4'b0010;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 5. SLTU rd, rs1, rs2 → SLTU x1, x2, x3 (0b 0000000 00011 00010 011 00001 0110011 = 0x003130B3))
        $display("\n-----------------------------------------------------");
        $display("Instruction 5/47: R-type - SLTU x1, x2, x3");
        $display("Encoding: 0x003130B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 011");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0011; others=0");
        instruction = 32'h003130B3;
        exp_alu_op=4'b0011;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 6. XOR rd, rs1, rs2 → XOR x1, x2, x3 (0b 0000000 00011 00010 100 00001 0110011 = 0x003140B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 6/47: R-type - XOR x1, x2, x3");
        $display("Encoding: 0x003140B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 100");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0101; others=0");
        instruction = 32'h003140B3;
        exp_alu_op=4'b0101;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 7. SRL rd, rs1, rs2 → SRL x1, x2, x3 (0b 0000000 00011 00010 101 00001 0110011 = 0x003150B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 7/47: R-type - SRL x1, x2, x3");
        $display("Encoding: 0x003150B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 101");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0110; others=0");
        instruction = 32'h003150B3;
        exp_alu_op=4'b0110;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 8. SRA rd, rs1, rs2 → SRA x1, x2, x3 (0b 0100000 00011 00010 101 00001 0110011 = 0x403150B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 8/47: R-type - SRA x1, x2, x3");
        $display("Encoding: 0x403150B3 | Opcode: 0110011 | Funct7: 0100000 | Funct3: 101");
        $display("Expected: reg_write=1, alu_src=0, alu_op=0111; others=0");
        instruction = 32'h403150B3;
        exp_alu_op=4'b0111;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 9. OR rd, rs1, rs2 → OR x1, x2, x3 (0b 0000000 00011 00010 110 00001 0110011 = 0x003160B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 9/47: R-type - OR x1, x2, x3");
        $display("Encoding: 0x003160B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 110");
        $display("Expected: reg_write=1, alu_src=0, alu_op=1000; others=0");
        instruction = 32'h003160B3;
        exp_alu_op=4'b1000;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;

        // 10. AND rd, rs1, rs2 → AND x1, x2, x3 (0b 0000000 00011 00010 111 00001 0110011 = 0x003170B3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 10/47: R-type - AND x1, x2, x3");
        $display("Encoding: 0x003170B3 | Opcode: 0110011 | Funct7: 0000000 | Funct3: 111");
        $display("Expected: reg_write=1, alu_src=0, alu_op=1001; others=0");
        instruction = 32'h003170B3;
        exp_alu_op=4'b1001;
        #10; $display("Actual: reg_write=%b, alu_op=4'b%b | Match: %b", reg_write, alu_op, (reg_write==exp_reg_write && alu_op==exp_alu_op));
        #100;


        // =====================================================
        // Group 2: I-type instructions (Arithmetic/Shift) - 9
        // Opcode: 0010011
        // =====================================================
        // 11. ADDI rd, rs1, imm → ADDI x1, x2, 3 (0b 000000000011 00010 000 00001 0010011 = 0x00310093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 11/47: I-type - ADDI x1, x2, 3");
        $display("Encoding: 0x00310093 | Opcode: 0010011 | Funct3: 000");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00310093;
        exp_alu_src=1; exp_alu_op=4'b0000;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 12. SLTI rd, rs1, imm → SLTI x1, x2, 3 (0b 000000000011 00010 010 00001 0010011 = 0x00312093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 12/47: I-type - SLTI x1, x2, 3");
        $display("Encoding: 0x00312093 | Opcode: 0010011 | Funct3: 010");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0010; others=0");
        instruction = 32'h00312093;
        exp_alu_op=4'b0010;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 13. SLTIU rd, rs1, imm → SLTIU x1, x2, 3 (0b 000000000011 00010 011 00001 0010011 = 0x00313093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 13/47: I-type - SLTIU x1, x2, 3");
        $display("Encoding: 0x00313093 | Opcode: 0010011 | Funct3: 011");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0011; others=0");
        instruction = 32'h00313093;
        exp_alu_op=4'b0011;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 14. XORI rd, rs1, imm → XORI x1, x2, 3 (0b 000000000011 00010 100 00001 0010011 = 0x00314093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 14/47: I-type - XORI x1, x2, 3");
        $display("Encoding: 0x00314093 | Opcode: 0010011 | Funct3: 100");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0101; others=0");
        instruction = 32'h00314093;
        exp_alu_op=4'b0101;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 15. ORI rd, rs1, imm → ORI x1, x2, 3 (0b 000000000011 00010 110 00001 0010011 = 0x00316093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 15/47: I-type - ORI x1, x2, 3");
        $display("Encoding: 0x00316093 | Opcode: 0010011 | Funct3: 110");
        $display("Expected: reg_write=1, alu_src=1, alu_op=1000; others=0");
        instruction = 32'h00316093;
        exp_alu_op=4'b1000;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 16. ANDI rd, rs1, imm → ANDI x1, x2, 3 (0b 000000000011 00010 111 00001 0010011 = 0x00317093) 
        $display("\n-----------------------------------------------------");
        $display("Instruction 16/47: I-type - ANDI x1, x2, 3");
        $display("Encoding: 0x00317093 | Opcode: 0010011 | Funct3: 111");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b1001; others=0");
        instruction = 32'h00317093;
        exp_alu_op=4'b1001;  
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 17. SLLI rd, rs1, imm → SLLI x1, x2, 3 (0b 000000000011 00010 001 00001 0010011 = 0x00311093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 17/47: I-type - SLLI x1, x2, 3");
        $display("Encoding: 0x00311093 | Opcode: 0010011 | Funct3: 001 | Funct7: 0000000");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0100; others=0");
        instruction = 32'h00311093;
        exp_alu_op=4'b0100;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 18. SRLI rd, rs1, imm → SRLI x1, x2, 3 (0b 000000000011 00010 101 00001 0010011 = 0x00315093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 18/47: I-type - SRLI x1, x2, 3");
        $display("Encoding: 0x00315093 | Opcode: 0010011 | Funct3: 101 | Funct7: 0000000");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0110; others=0");
        instruction = 32'h00315093;
        exp_alu_op=4'b0110;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 19. SRAI rd, rs1, imm → SRAI x1, x2, 3 (0b 010000000011 00010 101 00001 0010011 = 0x40315093)
        $display("\n-----------------------------------------------------");
        $display("Instruction 19/47: I-type - SRAI x1, x2, 3");
        $display("Encoding: 0x40315093 | Opcode: 0010011 | Funct3: 101 | Funct7: 0100000");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0111; others=0");
        instruction = 32'h40315093;
        exp_alu_op=4'b0111;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;


        // =====================================================
        // Group 3: Load instructions - 5
        // Opcode: 0000011
        // =====================================================
        // 20. LB rd, imm(rs1) → LB x1, 3(x2) (0b 000000000011 00010 000 00001 0000011 = 0x00310083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 20/47: Load - LB x1, 3(x2)");
        $display("Encoding: 0x00310083 | Opcode: 0000011 | Funct3: 000");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00310083;
        exp_mem_to_reg=1; exp_mem_read=1; exp_alu_op=4'b0000;
        #10; $display("Actual: reg_write=%b, mem_read=%b, alu_op=4'b%b | Match: %b", reg_write, mem_read, alu_op, (reg_write==exp_reg_write && mem_read==exp_mem_read && alu_op==exp_alu_op));
        #100;

        // 21. LH rd, imm(rs1) → LH x1, 3(x2) (0b 000000000011 00010 001 00001 0000011 = 0x00311083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 21/47: Load - LH x1, 3(x2)");
        $display("Encoding: 0x00311083 | Opcode: 0000011 | Funct3: 001");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00311083;
        #10; $display("Actual: reg_write=%b, mem_read=%b, alu_op=4'b%b | Match: %b", reg_write, mem_read, alu_op, (reg_write==exp_reg_write && mem_read==exp_mem_read && alu_op==exp_alu_op));
        #100;

        // 22. LW rd, imm(rs1) → LW x1, 3(x2) (0b 000000000011 00010 010 00001 0000011 = 0x00312083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 22/47: Load - LW x1, 3(x2)");
        $display("Encoding: 0x00312083 | Opcode: 0000011 | Funct3: 010");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00312083;
        #10; $display("Actual: reg_write=%b, mem_read=%b, alu_op=4'b%b | Match: %b", reg_write, mem_read, alu_op, (reg_write==exp_reg_write && mem_read==exp_mem_read && alu_op==exp_alu_op));
        #100;

        // 23. LBU rd, imm(rs1) → LBU x1, 3(x2) (0b 000000000011 00010 100 00001 0000011 = 0x00314083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 23/47: Load - LBU x1, 3(x2)");
        $display("Encoding: 0x00314083 | Opcode: 0000011 | Funct3: 100");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00314083;
        #10; $display("Actual: reg_write=%b, mem_read=%b, alu_op=4'b%b | Match: %b", reg_write, mem_read, alu_op, (reg_write==exp_reg_write && mem_read==exp_mem_read && alu_op==exp_alu_op));
        #100;

        // 24. LHU rd, imm(rs1) → LHU x1, 3(x2) (0b 000000000011 00010 101 00001 0000011 = 0x00315083)
        $display("\n-----------------------------------------------------");
        $display("Instruction 24/47: Load - LHU x1, 3(x2)");
        $display("Encoding: 0x00315083 | Opcode: 0000011 | Funct3: 101");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00315083;
        #10; $display("Actual: reg_write=%b, mem_read=%b, alu_op=4'b%b | Match: %b", reg_write, mem_read, alu_op, (reg_write==exp_reg_write && mem_read==exp_mem_read && alu_op==exp_alu_op));
        #100;


        // =====================================================
        // Group 4: Store instructions - 3
        // Opcode: 0100011
        // =====================================================
        // 25. SB rs2, imm(rs1) → SB x3, 3(x2) (0b 0000000 00011 00010 000 00011 0100011 = 0x00310023)
        $display("\n-----------------------------------------------------");
        $display("Instruction 25/47: Store - SB x3, 3(x2)");
        $display("Encoding: 0x00310023 | Opcode: 0100011 | Funct3: 000");
        $display("Expected: mem_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00310023;
        exp_reg_write=0; exp_mem_to_reg=0; exp_mem_write=1; exp_mem_read=0; exp_alu_op=4'b0000;
        #10; $display("Actual: mem_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", mem_write, alu_src, alu_op, (mem_write==exp_mem_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 26. SH rs2, imm(rs1) → SH x3, 3(x2) (0b 0000000 00011 00010 001 00010 0100011 = 0x00311023)
        $display("\n-----------------------------------------------------");
        $display("Instruction 26/47: Store - SH x3, 3(x2)");
        $display("Encoding: 0x00311023 | Opcode: 0100011 | Funct3: 001");
        $display("Expected: mem_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00311023;
        #10; $display("Actual: mem_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", mem_write, alu_src, alu_op, (mem_write==exp_mem_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 27. SW rs2, imm(rs1) → SW x3, 3(x2) (0b 0000000 00011 00010 010 00010 0100011 = 0x00312023)
        $display("\n-----------------------------------------------------");
        $display("Instruction 27/47: Store - SW x3, 3(x2)");
        $display("Encoding: 0x00312023 | Opcode: 0100011 | Funct3: 010");
        $display("Expected: mem_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00312023;
        #10; $display("Actual: mem_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", mem_write, alu_src, alu_op, (mem_write==exp_mem_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;


        // =====================================================
        // Group 5: B-type instructions - 6
        // Opcode: 1100011
        // =====================================================
        // 28. BEQ rs1, rs2, imm → BEQ x2, x3, 3 (0b 0000000 00011 00010 000 00110 1100011 = 0x00310363)
        $display("\n-----------------------------------------------------");
        $display("Instruction 28/47: B-type - BEQ x2, x3, 3");
        $display("Encoding: 0x00310363 | Opcode: 1100011 | Funct3: 000");
        $display("Expected: branch=1, alu_op=0001; others=0");
        instruction = 32'h00310363;
        exp_branch=1; exp_alu_src=0; exp_alu_op=4'b0001; exp_mem_write=0;
        #10; $display("Actual: branch=%b, alu_op=4'b%b | Match: %b", branch, alu_op, (branch==exp_branch && alu_op==exp_alu_op));
        #100;

        // 29. BNE rs1, rs2, imm → BNE x2, x3, 3 (0x00311063)
        $display("\n-----------------------------------------------------");
        $display("Instruction 29/47: B-type - BNE x2, x3, 3");
        $display("Encoding: 0x00311063 | Opcode: 1100011 | Funct3: 001");
        $display("Expected: branch=1, alu_op=0001; others=0");
        instruction = 32'h00311063;
        #10; $display("Actual: branch=%b, alu_op=4'b%b | Match: %b", branch, alu_op, (branch==exp_branch && alu_op==exp_alu_op));
        #100;

        // 30. BLT rs1, rs2, imm → BLT x2, x3, 3 (0x00314063)
        $display("\n-----------------------------------------------------");
        $display("Instruction 30/47: B-type - BLT x2, x3, 3");
        $display("Encoding: 0x00314063 | Opcode: 1100011 | Funct3: 100");
        $display("Expected: branch=1, alu_op=0010; others=0");
        instruction = 32'h00314063;
        exp_alu_op=4'b0010;
        #10; $display("Actual: branch=%b, alu_op=4'b%b | Match: %b", branch, alu_op, (branch==exp_branch && alu_op==exp_alu_op));
        #100;

        // 31. BGE rs1, rs2, imm → BGE x2, x3, 3 (0x00315063)
        $display("\n-----------------------------------------------------");
        $display("Instruction 31/47: B-type - BGE x2, x3, 3");
        $display("Encoding: 0x00315063 | Opcode: 1100011 | Funct3: 101");
        $display("Expected: branch=1, alu_op=1011; others=0");
        instruction = 32'h00315063;
        exp_alu_op=4'b1011;
        #10; $display("Actual: branch=%b, alu_op=4'b%b | Match: %b", branch, alu_op, (branch==exp_branch && alu_op==exp_alu_op));
        #100;

        // 32. BLTU rs1, rs2, imm → BLTU x2, x3, 3 (0x00316063)
        $display("\n-----------------------------------------------------");
        $display("Instruction 32/47: B-type - BLTU x2, x3, 3");
        $display("Encoding: 0x00316063 | Opcode: 1100011 | Funct3: 110");
        $display("Expected: branch=1, alu_op=0011; others=0");
        instruction = 32'h00316063;
        exp_alu_op=4'b0011;
        #10; $display("Actual: branch=%b, alu_op=4'b%b | Match: %b", branch, alu_op, (branch==exp_branch && alu_op==exp_alu_op));
        #100;

        // 33. BGEU rs1, rs2, imm → BGEU x2, x3, 3 (0x00317063)
        $display("\n-----------------------------------------------------");
        $display("Instruction 33/47: B-type - BGEU x2, x3, 3");
        $display("Encoding: 0x00317063 | Opcode: 1100011 | Funct3: 111");
        $display("Expected: branch=1, alu_op=0011; others=0");
        instruction = 32'h00317063;
        #10; $display("Actual: branch=%b, alu_op=4'b%b | Match: %b", branch, alu_op, (branch==exp_branch && alu_op==exp_alu_op));
        #100;


        // =====================================================
        // Group 6: Jump instructions - 2
        // =====================================================
        // 34. JAL rd, imm → JAL x1, 3 (0x003000EF)
        $display("\n-----------------------------------------------------");
        $display("Instruction 34/47: Jump - JAL x1, 3");
        $display("Encoding: 0x003000EF | Opcode: 1101111");
        $display("Expected: reg_write=1, jump=1, alu_op=1010; others=0");
        instruction = 32'h003000EF;
        exp_reg_write=1; exp_jump=1; exp_branch=0; exp_alu_op=4'b1010;
        #10; $display("Actual: reg_write=%b, jump=%b, alu_op=4'b%b | Match: %b", reg_write, jump, alu_op, (reg_write==exp_reg_write && jump==exp_jump && alu_op==exp_alu_op));
        #100;

        // 35. JALR rd, imm(rs1) → JALR x1, 3(x2) (0x003100E7)
        $display("\n-----------------------------------------------------");
        $display("Instruction 35/47: Jump - JALR x1, 3(x2)");
        $display("Encoding: 0x003100E7 | Opcode: 1100111 | Funct3: 000");
        $display("Expected: reg_write=1, jump=1, jalr_enable=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h003100E7;
        exp_jalr_enable=1; exp_alu_src=1; exp_alu_op=4'b0000;
        #10; $display("Actual: reg_write=%b, jalr_enable=%b, alu_op=4'b%b | Match: %b", reg_write, jalr_enable, alu_op, (reg_write==exp_reg_write && jalr_enable==exp_jalr_enable && alu_op==exp_alu_op));
        #100;


        // =====================================================
        // Group 7: Barrier instructions - 2
        // Opcode: 0001111
        // =====================================================
        // 36. FENCE → FENCE (0x0000000F)
        $display("\n-----------------------------------------------------");
        $display("Instruction 36/47: Barrier - FENCE");
        $display("Encoding: 0x0000000F | Opcode: 0001111 | Funct3: 000");
        $display("Expected: alu_op=1010; others=0");
        instruction = 32'h0000000F;
        exp_reg_write=0; exp_jump=0; exp_jalr_enable=0; exp_alu_op=4'b1010;
        #10; $display("Actual: alu_op=4'b%b | Match: %b", alu_op, (alu_op==exp_alu_op));
        #100;

        // 37. FENCE.I → FENCE.I (0x0000100F)
        $display("\n-----------------------------------------------------");
        $display("Instruction 37/47: Barrier - FENCE.I");
        $display("Encoding: 0x0000100F | Opcode: 0001111 | Funct3: 001");
        $display("Expected: alu_op=1010; others=0");
        instruction = 32'h0000100F;
        #10; $display("Actual: alu_op=4'b%b | Match: %b", alu_op, (alu_op==exp_alu_op));
        #100;


        // =====================================================
        // Group 8: Upper instructions - 2
        // =====================================================
        // 38. LUI rd, imm → LUI x1, 3 (0x00300037)
        $display("\n-----------------------------------------------------");
        $display("Instruction 38/47: Upper - LUI x1, 3");
        $display("Encoding: 0x00310037 | Opcode: 0110111");
        $display("Expected: reg_write=1, alu_src=1, alu_op=1010; others=0");
        instruction = 32'h00300037;
        exp_reg_write=1; exp_alu_src=1; exp_alu_op=4'b1010;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;

        // 39. AUIPC rd, imm → AUIPC x1, 3 (0x00300017)
        $display("\n-----------------------------------------------------");
        $display("Instruction 39/47: Upper - AUIPC x1, 3");
        $display("Encoding: 0x00310017 | Opcode: 0010111");
        $display("Expected: reg_write=1, alu_src=1, alu_op=0000; others=0");
        instruction = 32'h00300017;
        exp_alu_op=4'b0000;
        #10; $display("Actual: reg_write=%b, alu_src=%b, alu_op=4'b%b | Match: %b", reg_write, alu_src, alu_op, (reg_write==exp_reg_write && alu_src==exp_alu_src && alu_op==exp_alu_op));
        #100;


        // =====================================================
        // Group 9: SYSTEM instructions - 8
        // Opcode: 1110011
        // =====================================================
        // 40. ECALL → ECALL (0x00000073)
        $display("\n-----------------------------------------------------");
        $display("Instruction 40/47: SYSTEM - ECALL");
        $display("Encoding: 0x00000073 | Opcode: 1110011 | Funct3: 000");
        $display("Expected: alu_op=1010; others=0");
        instruction = 32'h00000073;
        exp_reg_write=0; exp_alu_src=0; exp_alu_op=4'b1010;
        #10; $display("Actual: alu_op=4'b%b | Match: %b", alu_op, (alu_op==exp_alu_op));
        #100;

        // 41. EBREAK → EBREAK (0x00100073)
        $display("\n-----------------------------------------------------");
        $display("Instruction 41/47: SYSTEM - EBREAK");
        $display("Encoding: 0x00100073 | Opcode: 1110011 | Funct3: 000");
        $display("Expected: alu_op=1010; others=0");
        instruction = 32'h00100073;
        #10; $display("Actual: alu_op=4'b%b | Match: %b", alu_op, (alu_op==exp_alu_op));
        #100;

        // 42. CSRRW rd, csr, rs1 → CSRRW x1, 0x123, x2 (0x12320073)
        $display("\n-----------------------------------------------------");
        $display("Instruction 42/47: SYSTEM - CSRRW x1, 0x123, x2");
        $display("Encoding: 0x12310073 | Opcode: 1110011 | Funct3: 001 | CSR: 0x123");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=00, csr_addr=0x123, alu_op=1010; others=0");
        instruction = 32'h12320073;
        exp_reg_write=1; exp_csr_write_enable=1; exp_csr_op=2'b00; exp_csr_addr=12'h123; exp_alu_op=4'b1010;
        #10; $display("Actual: reg_write=%b, csr_write_enable=%b, csr_addr=0x%03X | Match: %b", reg_write, csr_write_enable, csr_addr, (reg_write==exp_reg_write && csr_write_enable==exp_csr_write_enable && csr_addr==exp_csr_addr));
        #100;

        // 43. CSRRS rd, csr, rs1 → CSRRS x1, 0x123, x2 (0x12311073)
        $display("\n-----------------------------------------------------");
        $display("Instruction 43/47: SYSTEM - CSRRS x1, 0x123, x2");
        $display("Encoding: 0x12311073 | Opcode: 1110011 | Funct3: 010 | CSR: 0x123");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=01, csr_addr=0x123, alu_op=1010; others=0");
        instruction = 32'h12311073;
        exp_csr_op=2'b01;
        #10; $display("Actual: reg_write=%b, csr_write_enable=%b, csr_addr=0x%03X | Match: %b", reg_write, csr_write_enable, csr_addr, (reg_write==exp_reg_write && csr_write_enable==exp_csr_write_enable && csr_addr==exp_csr_addr));
        #100;

        // 44. CSRRC rd, csr, rs1 → CSRRC x1, 0x123, x2 (0x12312073)
        $display("\n-----------------------------------------------------");
        $display("Instruction 44/47: SYSTEM - CSRRC x1, 0x123, x2");
        $display("Encoding: 0x12312073 | Opcode: 1110011 | Funct3: 011 | CSR: 0x123");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=10, csr_addr=0x123, alu_op=1010; others=0");
        instruction = 32'h12312073;
        exp_csr_op=2'b10;
        #10; $display("Actual: reg_write=%b, csr_write_enable=%b, csr_addr=0x%03X | Match: %b", reg_write, csr_write_enable, csr_addr, (reg_write==exp_reg_write && csr_write_enable==exp_csr_write_enable && csr_addr==exp_csr_addr));
        #100;

        // 45. CSRRWI rd, csr, imm → CSRRWI x1, 0x123, 5 (0x1232D0F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 45/47: SYSTEM - CSRRWI x1, 0x123, 5");
        $display("Encoding: 0x1232D0F3 | Opcode: 1110011 | Funct3: 101 | CSR: 0x123 | Imm:5");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=11, csr_addr=0x123, csr_imm=5'h05, alu_op=1010; others=0");
        instruction = 32'h1232D0F3;
        exp_csr_op=2'b11; exp_csr_imm=5'h05;
        #10; $display("Actual: reg_write=%b, csr_write_enable=%b, csr_imm=5'h%02X | Match: %b", reg_write, csr_write_enable, csr_imm, (reg_write==exp_reg_write && csr_write_enable==exp_csr_write_enable && csr_imm==exp_csr_imm));
        #100;

        // 46. CSRRSI rd, csr, imm → CSRRSI x1, 0x123, 5 (0x1232E0F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 46/47: SYSTEM - CSRRSI x1, 0x123, 5");
        $display("Encoding: 0x1232E0F3 | Opcode: 1110011 | Funct3: 110 | CSR: 0x123 | Imm:5");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=11, csr_addr=0x123, csr_imm=5'h05, alu_op=1010; others=0");
        instruction = 32'h1232E0F3;
        #10; $display("Actual: reg_write=%b, csr_write_enable=%b, csr_imm=5'h%02X | Match: %b", reg_write, csr_write_enable, csr_imm, (reg_write==exp_reg_write && csr_write_enable==exp_csr_write_enable && csr_imm==exp_csr_imm));
        #100;

        // 47. CSRRCI rd, csr, imm → CSRRCI x1, 0x123, 5 (0x1232F0F3)
        $display("\n-----------------------------------------------------");
        $display("Instruction 47/47: SYSTEM - CSRRCI x1, 0x123, 5");
        $display("Encoding: 0x1232F0F3 | Opcode: 1110011 | Funct3: 111 | CSR: 0x123 | Imm:5");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=11, csr_addr=0x123, csr_imm=5'h05, alu_op=1010; others=0");
        instruction = 32'h1232F0F3; 
        #10; $display("Actual: reg_write=%b, csr_write_enable=%b, csr_imm=5'h%02X | Match: %b", reg_write, csr_write_enable, csr_imm, (reg_write==exp_reg_write && csr_write_enable==exp_csr_write_enable && csr_imm==exp_csr_imm));
        #100;


        // Test completion
        $display("\n=====================================================");
        $display("All 47 instructions tested - Testbench completed");
        $display("=====================================================");
        $finish;
    end

endmodule

