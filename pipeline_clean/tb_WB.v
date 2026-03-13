// tb_WB.v
`timescale 1ns/1ps

module tb_WB;

   reg  [31:0] mem_data;
   reg  [31:0] alu_result;
   reg  [4:0]  rd;
   reg         reg_write;
   reg         mem_reg;

   wire [31:0] wb_data;
   wire [4:0]  wb_rd;
   wire        wb_regwrite;

   WB u_WB (
       .mem_data   (mem_data),
       .alu_result (alu_result),
       .rd         (rd),
       .reg_write  (reg_write),
       .mem_reg    (mem_reg),
       .wb_data    (wb_data),
       .wb_rd      (wb_rd),
       .wb_regwrite(wb_regwrite)
   );

   initial begin
      $display("========================================");
      $display("   WB Stage Simulation (Vivado)        ");
      $display("========================================");

      // ---- initialise inputs ----
      mem_data   = 32'hXXXX_XXXX;
      alu_result = 32'hXXXX_XXXX;
      rd         = 5'd0;
      reg_write  = 1'b0;
      mem_reg    = 1'b0;
      #10;

      // ---- Test 1 : ALU path (mem_reg = 0) ----
      $display("\n[1] ALU path (mem_reg = 0)");
      alu_result = 32'h55AA_55AA;
      mem_reg    = 1'b0;
      rd         = 5'd12;
      reg_write  = 1'b1;
      #10;
      if (wb_data === 32'h55AA_55AA && wb_rd == 5'd12 && wb_regwrite)
        $display("  PASS: wb_data = 0x%h, wb_rd = %0d", wb_data, wb_rd);
      else
        $error("  FAIL: ALU path");

      // ---- Test 2 : Memory path (mem_reg = 1) ----
      $display("\n[2] Memory path (mem_reg = 1)");
      mem_data   = 32'hDEAD_BEEF;
      mem_reg    = 1'b1;
      #10;
      if (wb_data === 32'hDEAD_BEEF)
        $display("  PASS: wb_data = 0x%h (from mem)", wb_data);
      else
        $error("  FAIL: Memory path");

      // ---- Test 3 : No write (reg_write = 0) ----
      $display("\n[3] reg_write = 0");
      reg_write = 1'b0;
      #10;
      if (wb_regwrite === 1'b0)
        $display("  PASS: wb_regwrite = 0");
      else
        $error("  FAIL: wb_regwrite should be 0");

      // ---- Test 4 : rd pass-through (any value) ----
      $display("\n[4] rd pass-through");
      rd = 5'd31;
      reg_write = 1'b1;
      #10;
      if (wb_rd == 5'd31)
        $display("  PASS: wb_rd = %0d", wb_rd);
      else
        $error("  FAIL: wb_rd expected 31");

      // ---- End of test ----
      #20;
      $display("\n========================================");
      $display("        ALL TESTS FINISHED            ");
      $display("========================================");
      $finish;
   end

endmodule