(* keep_hierarchy = "yes" *)
module Data_Memory (
    input             clk,
    input             rst,
    input             mem_read,
    input             mem_write,
    input      [31:0] rs2_data,
    input      [31:0] alu_result,
    input      [31:0] instruction,
    output reg [31:0] data_mem_data,
    output reg        uart_tx_we,
    output reg [7:0]  uart_tx_data,
    input      [7:0]  uart_rx_data,
    input             uart_rx_valid,
    output reg        uart_rx_pop
);
    wire [2:0] funct3 = instruction[14:12];

    // 16KB data memory (byte-addressed): 4 lanes x 4096 bytes
    parameter WORDS = 4096;

    (* ram_style = "block" *) reg [7:0] mem_b0 [0:WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem_b1 [0:WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem_b2 [0:WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem_b3 [0:WORDS-1];

    wire [31:0] word_idx  = alu_result[31:2];
    wire [1:0]  byte_off  = alu_result[1:0];

    reg [7:0] q_b0, q_b1, q_b2, q_b3;

    reg [31:0] sec_div;
    reg [31:0] timer_seconds;

    localparam UART_TX_ADDR   = 32'h8000_0000;
    localparam UART_RX_ADDR   = 32'h8000_0004;
    localparam UART_STAT_ADDR = 32'h8000_0008;
    localparam TIMER_ADDR     = 32'h8000_000C;
    localparam CLK_HZ         = 32'd57_800_000;

    wire is_uart_tx   = (alu_result == UART_TX_ADDR);
    wire is_uart_rx   = (alu_result == UART_RX_ADDR);
    wire is_uart_stat = (alu_result == UART_STAT_ADDR);
    wire is_timer     = (alu_result == TIMER_ADDR);
    wire is_mmio      = is_uart_tx | is_uart_rx | is_uart_stat | is_timer;

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            uart_tx_we    <= 1'b0;
            uart_tx_data  <= 8'b0;
            uart_rx_pop   <= 1'b0;
            sec_div       <= 32'b0;
            timer_seconds <= 32'b0;
            q_b0          <= 8'b0;
            q_b1          <= 8'b0;
            q_b2          <= 8'b0;
            q_b3          <= 8'b0;

            // Keep deterministic startup behavior
            for (i = 0; i < WORDS; i = i + 1) begin
                mem_b0[i] <= 8'b0;
                mem_b1[i] <= 8'b0;
                mem_b2[i] <= 8'b0;
                mem_b3[i] <= 8'b0;
            end
        end else begin
            uart_tx_we  <= 1'b0;
            uart_rx_pop <= 1'b0;

            // 1Hz timer from 57.8MHz clock
            if (sec_div == (CLK_HZ - 1)) begin
                sec_div       <= 32'b0;
                timer_seconds <= timer_seconds + 32'd1;
            end else begin
                sec_div <= sec_div + 32'd1;
            end

            // Synchronous read capture for RAM space
            if (mem_read && !is_mmio) begin
                q_b0 <= mem_b0[word_idx];
                q_b1 <= mem_b1[word_idx];
                q_b2 <= mem_b2[word_idx];
                q_b3 <= mem_b3[word_idx];
            end

            // Memory write
            if (mem_write) begin
                if (is_uart_tx) begin
                    uart_tx_data <= rs2_data[7:0];
                    uart_tx_we   <= 1'b1;
                end else if (!is_mmio) begin
                    case (funct3)
                        3'b000: begin // SB
                            case (byte_off)
                                2'b00: mem_b0[word_idx] <= rs2_data[7:0];
                                2'b01: mem_b1[word_idx] <= rs2_data[7:0];
                                2'b10: mem_b2[word_idx] <= rs2_data[7:0];
                                2'b11: mem_b3[word_idx] <= rs2_data[7:0];
                            endcase
                        end
                        3'b001: begin // SH
                            if (byte_off[1] == 1'b0) begin
                                mem_b0[word_idx] <= rs2_data[7:0];
                                mem_b1[word_idx] <= rs2_data[15:8];
                            end else begin
                                mem_b2[word_idx] <= rs2_data[7:0];
                                mem_b3[word_idx] <= rs2_data[15:8];
                            end
                        end
                        3'b010: begin // SW
                            mem_b0[word_idx] <= rs2_data[7:0];
                            mem_b1[word_idx] <= rs2_data[15:8];
                            mem_b2[word_idx] <= rs2_data[23:16];
                            mem_b3[word_idx] <= rs2_data[31:24];
                        end
                        default: begin
                            // no-op
                        end
                    endcase
                end
            end

            if (mem_read && is_uart_rx && uart_rx_valid) begin
                uart_rx_pop <= 1'b1;
            end
        end
    end

    wire [31:0] word_q = {q_b3, q_b2, q_b1, q_b0};

    always @(*) begin
        data_mem_data = 32'b0;
        if (mem_read) begin
            if (is_uart_rx) begin
                data_mem_data = {24'b0, uart_rx_data};
            end else if (is_uart_stat) begin
                data_mem_data = {31'b0, uart_rx_valid};
            end else if (is_timer) begin
                data_mem_data = timer_seconds;
            end else begin
                case (funct3)
                    3'b000: begin // LB
                        case (byte_off)
                            2'b00: data_mem_data = {{24{word_q[7]}},  word_q[7:0]};
                            2'b01: data_mem_data = {{24{word_q[15]}}, word_q[15:8]};
                            2'b10: data_mem_data = {{24{word_q[23]}}, word_q[23:16]};
                            2'b11: data_mem_data = {{24{word_q[31]}}, word_q[31:24]};
                        endcase
                    end
                    3'b001: begin // LH
                        if (byte_off[1] == 1'b0)
                            data_mem_data = {{16{word_q[15]}}, word_q[15:0]};
                        else
                            data_mem_data = {{16{word_q[31]}}, word_q[31:16]};
                    end
                    3'b010: begin // LW
                        data_mem_data = word_q;
                    end
                    3'b100: begin // LBU
                        case (byte_off)
                            2'b00: data_mem_data = {24'b0, word_q[7:0]};
                            2'b01: data_mem_data = {24'b0, word_q[15:8]};
                            2'b10: data_mem_data = {24'b0, word_q[23:16]};
                            2'b11: data_mem_data = {24'b0, word_q[31:24]};
                        endcase
                    end
                    3'b101: begin // LHU
                        if (byte_off[1] == 1'b0)
                            data_mem_data = {16'b0, word_q[15:0]};
                        else
                            data_mem_data = {16'b0, word_q[31:16]};
                    end
                    default: data_mem_data = 32'b0;
                endcase
            end
        end
    end
endmodule
