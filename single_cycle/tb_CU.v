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

        $display("\n==================================== [Test 1: R-type Instructions] ====================================");
        instruction = 32'h00100013;
        #20;
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

        instruction = 32'h40100013;
        #20;
        $display("\n1.2 SUB:");
        $display("Expected: reg_write=1, mem_to_reg=0, mem_write=0, mem_read=0, alu_src=0, alu_op=4'b0001, branch=0, jump=0, jalr_enable=0");
        $display("Actual  : reg_write=%b, mem_to_reg=%b, mem_write=%b, mem_read=%b, alu_src=%b, alu_op=%4b, branch=%b, jump=%b, jalr_enable=%b",
                 reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable);
        if ( {reg_write, mem_to_reg, mem_write, mem_read, alu_src, alu_op, branch, jump, jalr_enable} != 13'b1_0_0_0_0_0001_0_0_0 )
        begin
            $error("1.2 SUB Test Failed!");
        end

        instruction = 32'h00101013;
        #20;
        $display("\n1.3 SLL:");
        $display("Expected: reg_write=1, alu_op=4'b0100");
        $display("Actual  : reg_write=%b, alu_op=%4b", reg_write, alu_op);
        if ( {reg_write, alu_op} != 5'b1_0100 )
        begin
            $error("1.3 SLL Test Failed!");
        end

        instruction = 32'h00102013;
        #20;
        if ( {reg_write, alu_op} != 5'b1_0010 )
        begin
            $error("1.4 SLT Test Failed!");
        end

        instruction = 32'h00103013;
        #20;
        if ( {reg_write, alu_op} != 5'b1_0011 )
        begin
            $error("1.5 SLTU Test Failed!");
        end

        instruction = 32'h00104013;
        #20;
        if ( {reg_write, alu_op} != 5'b1_0105 )
        begin
            $error("1.6 XOR Test Failed!");
        end

        instruction = 32'h00105013;
        #20;
        if ( {reg_write, alu_op} != 5'b1_0110 )
        begin
            $error("1.7 SRL Test Failed!");
        end

        instruction = 32'h40105013;
        #20;
        if ( {reg_write, alu_op} != 5'b1_0111 )
        begin
            $error("1.8 SRA Test Failed!");
        end

        instruction = 32'h00106013;
        #20;
        if ( {reg_write, alu_op} != 5'b1_1000 )
        begin
            $error("1.9 OR Test Failed!");
        end

        instruction = 32'h00107013;
        #20;
        if ( {reg_write, alu_op} != 5'b1_1001 )
        begin
            $error("1.10 AND Test Failed!");
        end

        instruction = 32'h7F107013; 
        #20;
        $display("\n1.11 R-type Invalid Funct:");
        $display("Expected: alu_op=4'b1111");
        $display("Actual  : alu_op=%4b", alu_op);
        if ( alu_op != 4'b1111 )
        begin
            $error("1.11 R-type Invalid Funct Test Failed!");
        end


        $display("\n==================================== [Test 2: I-type Instructions] ====================================");
        instruction = 32'h00100013;
        #20;
        $display("2.1 ADDI:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0000 )
        begin
            $error("2.1 ADDI Test Failed!");
        end

        instruction = 32'h00101013;
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0100 )
        begin
            $error("2.2 SLLI Test Failed!");
        end

        instruction = 32'h00102013;
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0010 )
        begin
            $error("2.3 SLTI Test Failed!");
        end

        instruction = 32'h00103013;
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0011 )
        begin
            $error("2.4 SLTIU Test Failed!");
        end

        instruction = 32'h00104013;
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0105 )
        begin
            $error("2.5 XORI Test Failed!");
        end

        instruction = 32'h00105013;
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0110 )
        begin
            $error("2.6 SRLI Test Failed!");
        end

        instruction = 32'h40105013;
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0111 )
        begin
            $error("2.7 SRAI Test Failed!");
        end

        instruction = 32'h00106013;
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_1000 )
        begin
            $error("2.8 ORI Test Failed!");
        end

        instruction = 32'h00107013;
        #20;
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_1001 )
        begin
            $error("2.9 ANDI Test Failed!");
        end

        instruction = 32'h00108013; 
        #20;
        if ( alu_op != 4'b1111 )
        begin
            $error("2.10 I-type Invalid Funct3 Test Failed!");
        end


        $display("\n==================================== [Test 3: Load Instructions] ====================================");
        instruction = 32'h00100003;
        #20;
        $display("3.1 LB:");
        $display("Expected: reg_write=1, mem_to_reg=1, mem_read=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, mem_to_reg=%b, mem_read=%b, alu_src=%b, alu_op=%4b",
                 reg_write, mem_to_reg, mem_read, alu_src, alu_op);
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.1 LB Test Failed!");
        end

        instruction = 32'h00101003;
        #20;
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.2 LH Test Failed!");
        end

        instruction = 32'h00102003;
        #20;
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.3 LW Test Failed!");
        end

        instruction = 32'h00104003;
        #20;
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.4 LBU Test Failed!");
        end

        instruction = 32'h00105003;
        #20;
        if ( {reg_write, mem_to_reg, mem_read, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("3.5 LHU Test Failed!");
        end


        $display("\n==================================== [Test 4: Store Instructions] ====================================");
        instruction = 32'h00100023;
        #20;
        $display("4.1 SB:");
        $display("Expected: reg_write=0, mem_write=1, mem_read=0, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, mem_write=%b, mem_read=%b, alu_src=%b, alu_op=%4b",
                 reg_write, mem_write, mem_read, alu_src, alu_op);
        if ( {reg_write, mem_write, mem_read, alu_src, alu_op} != 9'b0_1_0_1_0000 )
        begin
            $error("4.1 SB Test Failed!");
        end

        instruction = 32'h00101023;
        #20;
        if ( {reg_write, mem_write, mem_read, alu_src, alu_op} != 9'b0_1_0_1_0000 )
        begin
            $error("4.2 SH Test Failed!");
        end

        instruction = 32'h00102023;
        #20;
        if ( {reg_write, mem_write, mem_read, alu_src, alu_op} != 9'b0_1_0_1_0000 )
        begin
            $error("4.3 SW Test Failed!");
        end


        $display("\n==================================== [Test 5: B-type Instructions] ====================================");
        instruction = 32'h00100063;
        #20;
        $display("5.1 BEQ:");
        $display("Expected: branch=1, alu_op=4'b0001, reg_write=0");
        $display("Actual  : branch=%b, alu_op=%4b, reg_write=%b", branch, alu_op, reg_write);
        if ( {branch, alu_op, reg_write} != 6'b1_0001_0 )
        begin
            $error("5.1 BEQ Test Failed!");
        end

        instruction = 32'h00101063;
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_0001_0 )
        begin
            $error("5.2 BNE Test Failed!");
        end

        instruction = 32'h00104063;
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_0010_0 )
        begin
            $error("5.3 BLT Test Failed!");
        end

        instruction = 32'h00105063;
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_1011_0 )
        begin
            $error("5.4 BGE Test Failed!");
        end

        instruction = 32'h00106063;
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_0011_0 )
        begin
            $error("5.5 BLTU Test Failed!");
        end

        instruction = 32'h00107063;
        #20;
        if ( {branch, alu_op, reg_write} != 6'b1_0011_0 )
        begin
            $error("5.6 BGEU Test Failed!");
        end

        instruction = 32'h00108063;
        #20;
        if ( alu_op != 4'b1111 )
        begin
            $error("5.7 B-type Invalid Funct3 Test Failed!");
        end


        $display("\n==================================== [Test 6: Jump Instructions] ====================================");
        instruction = 32'h001000EF;
        #20;
        $display("6.1 JAL:");
        $display("Expected: jump=1, reg_write=1, alu_op=4'b1010, jalr_enable=0");
        $display("Actual  : jump=%b, reg_write=%b, alu_op=%4b, jalr_enable=%b", jump, reg_write, alu_op, jalr_enable);
        if ( {jump, reg_write, alu_op, jalr_enable} != 7'b1_1_1010_0 )
        begin
            $error("6.1 JAL Test Failed!");
        end

        instruction = 32'h001000E7;
        #20;
        $display("\n6.2 JALR:");
        $display("Expected: jump=1, reg_write=1, jalr_enable=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : jump=%b, reg_write=%b, jalr_enable=%b, alu_src=%b, alu_op=%4b",
                 jump, reg_write, jalr_enable, alu_src, alu_op);
        if ( {jump, reg_write, jalr_enable, alu_src, alu_op} != 9'b1_1_1_1_0000 )
        begin
            $error("6.2 JALR Test Failed!");
        end


        $display("\n==================================== [Test 7: FENCE Instructions] ====================================");
        instruction = 32'h000000F;
        #20;
        $display("7.1 FENCE:");
        $display("Expected: alu_op=4'b1010, all control signals=0 (except alu_op)");
        $display("Actual  : alu_op=%4b, reg_write=%b, mem_write=%b, branch=%b, jump=%b",
                 alu_op, reg_write, mem_write, branch, jump);
        if ( {alu_op, reg_write, mem_write, branch, jump} != 9'b1010_0_0_0_0 )
        begin
            $error("7.1 FENCE Test Failed!");
        end

        instruction = 32'h001000F;
        #20;
        if ( {alu_op, reg_write, mem_write, branch, jump} != 9'b1010_0_0_0_0 )
        begin
            $error("7.2 FENCE.I Test Failed!");
        end


        $display("\n==================================== [Test 8: SYSTEM/CSR Instructions] ====================================");
        instruction = 32'h00000073;
        #20;
        $display("8.1 ECALL:");
        $display("Expected: alu_op=4'b1010, csr_write_enable=0");
        $display("Actual  : alu_op=%4b, csr_write_enable=%b", alu_op, csr_write_enable);
        if ( {alu_op, csr_write_enable} != 5'b1010_0 )
        begin
            $error("8.1 ECALL Test Failed!");
        end

        instruction = 32'h00100073;
        #20;
        if ( {alu_op, csr_write_enable} != 5'b1010_0 )
        begin
            $error("8.2 EBREAK Test Failed!");
        end

        instruction = 32'h12300073;
        #20;
        $display("\n8.3 CSRRW:");
        $display("Expected: reg_write=1, csr_write_enable=1, csr_op=2'b00, csr_addr=12'h123");
        $display("Actual  : reg_write=%b, csr_write_enable=%b, csr_op=%2b, csr_addr=%h",
                 reg_write, csr_write_enable, csr_op, csr_addr);
        if ( {reg_write, csr_write_enable, csr_op, csr_addr} != 16'b1_1_00_0000000100100011 )
        begin
            $error("8.3 CSRRW Test Failed!");
        end

        instruction = 32'h45601073;
        #20;
        if ( {reg_write, csr_write_enable, csr_op, csr_addr} != 16'b1_1_01_00000001000100110 )
        begin
            $error("8.4 CSRRS Test Failed!");
        end

        instruction = 32'h78902073;
        #20;
        if ( {reg_write, csr_write_enable, csr_op, csr_addr} != 16'b1_1_10_000000011110001001 )
        begin
            $error("8.5 CSRRC Test Failed!");
        end

        instruction = 32'hABC1F273;
        #20;
        $display("\n8.6 CSRRWI:");
        $display("Expected: csr_op=2'b11, csr_imm=5'h1F");
        $display("Actual  : csr_op=%2b, csr_imm=%h", csr_op, csr_imm);
        if ( {csr_op, csr_imm} != 7'b11_11111 )
        begin
            $error("8.6 CSRRWI Test Failed!");
        end

        instruction = 32'hDEF0A373;
        #20;
        if ( {csr_op, csr_imm} != 7'b11_01010 )
        begin
            $error("8.7 CSRRSI Test Failed!");
        end

        instruction = 32'h11105373;
        #20;
        if ( {csr_op, csr_imm} != 7'b11_00101 )
        begin
            $error("8.8 CSRRCI Test Failed!");
        end

        instruction = 32'h00008073; 
        #20;
        if ( alu_op != 4'b1111 )
        begin
            $error("8.9 SYSTEM Invalid Funct3 Test Failed!");
        end


        $display("\n==================================== [Test 9: AUIPC & LUI] ====================================");
        instruction = 32'h00100093;
        #20;
        $display("9.1 AUIPC:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b0000");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_0000 )
        begin
            $error("9.1 AUIPC Test Failed!");
        end

        instruction = 32'h001000B7;
        #20;
        $display("\n9.2 LUI:");
        $display("Expected: reg_write=1, alu_src=1, alu_op=4'b1010");
        $display("Actual  : reg_write=%b, alu_src=%b, alu_op=%4b", reg_write, alu_src, alu_op);
        if ( {reg_write, alu_src, alu_op} != 6'b1_1_1010 )
        begin
            $error("9.2 LUI Test Failed!");
        end


        $display("\n==================================== [Test 10: Invalid Opcode] ====================================");
        instruction = 32'h00000013;
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