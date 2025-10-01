module mux_tb();
    // Testbench signal definitions
    reg [31:0] in0;    // Input signal 0
    reg [31:0] in1;    // Input signal 1
    reg ctrl;          // Control signal
    wire [31:0] out;   // Output signal 

    // Instantiate the Device Under Test (DUT)
    mux uut (
        .in0(in0),
        .in1(in1),
        .ctrl(ctrl),
        .out(out)  
    );

    // Test stimuli
    initial begin
        // Initialize inputs
        in0 = 32'h00000000;
        in1 = 32'h00000000;
        ctrl = 1'b0;
        
        // Print test information
        $display("Starting multiplexer test...");
        $monitor("Time=%0t, in0=0x%0h, in1=0x%0h, ctrl=%b, out=0x%0h", 
                 $time, in0, in1, ctrl, out);

        // Test 1: ctrl=0, verify output equals in0
        #10;  // 10ns delay
        in0 = 32'hA5A5A5A5;
        in1 = 32'h5A5A5A5A;
        ctrl = 1'b0;

        // Test 2: ctrl=1, verify output equals in1
        #10;
        ctrl = 1'b1;

        // Test 3: Change in0 value, keep ctrl=1 (output should follow in1)
        #10;
        in0 = 32'h12345678;
        in1 = 32'h87654321;

        // Test 4: Switch ctrl=0 again (output should follow in0)
        #10;
        ctrl = 1'b0;

        // Test 5: Boundary value test (all 0s and all 1s)
        #10;
        in0 = 32'h00000000;
        in1 = 32'hFFFFFFFF;
        ctrl = 1'b0;

        #10;
        ctrl = 1'b1;

        // End of test
        #10;
        $display("Test completed!");
        $finish;
    end

endmodule

