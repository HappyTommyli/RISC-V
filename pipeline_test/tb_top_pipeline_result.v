`timescale 1ns / 1ps

module tb_top_pipeline_result;
    reg clk;
    reg rst;
    reg [5:0] result_index;
    wire [31:0] result_word;
    wire [31:0] instruction;

    // Adjust if your program runs longer
    integer i;
    localparam integer CYCLES_WAIT = 50000;
    integer cycle_count;
    integer instr_count;

    top_pipeline_result dut (
        .clk(clk),
        .rst(rst),
        .result_index(result_index),
        .result_word(result_word),
        .instruction(instruction)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instr_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (instruction !== 32'h00000013 && instruction !== 32'h00000000)
                instr_count <= instr_count + 1;
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        result_index = 0;
        cycle_count = 0;
        instr_count = 0;

        // reset for a few cycles
        repeat (5) @(posedge clk);
        rst = 0;

        // wait for program to finish (tune as needed)
        repeat (CYCLES_WAIT) @(posedge clk);

        $display("==== Cycle Count = %0d ====", cycle_count);
        $display("==== Instruction Count (non-NOP fetched) = %0d ====", instr_count);
        $display("==== C matrix output (index -> value) ====");
        for (i = 0; i < 64; i = i + 1) begin
            result_index = i[5:0];
            @(posedge clk);
            $display("C[%0d] = 0x%08x (%0d)", i, result_word, result_word);
        end

        $display("==== DONE ====");
        $finish;
    end
endmodule
