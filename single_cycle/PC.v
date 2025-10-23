module pc (
    input wire clk,
    input wire rst,
    input wire [31:0] next_pc,
    output reg [31:0] pc_address
  );

  always @(negedge clk or posedge rst)
  begin
    if (rst)
    begin
      pc_address <= 32'b0; // reset PC to 0
    end
    else
    begin
      pc_address <= next_pc; // update PC to next_pc
    end
  end

endmodule

