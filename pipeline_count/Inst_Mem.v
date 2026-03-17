// (* keep_hierarchy = "yes" *)
module inst_mem_count (
    input  wire [31:0] pc_address,
    output reg  [31:0] instruction
);
  localparam NUM_OF_INST = 256;

  // Force distributed ROM (combinational read)
  (* rom_style = "distributed" *) reg [31:0] memory [0:NUM_OF_INST-1];
  wire [7:0] word_addr = pc_address[9:2];

  integer i;
  initial begin
    // default fill with NOP
    for (i = 0; i < NUM_OF_INST; i = i + 1) begin
      memory[i] = 32'h00000013;
    end

    // Stress_test benchmark instructions
    memory[0] = 32'h000012b7;
    memory[1] = 32'h00028293;
    memory[2] = 32'h00001337;
    memory[3] = 32'h10030313;
    memory[4] = 32'h000013b7;
    memory[5] = 32'h20038393;
    memory[6] = 32'h04000e13;
    memory[7] = 32'h00100513;
    memory[8] = 32'h00a2a023;
    memory[9] = 32'h00428293;
    memory[10] = 32'h00150513;
    memory[11] = 32'hfffe0e13;
    memory[12] = 32'hfe0e18e3;
    memory[13] = 32'h000012b7;
    memory[14] = 32'h00028293;
    memory[15] = 32'h00001337;
    memory[16] = 32'h10030313;
    memory[17] = 32'h04000e13;
    memory[18] = 32'h0002a503;
    memory[19] = 32'h00a32023;
    memory[20] = 32'h00428293;
    memory[21] = 32'h00430313;
    memory[22] = 32'hfffe0e13;
    memory[23] = 32'hfe0e16e3;
    memory[24] = 32'h000012b7;
    memory[25] = 32'h00028293;
    memory[26] = 32'h00001337;
    memory[27] = 32'h10030313;
    memory[28] = 32'h000013b7;
    memory[29] = 32'h20038393;
    memory[30] = 32'h00800993;
    memory[31] = 32'h00000413;
    memory[32] = 32'h00541f93;
    memory[33] = 32'h01f28e33;
    memory[34] = 32'h01f38eb3;
    memory[35] = 32'h00000493;
    memory[36] = 32'h00000713;
    memory[37] = 32'h000e0613;
    memory[38] = 32'h00249f13;
    memory[39] = 32'h01e306b3;
    memory[40] = 32'h00800913;
    memory[41] = 32'h00062503;
    memory[42] = 32'h0006a583;
    memory[43] = 32'h00000813;
    memory[44] = 32'h00058793;
    memory[45] = 32'h00078863;
    memory[46] = 32'h00a80833;
    memory[47] = 32'hfff78793;
    memory[48] = 32'hff5ff06f;
    memory[49] = 32'h01070733;
    memory[50] = 32'h00460613;
    memory[51] = 32'h02068693;
    memory[52] = 32'hfff90913;
    memory[53] = 32'hfc0918e3;
    memory[54] = 32'h00249f13;
    memory[55] = 32'h01ee8fb3;
    memory[56] = 32'h00efa023;
    memory[57] = 32'h00148493;
    memory[58] = 32'hfb3494e3;
    memory[59] = 32'h00140413;
    memory[60] = 32'hf93418e3;
    memory[61] = 32'h0000006f;
  end

  always @(*) begin
    instruction = memory[word_addr];
  end
endmodule
