module inst_mem (input wire [31:0]pc_address, input wire clk, output reg [31:0]instruction);
  parameter num_of_inst = 1024;
  reg [31:0] memory [0:num_of_inst-1];


  initial
  begin
    integer i;
    for (i = 0; i < num_of_inst; i = i + 1)
    begin
      memory[i] = 32'h00000013;  //nop
    end
  end


  always @(posedge clk)//這個需要posedge clk 嗎? 直接@(*)不行嗎?
  begin
    instruction = memory[pc_address[31:2]];
  end

  
endmodule