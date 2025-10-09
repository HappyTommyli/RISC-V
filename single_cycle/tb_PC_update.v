`timescale 1ns / 1ps

module tb_PC_update;
    // Inputs
    reg [31:0] rs1_data;
    reg jump;
    reg jalr_enable;
    reg branch;
    reg [31:0] pc_address;
    reg [31:0] imm;
    reg zero;
    
    // Outputs
    wire [31:0] next_pc;
    
    // Instantiate the DUT
    PC_update uut (
        .rs1_data(rs1_data),
        .jump(jump),
        .jalr_enable(jalr_enable),
        .branch(branch),
        .pc_address(pc_address),
        .imm(imm),
        .zero(zero),
        .next_pc(next_pc)
    );
    
    // Test counters
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    initial begin
        // Initialize inputs
        rs1_data = 0;
        jump = 0;
        jalr_enable = 0;
        branch = 0;
        pc_address = 0;
        imm = 0;
        zero = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("Starting PC Update Module Tests...");
        $display("==================================================");
        
        // Test 1: Normal operation (PC + 4)
        $display("\nTesting normal operation (PC + 4)");
        jump = 0;
        jalr_enable = 0;
        branch = 0;
        pc_address = 32'h00000000;
        imm = 32'h00000000;
        zero = 0;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00000004, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00000004) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 2: JALR operation
        $display("\nTesting JALR operation");
        jump = 1;
        jalr_enable = 1;
        branch = 0;
        pc_address = 32'h00000000;  // Should not affect result
        rs1_data = 32'h00001000;
        imm = 32'h00000020;
        zero = 0;  // Should not affect result
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00001020, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00001020) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 3: JALR with negative immediate
        jump = 1;
        jalr_enable = 1;
        rs1_data = 32'h00002000;
        imm = 32'hFFFFFFF0;  // -16
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00001FF0, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00001FF0) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 4: JAL operation
        $display("\nTesting JAL operation");
        jump = 1;
        jalr_enable = 0;
        pc_address = 32'h00000080;
        imm = 32'h00000100;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00000180, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00000180) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 5: JAL with negative immediate
        pc_address = 32'h00000200;
        imm = 32'hFFFFFE00;  // -512
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00000000, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00000000) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 6: Successful branch (branch + zero)
        $display("\nTesting successful branch");
        jump = 0;
        branch = 1;
        zero = 1;
        pc_address = 32'h00000400;
        imm = 32'h00000040;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00000440, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00000440) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 7: Unsuccessful branch (branch + !zero)
        $display("\nTesting unsuccessful branch");
        branch = 1;
        zero = 0;
        pc_address = 32'h00000800;
        imm = 32'h00000080;  // Should not affect result
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00000804, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00000804) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 8: Priority check (JALR vs Branch)
        $display("\nTesting priority (JALR takes precedence)");
        jump = 1;
        jalr_enable = 1;
        branch = 1;
        zero = 1;
        pc_address = 32'h00001000;  // Should not affect result
        rs1_data = 32'h00002000;
        imm = 32'h00000010;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00002010, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00002010) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 9: Priority check (JAL vs Branch)
        $display("\nTesting priority (JAL takes precedence)");
        jump = 1;
        jalr_enable = 0;
        branch = 1;
        zero = 1;
        pc_address = 32'h00003000;
        imm = 32'h00000020;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00003020, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00003020) pass_count = pass_count + 1;
        else fail_count = fail_count + 1;
        
        // Test 10: Higher address range
        $display("\nTesting higher address range");
        jump = 0;
        branch = 0;
        pc_address = 32'hFFFFFFFC;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected = 00000000, Actual = %h", test_count, next_pc);
        if (next_pc == 32'h00000000) pass_count = pass_count + 1;
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

