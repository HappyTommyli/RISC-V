 (* keep_hierarchy = "yes" *)
module ssd1306_driver(
    input clk, rst,
    input [7:0] vram_data,
    output reg [6:0] vram_addr,
    output reg sdin, sclk, dc, res, cs
);
    reg [7:0] state;
    reg [19:0] delay_cnt;
    reg [7:0] cmd_rom [0:15];
    reg [3:0] cmd_ptr;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;

    initial begin
        cmd_rom[0]=8'hAE; cmd_rom[1]=8'h8D; cmd_rom[2]=8'h14; // Charge Pump
        cmd_rom[3]=8'hAF; cmd_rom[4]=8'h20; cmd_rom[5]=8'h02; // Page Mode
        cmd_rom[6]=8'hB0; cmd_rom[7]=8'h00; cmd_rom[8]=8'h10; // Reset Pos
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0; res <= 0; cs <= 0; sclk <= 1; cmd_ptr <= 0;
        end else begin
            case (state)
                0: if (delay_cnt < 100000) delay_cnt <= delay_cnt + 1; else begin res <= 1; state <= 1; end
                1: begin 
                    dc <= 0;
                    if (cmd_ptr < 9) begin shift_reg <= cmd_rom[cmd_ptr]; state <= 10; end
                    else state <= 2;
                end
                2: begin 
                    dc <= 0; shift_reg <= 8'hB0; state <= 11;
                end
                3: begin 
                    dc <= 1; shift_reg <= vram_data; state <= 12;
                end
                10, 11, 12: begin 
                    if (bit_cnt < 8) begin
                        sclk <= ~sclk;
                        if (sclk) begin sdin <= shift_reg[7]; shift_reg <= {shift_reg[6:0], 1'b0}; bit_cnt <= bit_cnt + 1; end
                    end else begin
                        bit_cnt <= 0;
                        if (state == 10) begin cmd_ptr <= cmd_ptr + 1; state <= 1; end
                        if (state == 11) state <= 3;
                        if (state == 12) begin
                            vram_addr <= vram_addr + 1;
                            state <= (vram_addr == 127) ? 2 : 3;
                        end
                    end
                end
            endcase
        end
    end
endmodule