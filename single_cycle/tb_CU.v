
module tb_CU;
    // Inputs
    reg [31:0] instruction;  
    // Outputs
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

    // Instantiate DUT
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

    // Clock generation
    reg clk;
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk; // 50MHz clock
    end

    // Test statistics
    integer total_tests;
    integer pass_count;
    integer fail_count;

    // Task: Display FULL expected/actual for each signal + count results
    // Parameters: All expected signals (N/A = 1'bx for non-applicable)
    task check_test;
        input [31:0] test_instr;
        input [127:0] test_desc;
        // Core control signals (applicable to most tests)
        input exp_reg_write;
        input exp_mem_to_reg;
        input exp_mem_write;
        input exp_mem_read;
        input exp_alu_src;
        input [3:0] exp_alu_op;
        input exp_branch;
        input exp_jump;
        input exp_jalr_enable;
        // CSR-specific signals (x = N/A for non-CSR tests)
        input [11:0] exp_csr_addr;
        input exp_csr_write_enable;
        input [1:0] exp_csr_op;
        input [4:0] exp_csr_imm;
    begin
        instruction = test_instr;
        #20; // Wait for combinational logic稳定 & clock edge
        total_tests = total_tests + 1;
        logic test_pass = 1'b1; // Assume pass first

        // -------------------------- 1. Test Header --------------------------
        $display("\n==================================== [Test %0d: %s] ===================================", total_tests, test_desc);
        $display("Instruction: %h", test_instr);

        // -------------------------- 2. Full Expected/Actual Display --------------------------
        $display("\n[Core Control Signals]");
        // Check & display each core signal
        if (exp_reg_write !== 1'bx) begin
            $display("  reg_write  : Expected = %b | Actual = %b", exp_reg_write, reg_write);
            if (exp_reg_write !== reg_write) test_pass = 1'b0;
        end
        if (exp_mem_to_reg !== 1'bx) begin
            $display("  mem_to_reg : Expected = %b | Actual = %b", exp_mem_to_reg, mem_to_reg);
            if (exp_mem_to_reg !== mem_to_reg) test_pass = 1'b0;
        end
        if (exp_mem_write !== 1'bx) begin
            $display("  mem_write  : Expected = %b | Actual = %b", exp_mem_write, mem_write);
            if (exp_mem_write !== mem_write) test_pass = 1'b0;
        end
        if (exp_mem_read !== 1'bx) begin
            $display("  mem_read   : Expected = %b | Actual = %b", exp_mem_read, mem_read);
            if (exp_mem_read !== mem_read) test_pass = 1'b0;
        end
        if (exp_alu_src !== 1'bx) begin
            $display("  alu_src    : Expected = %b | Actual = %b", exp_alu_src, alu_src);
            if (exp_alu_src !== alu_src) test_pass = 1'b0;
        end
        if (exp_alu_op !== 4'bxxxx) begin
            $display("  alu_op     : Expected = %4b | Actual = %4b", exp_alu_op, alu_op);
            if (exp_alu_op !== alu_op) test_pass = 1'b0;
        end
        if (exp_branch !== 1'bx) begin
            $display("  branch     : Expected = %b | Actual = %b", exp_branch, branch);
            if (exp_branch !== branch) test_pass = 1'b0;
        end
        if (exp_jump !== 1'bx) begin
            $display("  jump       : Expected = %b | Actual = %b", exp_jump, jump);
            if (exp_jump !== jump) test_pass = 1'b0;
        end
        if (exp_jalr_enable !== 1'bx) begin
            $display("  jalr_enable: Expected = %b | Actual = %b", exp_jalr_enable, jalr_enable);
            if (exp_jalr_enable !== jalr_enable) test_pass = 1'b0;
        end

        // Display CSR signals only if applicable (exp_csr_addr != x)
        if (exp_csr_addr !== 12'hxxx) begin
            $display("\n[CSR-Specific Signals]");
            $display("  csr_addr       : Expected = %h | Actual = %h", exp_csr_addr, csr_addr);
            if (exp_csr_addr !== csr_addr) test_pass = 1'b0;
            $display("  csr_write_enable: Expected = %b | Actual = %b", exp_csr_write_enable, csr_write_enable);
            if (exp_csr_write_enable !== csr_write_enable) test_pass = 1'b0;
            $display("  csr_op         : Expected = %2b | Actual = %2b", exp_csr_op, csr_op);
            if (exp_csr_op !== csr_op) test_pass = 1'b0;
            $display("  csr_imm        : Expected = %h | Actual = %h", exp_csr_imm, csr_imm);
            if (exp_csr_imm !== csr_imm) test_pass = 1'b0;
        end

        // -------------------------- 3. Pass/Fail Result --------------------------
        if (test_pass) begin
            $display("\n[Result] PASS");
            pass_count = pass_count + 1;
        end else begin
            $error("\n[Result] FAIL");
            fail_count = fail_count + 1;
        end
        $display("--------------------------------------------------------------------------------");
    end
    endtask

    // Main test flow
    initial begin
        // Step 1: Initial 1000ns delay (required)
        $display("==================================== Initial Delay: 1000ns ===================================");
        #1000;
        $display("==================================== Start CU Tests ===================================\n");

        // Initialize variables
        instruction = 32'h00000000;
        total_tests = 0;
        pass_count = 0;
        fail_count = 0;
        #20;


        // -------------------------- Group 1: R-type Instructions --------------------------
        $display("---------------------------------- Group 1: R-type Instructions ----------------------------------");
        // 1.1 ADD (opcode=0110011)
        check_test(
            32'h00100033, "R-type ADD",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.2 SUB (opcode=0110011)
        check_test(
            32'h40100033, "R-type SUB",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0001, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.3 SLL (opcode=0110011)
        check_test(
            32'h00101033, "R-type SLL",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0100, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.4 SLT (opcode=0110011)
        check_test(
            32'h00102033, "R-type SLT",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0010, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.5 SLTU (opcode=0110011)
        check_test(
            32'h00103033, "R-type SLTU",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0011, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.6 XOR (opcode=0110011)
        check_test(
            32'h00104033, "R-type XOR",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0105, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.7 SRL (opcode=0110011)
        check_test(
            32'h00105033, "R-type SRL",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0110, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.8 SRA (opcode=0110011)
        check_test(
            32'h40105033, "R-type SRA",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0111, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.9 OR (opcode=0110011)
        check_test(
            32'h00106033, "R-type OR",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b1000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.10 AND (opcode=0110011)
        check_test(
            32'h00107033, "R-type AND",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b1001, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 1.11 Invalid R-type
        check_test(
            32'h7F107033, "R-type Invalid Funct",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b1111, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );


        // -------------------------- Group 2: I-type Instructions --------------------------
        $display("\n---------------------------------- Group 2: I-type Instructions ----------------------------------");
        // 2.1 ADDI (opcode=0010011)
        check_test(
            32'h00100013, "I-type ADDI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.2 SLLI (opcode=0010011)
        check_test(
            32'h00101013, "I-type SLLI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0100, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.3 SLTI (opcode=0010011)
        check_test(
            32'h00102013, "I-type SLTI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0010, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.4 SLTIU (opcode=0010011)
        check_test(
            32'h00103013, "I-type SLTIU",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0011, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.5 XORI (opcode=0010011)
        check_test(
            32'h00104013, "I-type XORI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0105, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.6 SRLI (opcode=0010011)
        check_test(
            32'h00105013, "I-type SRLI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0110, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.7 SRAI (opcode=0010011)
        check_test(
            32'h40105013, "I-type SRAI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0111, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.8 ORI (opcode=0010011)
        check_test(
            32'h00106013, "I-type ORI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b1000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.9 ANDI (opcode=0010011)
        check_test(
            32'h00107013, "I-type ANDI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b1001, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 2.10 Invalid I-type
        check_test(
            32'h00108013, "I-type Invalid Funct3",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b1111, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );


        // -------------------------- Group 3: Load Instructions --------------------------
        $display("\n---------------------------------- Group 3: Load Instructions ----------------------------------");
        // 3.1 LB (opcode=0000011)
        check_test(
            32'h00100003, "Load LB",
            1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 3.2 LH (opcode=0000011)
        check_test(
            32'h00101003, "Load LH",
            1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 3.3 LW (opcode=0000011)
        check_test(
            32'h00102003, "Load LW",
            1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 3.4 LBU (opcode=0000011)
        check_test(
            32'h00104003, "Load LBU",
            1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 3.5 LHU (opcode=0000011)
        check_test(
            32'h00105003, "Load LHU",
            1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );


        // -------------------------- Group 4: Store Instructions --------------------------
        $display("\n---------------------------------- Group 4: Store Instructions ----------------------------------");
        // 4.1 SB (opcode=0100011)
        check_test(
            32'h00100023, "Store SB",
            1'b0, 1'bx, 1'b1, 1'b0, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 4.2 SH (opcode=0100011)
        check_test(
            32'h00101023, "Store SH",
            1'b0, 1'bx, 1'b1, 1'b0, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 4.3 SW (opcode=0100011)
        check_test(
            32'h00102023, "Store SW",
            1'b0, 1'bx, 1'b1, 1'b0, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );


        // -------------------------- Group 5: B-type Instructions --------------------------
        $display("\n---------------------------------- Group 5: B-type Instructions ----------------------------------");
        // 5.1 BEQ (opcode=1100011)
        check_test(
            32'h00100063, "Branch BEQ",
            1'b0, 1'bx, 1'b0, 1'b0, 1'b0, 4'b0001, 1'b1, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 5.2 BNE (opcode=1100011)
        check_test(
            32'h00101063, "Branch BNE",
            1'b0, 1'bx, 1'b0, 1'b0, 1'b0, 4'b0001, 1'b1, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 5.3 BLT (opcode=1100011)
        check_test(
            32'h00104063, "Branch BLT",
            1'b0, 1'bx, 1'b0, 1'b0, 1'b0, 4'b0010, 1'b1, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 5.4 BGE (opcode=1100011)
        check_test(
            32'h00105063, "Branch BGE",
            1'b0, 1'bx, 1'b0, 1'b0, 1'b0, 4'b1011, 1'b1, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 5.5 BLTU (opcode=1100011)
        check_test(
            32'h00106063, "Branch BLTU",
            1'b0, 1'bx, 1'b0, 1'b0, 1'b0, 4'b0011, 1'b1, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 5.6 BGEU (opcode=1100011)
        check_test(
            32'h00107063, "Branch BGEU",
            1'b0, 1'bx, 1'b0, 1'b0, 1'b0, 4'b0011, 1'b1, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 5.7 Invalid B-type
        check_test(
            32'h00108063, "B-type Invalid Funct3",
            1'b0, 1'bx, 1'b0, 1'b0, 1'b0, 4'b1111, 1'b1, 1'b0, 1'b0, // Core signals (mem_to_reg N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );


        // -------------------------- Group 6: Jump Instructions --------------------------
        $display("\n---------------------------------- Group 6: Jump Instructions ----------------------------------");
        // 6.1 JAL (opcode=1101111)
        check_test(
            32'h001000EF, "Jump JAL",
            1'b1, 1'b0, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b1, 1'b0, // Core signals (alu_src N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 6.2 JALR (opcode=1100111)
        check_test(
            32'h001000E7, "Jump JALR",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0000, 1'b0, 1'b1, 1'b1, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );


        // -------------------------- Group 7: FENCE Instructions --------------------------
        $display("\n---------------------------------- Group 7: FENCE Instructions ----------------------------------");
        // 7.1 FENCE (opcode=0001111)
        check_test(
            32'h0000000F, "FENCE",
            1'b0, 1'bx, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg/alu_src N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 7.2 FENCE.I (opcode=0001111)
        check_test(
            32'h0010000F, "FENCE.I",
            1'b0, 1'bx, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg/alu_src N/A)
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );


        // -------------------------- Group 8: SYSTEM/CSR Instructions --------------------------
        $display("\n---------------------------------- Group 8: SYSTEM/CSR Instructions ----------------------------------");
        // 8.1 ECALL (opcode=1110011)
        check_test(
            32'h00000073, "SYSTEM ECALL",
            1'b0, 1'bx, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg/alu_src N/A)
            12'hxxx, 1'b0, 2'bxx, 5'hxx // CSR: csr_write_enable=0, others N/A
        );
        // 8.2 EBREAK (opcode=1110011)
        check_test(
            32'h00100073, "SYSTEM EBREAK",
            1'b0, 1'bx, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg/alu_src N/A)
            12'hxxx, 1'b0, 2'bxx, 5'hxx // CSR: csr_write_enable=0, others N/A
        );
        // 8.3 CSRRW (opcode=1110011)
        check_test(
            32'h12300073, "CSR CSRRW",
            1'b1, 1'b0, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (alu_src N/A)
            12'h123, 1'b1, 2'b00, 5'hxx // CSR: csr_addr=123, csr_op=00, others N/A
        );
        // 8.4 CSRRS (opcode=1110011)
        check_test(
            32'h45601073, "CSR CSRRS",
            1'b1, 1'b0, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (alu_src N/A)
            12'h456, 1'b1, 2'b01, 5'hxx // CSR: csr_addr=456, csr_op=01, others N/A
        );
        // 8.5 CSRRC (opcode=1110011)
        check_test(
            32'h78902073, "CSR CSRRC",
            1'b1, 1'b0, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (alu_src N/A)
            12'h789, 1'b1, 2'b10, 5'hxx // CSR: csr_addr=789, csr_op=10, others N/A
        );
        // 8.6 CSRRWI (opcode=1110011)
        check_test(
            32'hABC1F273, "CSR CSRRWI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (alu_src N/A)
            12'hABC, 1'b1, 2'b11, 5'h1F // CSR: csr_addr=ABC, csr_op=11, csr_imm=1F
        );
        // 8.7 CSRRSI (opcode=1110011)
        check_test(
            32'hDEF0A373, "CSR CSRRSI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (alu_src N/A)
            12'hDEF, 1'b1, 2'b11, 5'h0A // CSR: csr_addr=DEF, csr_op=11, csr_imm=0A
        );
        // 8.8 CSRRCI (opcode=1110011)
        check_test(
            32'h11105373, "CSR CSRRCI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'bx, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals (alu_src N/A)
            12'h111, 1'b1, 2'b11, 5'h05 // CSR: csr_addr=111, csr_op=11, csr_imm=05
        );
        // 8.9 Invalid SYSTEM
        check_test(
            32'h00008073, "SYSTEM Invalid Funct3",
            1'b0, 1'bx, 1'b0, 1'b0, 1'bx, 4'b1111, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg/alu_src N/A)
            12'hxxx, 1'b0, 2'bxx, 5'hxx // CSR: csr_write_enable=0, others N/A
        );


        // -------------------------- Group 9: AUIPC & LUI --------------------------
        $display("\n---------------------------------- Group 9: AUIPC & LUI ----------------------------------");
        // 9.1 AUIPC (opcode=0010511)
        check_test(
            32'h00100093, "AUIPC",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0000, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );
        // 9.2 LUI (opcode=0110111)
        check_test(
            32'h001000B7, "LUI",
            1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 4'b1010, 1'b0, 1'b0, 1'b0, // Core signals
            12'hxxx, 1'bx, 2'bxx, 5'hxx // CSR: N/A
        );


        // -------------------------- Group 10: Invalid Opcode --------------------------
        $display("\n---------------------------------- Group 10: Invalid Opcode ----------------------------------");
        check_test(
            32'h00000013, "Invalid Opcode",
            1'b0, 1'bx, 1'b0, 1'b0, 1'bx, 4'b1111, 1'b0, 1'b0, 1'b0, // Core signals (mem_to_reg/alu_src N/A)
            12'hxxx, 1'b0, 2'bxx, 5'hxx // CSR: csr_write_enable=0, others N/A
        );


        // -------------------------- Final Test Summary --------------------------
        $display("\n\n==================================== FINAL TEST SUMMARY ===================================");
        $display("Total Tests  : %0d", total_tests);
        $display("Passed Tests : %0d", pass_count);
        $display("Failed Tests : %0d", fail_count);
        $display("Pass Rate    : %.2f%%", (pass_count * 100.0) / total_tests);
        $display("==========================================================================================");

        $finish; // End simulation
    end
endmodule


