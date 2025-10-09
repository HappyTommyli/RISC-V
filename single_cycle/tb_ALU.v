`timescale 1ns / 1ps

module tb_ALU;
    reg [31:0] rs1_data;
    reg [31:0] rs2_data;
    reg [3:0] alu_op;
    wire zero;
    wire [31:0] alu_result;
    wire overflow;
    
    ALU uut (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .alu_op(alu_op),
        .zero(zero),
        .alu_result(alu_result),
        .overflow(overflow)
    );
    
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    initial begin
        rs1_data = 0;
        rs2_data = 0;
        alu_op = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("Starting ALU tests...");
        $display("==================================================");
        
        $display("\nTesting ADD operation (0000)");
        alu_op = 4'b0000;
        
        rs1_data = 32'd10;
        rs2_data = 32'd20;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 30, zero: 0, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd30 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h7FFFFFFF;
        rs2_data = 32'h00000001;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 80000000, zero: 0, overflow: 1; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h80000000 && zero == 1'b0 && overflow == 1'b1)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h80000000;
        rs2_data = 32'h80000000;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 00000000, zero: 1, overflow: 1; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h00000000 && zero == 1'b1 && overflow == 1'b1)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'd5;
        rs2_data = -32'd5;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 0, zero: 1, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd0 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting SUB operation (0001)");
        alu_op = 4'b0001;
        
        rs1_data = 32'd50;
        rs2_data = 32'd20;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 30, zero: 0, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd30 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h7FFFFFFF;
        rs2_data = 32'h80000001;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: FFFFFFFF, zero: 0, overflow: 1; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'hFFFFFFFF && zero == 1'b0 && overflow == 1'b1)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h80000000;
        rs2_data = 32'h00000001;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 7FFFFFFF, zero: 0, overflow: 1; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h7FFFFFFF && zero == 1'b0 && overflow == 1'b1)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'd100;
        rs2_data = 32'd100;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 0, zero: 1, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd0 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting AND operation (1001)");
        alu_op = 4'b1001;
        
        rs1_data = 32'hFFFF0000;
        rs2_data = 32'h00FFFF00;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 00FF0000, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h00FF0000 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h00000000;
        rs2_data = 32'hFFFFFFFF;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 00000000, zero: 1, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h00000000 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting OR operation (1000)");
        alu_op = 4'b1000;
        
        rs1_data = 32'hFFFF0000;
        rs2_data = 32'h00FFFF00;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: FFFFFF00, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'hFFFFFF00 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h00000000;
        rs2_data = 32'h00000000;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 00000000, zero: 1, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h00000000 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting SLL operation (0100)");
        alu_op = 4'b0100;
        
        rs1_data = 32'h00000001;
        rs2_data = 32'd1;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 00000002, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h00000002 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h80000000;
        rs2_data = 32'd1;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 00000000, zero: 1, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h00000000 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h0000000F;
        rs2_data = 32'd4;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 000000F0, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h000000F0 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting SLT operation (0010)");
        alu_op = 4'b0010;
        
        rs1_data = 32'd10;
        rs2_data = 32'd20;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 1, zero: 0, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd1 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h80000000;
        rs2_data = 32'h7FFFFFFF;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 1, zero: 0, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd1 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'd50;
        rs2_data = 32'd50;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 0, zero: 1, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd0 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting SLTU operation (0011)");
        alu_op = 4'b0011;
        
        rs1_data = 32'd10;
        rs2_data = 32'd20;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 1, zero: 0, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd1 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h80000000;
        rs2_data = 32'h7FFFFFFF;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 0, zero: 1, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd0 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting XOR operation (0101)");
        alu_op = 4'b0101;
        
        rs1_data = 32'hFFFF0000;
        rs2_data = 32'h00FFFF00;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: FF00FF00, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'hFF00FF00 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h12345678;
        rs2_data = 32'h12345678;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 00000000, zero: 1, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h00000000 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting SRL operation (0110)");
        alu_op = 4'b0110;
        
        rs1_data = 32'h80000000;
        rs2_data = 32'd1;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 40000000, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h40000000 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'hF0000000;
        rs2_data = 32'd4;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 0F000000, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h0F000000 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting SRA operation (0111)");
        alu_op = 4'b0111;
        
        rs1_data = 32'h80000000;
        rs2_data = 32'd1;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: C0000000, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'hC0000000 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h40000000;
        rs2_data = 32'd1;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 20000000, zero: 0, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h20000000 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting BGE operation (1011)");
        alu_op = 4'b1011;
        
        rs1_data = 32'd20;
        rs2_data = 32'd10;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 1, zero: 0, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd1 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'h80000000;
        rs2_data = 32'h7FFFFFFF;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 0, zero: 1, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd0 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        rs1_data = 32'd50;
        rs2_data = 32'd50;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 1, zero: 0, overflow: 0; Actual result: %0d, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'd1 && zero == 1'b0 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting NO OPERATION (1010)");
        alu_op = 4'b1010;
        
        rs1_data = 32'd123;
        rs2_data = 32'd456;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: 00000000, zero: 1, overflow: 0; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result == 32'h00000000 && zero == 1'b1 && overflow == 1'b0)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\nTesting default case");
        alu_op = 4'b1111;
        
        rs1_data = 32'd10;
        rs2_data = 32'd20;
        #10;
        test_count = test_count + 1;
        $display("Test %0d: Expected result: x, zero: x, overflow: x; Actual result: %h, zero: %b, overflow: %b",
                 test_count, alu_result, zero, overflow);
        if (alu_result === 32'hx)
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("\n==================================================");
        $display("Test summary:");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("==================================================");
        
        $finish;
    end
endmodule

