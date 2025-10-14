module imm_generator_tb;

  reg [31:0] instruction;
  wire [31:0] imm;
  integer pass_count, fail_count;

  // Instantiate the DUT (Device Under Test)
imm_generator  uut (
    .instruction(instruction),
    .imm(imm)
  );

  // Task to perform a single test case
  task run_test;
    input [31:0] test_instruction;
    input [31:0] expected_imm;
    input [8*100:0] test_name;
    
    begin
      instruction = test_instruction;
      #10; // Wait for combinational logic to settle
      
      if (imm === expected_imm) begin
        $display("[PASS] %s", test_name);
        pass_count = pass_count + 1;
      end else begin
        $display("[FAIL] %s - Expected: %32b, Got: %32b", 
                 test_name, expected_imm, imm);
        fail_count = fail_count + 1;
      end
    end
  endtask

  initial begin
    // Initialize counters
    pass_count = 0;
    fail_count = 0;
    $display("Starting immediate generator tests...\n");

    // 1. Test I-Type (addi: add immediate)
    // Instruction format: [31:20]imm, [19:15]rs1, [14:12]funct3, [11:7]rd, [6:0]opcode
    run_test(
      32'b0000_0000_1010_0101_0000_0010_1001_0011,  // Instruction: addi x5, x10, 10
      32'b0000_0000_0000_0000_0000_0000_1010,      // Expected immediate: 10
      "I_TYPE (addi)"
    );

    // 2. Test I-Type (lw: load word)
    // Instruction format: [31:20]imm, [19:15]rs1, [14:12]funct3, [11:7]rd, [6:0]opcode
    run_test(
      32'b0000_0000_1000_0001_0010_0011_1000_0011,  // Instruction: lw x7, 8(x2)
      32'b0000_0000_0000_0000_0000_0000_0000_1000,      // Expected immediate: 8
      "I_TYPE (lw)"
    );

    // 3. Test I-Type (csrrw: CSR read/write)
    // Instruction format: [31:20]csr_addr, [19:15]rs1, [14:12]funct3, [11:7]rd, [6:0]opcode
    run_test(
      32'b0011_0000_0000_0000_0001_0000_0111_0011,  // Instruction: csrrw x0, mstatus, x0
      32'b0000_0000_0000_0000_0000_0011_0000_0000,      // Expected immediate: 0
      "I_TYPE (csrrw)"
    );

    // 4. Test I-Type (jalr: jump and link register)
    // Instruction format: [31:20]imm, [19:15]rs1, [14:12]funct3, [11:7]rd, [6:0]opcode
    run_test(
      32'b0000_0000_0000_0000_1000_0000_0110_0111,  // Instruction: jalr x0, 0(x1)
      32'b0000_0000_0000_0000_0000_0000_0000_0000,      // Expected immediate: 0
      "I_TYPE (jalr)"
    );

    // 5. Test S-Type (sw: store word)
    // Instruction format: [31:25]imm[11:5], [24:20]rs2, [19:15]rs1, [14:12]funct3, [11:7]imm[4:0], [6:0]opcode
    run_test(
      32'b0000_0000_0101_0001_1010_0110_1010_0011,  // Instruction: sw x5, 13(x3)
      32'b0000_0000_0000_0000_0000_0000_1101,      // Expected immediate: 13 
      "S_TYPE (sw)"
    );

    // 6. Test B-Type (beq: branch if equal)
    // Instruction format: [31]imm[12], [30:25]imm[10:5], [24:20]rs2, [19:15]rs1, [14:12]funct3, [11:8]imm[4:1], [7]imm[11], [6:0]opcode
    run_test(
      32'b0000_0000_0010_0000_1000_0100_0110_0011,  // Instruction: beq x1, x2, 8   
      32'b0000_0000_0000_0000_0000_0000_0000_1000,      // Expected immediate: 8    
      "B_TYPE (beq)"
    );

    // 7. Test U-Type (lui: load upper immediate)
    // Instruction format: [31:12]imm, [11:7]rd, [6:0]opcode
    run_test(
      32'b0001_0010_0011_0100_0101_0101_0011_0111,  // Instruction: lui x10, 0x12345     
      32'b0001_0010_0011_0100_0101_0000_0000_0000,// Expected immediate: 0x12345 << 12   
      "U_TYPE (lui)"
    );

    // 8. Test U-Type (auipc: add upper immediate to PC)
    // Instruction format: [31:12]imm, [11:7]rd, [6:0]opcode
    run_test(
      32'b0101_0100_0011_0010_0001_0111_1001_0111,  // Instruction: auipc x15, 0x54321
      32'b0101_0100_0011_0010_0001_0000_0000_0000,// Expected immediate: 0x54321 << 12
      "U_TYPE (auipc)"
    );

    // 9. Test J-Type (jal: jump and link)
    // Instruction format: [31]imm[20], [30:21]imm[10:1], [20]imm[11], [19:12]imm[19:12], [11:7]rd, [6:0]opcode
    run_test(
      32'b0000_0001_0000_0000_0000_0000_0110_1111,  // Instruction: jal x0, 16
      32'b0000_0000_0000_0000_0000_0001_0000,      // Expected immediate: 16
      "J_TYPE (jal)"
    );

    // 10. Test default case (invalid opcode)
    run_test(
      32'b0000_0000_0000_00000_000_00000_0000000,  // Invalid instruction
      32'b0000_0000_0000_0000_0000_0000_0000,      // Expected immediate: 0
      "Default case (invalid opcode)"
    );

    // Print final test summary
    $display("\nTest Summary:");
    $display("Passed: %0d", pass_count);
    $display("Failed: %0d", fail_count);
    $display("Total:  %0d", pass_count + fail_count);
    
    $finish;
  end

endmodule
    


//addi x5, x10, 10
// lw x7, 8(x2)
// csrrw x0, mstatus, x0
// jalr x0, 0(x1)
// sw x5, 13(x3)
// beq x1, x2, 8
// lui x10, 0x12345
// auipc x15, 0x54321
// jal x0, 16
