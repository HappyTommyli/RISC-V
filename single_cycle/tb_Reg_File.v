`timescale 1ns / 1ps 

module tb_Reg_File;

    // Inputs
    reg clk;
    reg rst;
    reg reg_write;
    reg [31:0]instruction;
    reg [31:0]alu_result;
    reg [4:0] mem_to_reg;
    reg [31:0] [31:0]data_mem_data;

    // Outputs
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // Instantiate the DUT
    Reg_File uut (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .instruction(instruction),
        .alu_result(alu_result),
        .mem_to_reg(mem_to_reg),
        .data_mem_data(data_mem_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Clock
    always #5 clk = ~clk; // 10ns period

    initial begin
        // Initialize inputs
        rst = 1;
        reg_write = 0;
        instruction = 32'h0;
        alu_result = 32'h0;
        mem_to_reg = 0;
        data_mem_data = 32'h0;

        #10;
        rst = 1; // Reset the register file
        #10;
        rst = 0;
        #10;
        // 1. Test  x0
        instruction = 32'h00000000; // rd = x0 00000 11:7, rs1 = x0 0000 19:15, rs2 = x0 0000 24:20
        #10;
        // 2. Write x1
        instruction = 32'h000040b3; // rd = x1 00001 11:7, rs1 = x1 (19:15), rs2 = x0 (24:20), opcode = 0110011
        alu_result = 32'h00000001; // Value to write
        reg_write = 1;
        mem_to_reg = 0; // Write from ALU result
        #10;
        reg_write = 0; // Disable write
        #10;
        // 3. Write x2
        instruction = 32'h00004133;
        alu_result = 32'h00000002; // Value to write
        reg_write = 1;
        mem_to_reg = 0; // Write from ALU result
        #10;
        reg_write = 0; // Disable write
        #10;
        // 4. Write x0 (should not change)
        instruction = 32'h00000033;
        alu_result = 32'h00000003; // Value to write
        reg_write = 1;
        mem_to_reg = 0; // Write from ALU result
        #10;
        reg_write = 0; // Disable write
        #10;
        // 5. Write and read x5 x6
        instruction = 32'h006282b3; //rd = x5 11:7, rs1 = x5 (19:15), rs2 = x6 (24:20)
        alu_result = 32'h00000005; // Value to write to x5
        reg_write = 1;
        mem_to_reg = 0; // Write from ALU result
        #10;
        instruction = 32'h00628333; //rd = x6 11:7, rs1 = x5 (19:15), rs2 = x6 (24:20)
        alu_result = 32'h00000006; // Value to write to x6
        #10;
        reg_write = 0; // Disable write
        instruction = 32'h006282b3; // Read x5 and x6
        #10;
        if(rs1_data == 32'h00000000 && rs2_data == 32'h00000000)
            $display("Test 6 Passed");
        else 
            $display("Test 6 Failed: rs1 = %h, rs2 = %h", rs1_data, rs2_data);
        #10;
        $finish;
    end
endmodule