`timescale 1ns / 1ps

module tb_imm_generator;
    reg [31:0] instruction;
    wire [31:0] imm;
    
    // Instantiate the DUT
    imm_generator uut (
        .instruction(instruction),
        .imm(imm)
    );
    
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    initial begin
        // Initialize variables
        instruction = 32'h00000000;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("Starting Immediate Generator Tests...");
        $display("==================================================");
        
        // Test I-Type instructions (0010011 - OP-IMM)
        $display("\nTesting I-Type (OP-IMM) instructions");
        
        // ADDI x1, x0, 0x123 (imm = 0x00000123)
        instruction = 32'h12300013;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 12300013, Expected = 00000123, Actual = %h",
                 test_count, imm);
        if (imm == 32'h00000123) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // ADDI x1, x0, -5 (imm = 0xFFFFFFFB)
        instruction = 32'hFFB00013;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = FFB00013, Expected = FFFFFFB, Actual = %h",
                 test_count, imm);
        if (imm == 32'hFFFFFFFB) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test I-Type (LOAD - 0000011)
        $display("\nTesting I-Type (LOAD) instructions");
        
        // LW x2, 0x345(x0) (imm = 0x00000345)
        instruction = 32'h34500003;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 34500003, Expected = 00000345, Actual = %h",
                 test_count, imm);
        if (imm == 32'h00000345) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test I-Type (JALR - 1100111)
        $display("\nTesting I-Type (JALR) instructions");
        
        // JALR x3, 0x67(x1) (imm = 0x00000067)
        instruction = 32'h067100E7;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 067100E7, Expected = 00000067, Actual = %h",
                 test_count, imm);
        if (imm == 32'h00000067) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test S-Type (STORE - 0100011)
        $display("\nTesting S-Type (STORE) instructions");
        
        // SW x4, 0x89A(x5) (imm = 0x0000089A)
        instruction = 32'h89A28223;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 89A28223, Expected = 0000089A, Actual = %h",
                 test_count, imm);
        if (imm == 32'h0000089A) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // SW x4, -0x10(x5) (imm = 0xFFFFFFF0)
        instruction = 32'hF1A28223;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = F1A28223, Expected = FFFFFF10, Actual = %h",
                 test_count, imm);
        if (imm == 32'hFFFFF10) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test B-Type (BRANCH - 1100011)
        $display("\nTesting B-Type (BRANCH) instructions");
        
        // BEQ x6, x7, 0x120 (imm = 0x00000120)
        instruction = 32'h08038363;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 08038363, Expected = 00000120, Actual = %h",
                 test_count, imm);
        if (imm == 32'h00000120) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // BNE x6, x7, -0x20 (imm = 0xFFFFFFE0)
        instruction = 32'hF0039363;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = F0039363, Expected = FFFFFFE0, Actual = %h",
                 test_count, imm);
        if (imm == 32'hFFFFFFE0) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test U-Type (LUI - 0110111)
        $display("\nTesting U-Type (LUI) instructions");
        
        // LUI x8, 0x12345 (imm = 0x12345000)
        instruction = 32'h12345437;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 12345437, Expected = 12345000, Actual = %h",
                 test_count, imm);
        if (imm == 32'h12345000) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test U-Type (AUIPC - 0010111)
        $display("\nTesting U-Type (AUIPC) instructions");
        
        // AUIPC x9, 0x6789A (imm = 0x6789A000)
        instruction = 32'h6789A493;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 6789A493, Expected = 6789A000, Actual = %h",
                 test_count, imm);
        if (imm == 32'h6789A000) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test J-Type (JAL - 1101111)
        $display("\nTesting J-Type (JAL) instructions");
        
        // JAL x10, 0x1234 (imm = 0x00001234)
        instruction = 32'h001235EF;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 001235EF, Expected = 00001234, Actual = %h",
                 test_count, imm);
        if (imm == 32'h00001234) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // JAL x10, -0x5678 (imm = 0xFFFFA988)
        instruction = 32'hFFA985EF;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = FFA985EF, Expected = FFFFA988, Actual = %h",
                 test_count, imm);
        if (imm == 32'hFFFFA988) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test default case (invalid opcode)
        $display("\nTesting default case (invalid opcode)");
        
        instruction = 32'h00000000;  // Invalid opcode
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Instruction = 00000000, Expected = 00000000, Actual = %h",
                 test_count, imm);
        if (imm == 32'h00000000) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test summary
        $display("\n==================================================");
        $display("Test summary:");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("==================================================");
        
        $finish;
    end
endmodule

