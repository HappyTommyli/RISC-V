module Data_Memory (
    input clk,
    input mem_read,
    input mem_write,
    input [31:0]rs2_data, //data need to be writen
    input [31:0]alu_result, //memory address
    input [31:0]instruction,
    output reg [31:0]data_mem_data
  );

  wire [2:0] funct3;
  assign funct3 = instruction[14:12];

  parameter max_size = 4096;
  reg [7:0] memory [0:max_size-1]; //4KB memory
  integer i;
  initial begin
    for ( i=0 ;i<max_size ;i= i+1 ) begin
      memory[i] = 8'd0;
    end
  end
  //write
  always @(posedge clk)
  begin
    if(mem_write)
    begin
      case (funct3)
        3'b000://sb, byte
        begin
          memory[alu_result] <= rs2_data[7:0];
        end

        3'b001://sh, halfword
        begin
          memory[alu_result] <= rs2_data[7:0];
          memory[alu_result+1] <= rs2_data[15:8];
        end

        3'b010://sw, word
        begin
          memory[alu_result] <= rs2_data[7:0];
          memory[alu_result+1] <= rs2_data[15:8];
          memory[alu_result+2] <= rs2_data[23:16];
          memory[alu_result+3] <= rs2_data[31:24];
        end
      endcase
    end//endif
  end//endalways

  //read
  always @(*)
  begin
    if(mem_read)
    begin
      case (funct3)
        3'b000://lb
          data_mem_data = {{24{memory[alu_result][7]}}, memory[alu_result]};
        3'b001://lh
          data_mem_data = {{16{memory[alu_result+1][7]}}, memory[alu_result+1][7:0], memory[alu_result][7:0]};
        3'b010://lw
          data_mem_data = {memory[alu_result+3], memory[alu_result+2], memory[alu_result+1], memory[alu_result]};
        3'b100://lbu, unsigned
          data_mem_data = {24'b0, memory[alu_result]};
        3'b101://lhu
          data_mem_data = {16'b0, memory[alu_result+1], memory[alu_result]};
        default:
          data_mem_data = 32'b0;
      endcase
    end//endif

    else
    begin
      data_mem_data = 32'b0;
    end//endelse

  end//endalways

endmodule


//alu_result(address)的最低两位永远是0，所以alu_result是四位四位递增的。所以才需要用到alu_result+1 or +2 or +3
//是否需要边界检查，例如大于max_size的情况