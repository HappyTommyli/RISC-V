module Data_Memory (
    input clk,
    input mem_read,
    input mem_write,
    input [31:0]rs2_data, //data need to be writen
    input [31:0]alu_result, //memory address
    input [31:0]instruction,
    output reg [31:0]data_mem_data
  );

  wire [2:0] funct3 = instruction[14:12];

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

/** `timescale 1ns / 1ps

module Data_Memory (
    input clk,
    input mem_read,       // Read enable signal
    input mem_write,      // Write enable signal
    input [31:0] rs2_data,// Data to be written to memory
    input [31:0] alu_result, // Memory address (from ALU output)
    input [2:0] funct3,   // Optimized: only funct3 (previously instruction[14:12])
    output reg [31:0] data_mem_data // Data read from memory
);

// Memory parameters: 4KB = 4096 bytes (address range 0~4095)
parameter MAX_SIZE = 4096;
reg [7:0] memory [0:MAX_SIZE-1]; // Byte-addressable memory array

// Fix 1: Memory initialization (avoids unknown values 'x' in simulation)
initial begin
    integer i;
    for (i = 0; i < MAX_SIZE; i = i + 1) begin
        memory[i] = 8'h00; // Initialize all bytes to 0
    end
end

// Helper function: Check address validity (bounds + alignment)
// access_type: 0=byte(8bit), 1=halfword(16bit), 2=word(32bit)
function automatic logic is_valid_addr(input [31:0] addr, input integer access_type);
    case (access_type)
        0: // Byte operations (no alignment required, only bounds check)
            is_valid_addr = (addr < MAX_SIZE);
        1: // Halfword operations (2-byte alignment required, addr+1 must be valid)
            is_valid_addr = (addr < MAX_SIZE - 1) && (addr[0] == 1'b0);
        2: // Word operations (4-byte alignment required, addr+3 must be valid)
            is_valid_addr = (addr < MAX_SIZE - 3) && (addr[1:0] == 2'b00);
        default: 
            is_valid_addr = 1'b0;
    endcase
endfunction

// Write operation (sequential logic, triggered on positive clock edge)
always @(posedge clk) begin
    // Fix 2: Read-write mutual exclusion (only one operation at a time)
    if (mem_write && !mem_read) begin
        case (funct3)
            3'b000: begin // SB (Store Byte)
                if (is_valid_addr(alu_result, 0)) begin
                    memory[alu_result] <= rs2_data[7:0]; // Write only lower 8 bits
                end
                // No operation for invalid addresses (prevents out-of-bounds)
            end

            3'b001: begin // SH (Store Halfword)
                if (is_valid_addr(alu_result, 1)) begin
                    memory[alu_result]   <= rs2_data[7:0];   // Lower byte
                    memory[alu_result+1] <= rs2_data[15:8];  // Higher byte
                end
                // No operation for invalid/unaligned addresses
            end

            3'b010: begin // SW (Store Word)
                if (is_valid_addr(alu_result, 2)) begin
                    memory[alu_result]   <= rs2_data[7:0];    // Byte 0 (LSB)
                    memory[alu_result+1] <= rs2_data[15:8];   // Byte 1
                    memory[alu_result+2] <= rs2_data[23:16];  // Byte 2
                    memory[alu_result+3] <= rs2_data[31:24];  // Byte 3 (MSB)
                end
                // No operation for invalid/unaligned addresses
            end
        endcase
    end
end

// Read operation (combinational logic, immediate response)
always @(*) begin
    // Fix 3: Read-write mutual exclusion + default value optimization
    // (Output high-impedance when inactive to avoid misinterpreting as 0)
    if (mem_read && !mem_write) begin
        case (funct3)
            3'b000: begin // LB (Load Byte, signed)
                if (is_valid_addr(alu_result, 0)) begin
                    // Sign-extend to 32 bits (fill upper 24 bits with byte's MSB)
                    data_mem_data = {{24{memory[alu_result][7]}}, memory[alu_result]};
                end else begin
                    data_mem_data = 32'hzzzzzzzz; // High-impedance for out-of-bounds
                end
            end

            3'b001: begin // LH (Load Halfword, signed)
                if (is_valid_addr(alu_result, 1)) begin
                    // Sign-extend to 32 bits (fill upper 16 bits with halfword's MSB)
                    data_mem_data = {{16{memory[alu_result+1][7]}}, memory[alu_result+1], memory[alu_result]};
                end else begin
                    data_mem_data = 32'hzzzzzzzz;
                end
            end

            3'b010: begin // LW (Load Word)
                if (is_valid_addr(alu_result, 2)) begin
                    // Combine 4 bytes (note endianness: higher addresses = higher bytes)
                    data_mem_data = {memory[alu_result+3], memory[alu_result+2], memory[alu_result+1], memory[alu_result]};
                end else begin
                    data_mem_data = 32'hzzzzzzzz;
                end
            end

            3'b100: begin // LBU (Load Byte Unsigned)
                if (is_valid_addr(alu_result, 0)) begin
                    // Zero-extend to 32 bits
                    data_mem_data = {24'b0, memory[alu_result]};
                end else begin
                    data_mem_data = 32'hzzzzzzzz;
                end
            end

            3'b101: begin // LHU (Load Halfword Unsigned)
                if (is_valid_addr(alu_result, 1)) begin
                    // Zero-extend to 32 bits
                    data_mem_data = {16'b0, memory[alu_result+1], memory[alu_result]};
                end else begin
                    data_mem_data = 32'hzzzzzzzz;
                end
            end

            default: begin // Invalid funct3
                data_mem_data = 32'hzzzzzzzz;
            end
        endcase
    end else begin
        // Fix 4: Output high-impedance in non-read states (distinguishes from "read 0")
        data_mem_data = 32'hzzzzzzzz;
    end
end

endmodule
*/