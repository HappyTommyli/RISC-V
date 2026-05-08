`timescale 1ns / 1ps

module tetris_top (
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx,
    output wire led0
);
    // ------------------------------------------------------------------------
    // CPU <-> UART bridge wires
    wire       cpu_uart_tx_we;
    wire [7:0] cpu_uart_tx_data;
    wire [7:0] cpu_uart_rx_data;
    wire       cpu_uart_rx_valid;
    wire       cpu_uart_rx_pop;

    // pipeline_lut_opt CPU (modified version under tetris_pipeline_lut_opt/CPU)
    pipeline u_cpu (
        .clk          (clk),
        .rst          (rst),
        .uart_tx_we   (cpu_uart_tx_we),
        .uart_tx_data (cpu_uart_tx_data),
        .uart_rx_data (cpu_uart_rx_data),
        .uart_rx_valid(cpu_uart_rx_valid),
        .uart_rx_pop  (cpu_uart_rx_pop)
    );

    // ------------------------------------------------------------------------
    // UART RX path (single-byte holding register until CPU pops)
    wire       rx_byte_valid;
    wire [7:0] rx_byte_data;
    reg        rx_hold_valid;
    reg [7:0]  rx_hold_data;

    uart_rx #(
        .CLK_HZ  (100_000_000),
        .BAUDRATE(115200)
    ) u_uart_rx (
        .clk        (clk),
        .rst        (rst),
        .rx         (uart_rx),
        .data_valid (rx_byte_valid),
        .data_out   (rx_byte_data)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_hold_valid <= 1'b0;
            rx_hold_data  <= 8'h00;
        end else begin
            if (cpu_uart_rx_pop) begin
                rx_hold_valid <= 1'b0;
            end

            if (!rx_hold_valid && rx_byte_valid) begin
                rx_hold_valid <= 1'b1;
                rx_hold_data  <= rx_byte_data;
            end
        end
    end

    assign cpu_uart_rx_valid = rx_hold_valid;
    assign cpu_uart_rx_data  = rx_hold_data;

    // ------------------------------------------------------------------------
    // UART TX path (FIFO to absorb CPU burst output)
    localparam TX_FIFO_AW = 10;               // 2^10 = 1024 bytes
    localparam TX_FIFO_DP = (1 << TX_FIFO_AW);

    reg [7:0] tx_fifo_mem [0:TX_FIFO_DP-1];
    reg [TX_FIFO_AW-1:0] tx_wptr;
    reg [TX_FIFO_AW-1:0] tx_rptr;
    reg [TX_FIFO_AW:0]   tx_count;

    wire tx_fifo_empty = (tx_count == 0);
    wire tx_fifo_full  = (tx_count == TX_FIFO_DP);

    reg        tx_start;
    reg [7:0]  tx_data;
    wire       tx_busy;

    uart_tx #(
        .CLK_HZ  (100_000_000),
        .BAUDRATE(115200)
    ) u_uart_tx (
        .clk   (clk),
        .rst   (rst),
        .start (tx_start),
        .data  (tx_data),
        .tx    (uart_tx),
        .busy  (tx_busy)
    );

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_wptr  <= {TX_FIFO_AW{1'b0}};
            tx_rptr  <= {TX_FIFO_AW{1'b0}};
            tx_count <= {(TX_FIFO_AW+1){1'b0}};
            tx_start <= 1'b0;
            tx_data  <= 8'h00;
            for (i = 0; i < TX_FIFO_DP; i = i + 1) begin
                tx_fifo_mem[i] <= 8'h00;
            end
        end else begin
            tx_start <= 1'b0;

            // CPU write to FIFO
            if (cpu_uart_tx_we && !tx_fifo_full) begin
                tx_fifo_mem[tx_wptr] <= cpu_uart_tx_data;
                tx_wptr <= tx_wptr + 1'b1;
            end

            // UART consume from FIFO
            if (!tx_busy && !tx_fifo_empty) begin
                tx_data  <= tx_fifo_mem[tx_rptr];
                tx_rptr  <= tx_rptr + 1'b1;
                tx_start <= 1'b1;
            end

            // Count update with simultaneous push/pop handling
            case ({(cpu_uart_tx_we && !tx_fifo_full), (!tx_busy && !tx_fifo_empty)})
                2'b10: tx_count <= tx_count + 1'b1; // push only
                2'b01: tx_count <= tx_count - 1'b1; // pop only
                default: tx_count <= tx_count;      // both or none
            endcase
        end
    end

    // Debug LED: on when RX holding register has unread key
    assign led0 = rx_hold_valid;

endmodule

// ----------------------------------------------------------------------------
// UART transmitter: 8N1
module uart_tx #(
    parameter integer CLK_HZ   = 100_000_000,
    parameter integer BAUDRATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);
    localparam integer BAUD_DIV = CLK_HZ / BAUDRATE;

    reg [15:0] baud_cnt;
    reg [3:0]  bit_idx;
    reg [9:0]  shifter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx       <= 1'b1;
            busy     <= 1'b0;
            baud_cnt <= 16'd0;
            bit_idx  <= 4'd0;
            shifter  <= 10'h3FF;
        end else begin
            if (!busy) begin
                tx <= 1'b1;
                if (start) begin
                    // {stop(1), data[7:0], start(0)}
                    shifter  <= {1'b1, data, 1'b0};
                    busy     <= 1'b1;
                    baud_cnt <= 16'd0;
                    bit_idx  <= 4'd0;
                    tx       <= 1'b0; // start bit immediately
                end
            end else begin
                if (baud_cnt == (BAUD_DIV - 1)) begin
                    baud_cnt <= 16'd0;
                    bit_idx  <= bit_idx + 1'b1;
                    shifter  <= {1'b1, shifter[9:1]};
                    tx       <= shifter[1];

                    if (bit_idx == 4'd9) begin
                        busy <= 1'b0;
                        tx   <= 1'b1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                end
            end
        end
    end
endmodule

// ----------------------------------------------------------------------------
// UART receiver: 8N1, single-cycle data_valid pulse on each received byte
module uart_rx #(
    parameter integer CLK_HZ   = 100_000_000,
    parameter integer BAUDRATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg        data_valid,
    output reg [7:0]  data_out
);
    localparam integer BAUD_DIV      = CLK_HZ / BAUDRATE;
    localparam integer HALF_BAUD_DIV = BAUD_DIV / 2;

    reg [2:0] rx_sync;
    reg [15:0] baud_cnt;
    reg [3:0] bit_idx;
    reg [7:0] rx_shift;
    reg       receiving;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync    <= 3'b111;
            baud_cnt   <= 16'd0;
            bit_idx    <= 4'd0;
            rx_shift   <= 8'h00;
            receiving  <= 1'b0;
            data_valid <= 1'b0;
            data_out   <= 8'h00;
        end else begin
            rx_sync <= {rx_sync[1:0], rx};
            data_valid <= 1'b0;

            if (!receiving) begin
                // detect start bit (falling edge)
                if (rx_sync[2:1] == 2'b10) begin
                    receiving <= 1'b1;
                    baud_cnt  <= 16'd0;
                    bit_idx   <= 4'd0;
                end
            end else begin
                if (bit_idx == 4'd0) begin
                    // start bit validation at mid-bit
                    if (baud_cnt == (HALF_BAUD_DIV - 1)) begin
                        baud_cnt <= 16'd0;
                        if (rx_sync[2] == 1'b0) begin
                            bit_idx <= 4'd1;
                        end else begin
                            receiving <= 1'b0;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end else begin
                    if (baud_cnt == (BAUD_DIV - 1)) begin
                        baud_cnt <= 16'd0;

                        if (bit_idx >= 4'd1 && bit_idx <= 4'd8) begin
                            rx_shift <= {rx_sync[2], rx_shift[7:1]};
                            bit_idx  <= bit_idx + 1'b1;
                        end else if (bit_idx == 4'd9) begin
                            // stop bit sampled
                            receiving  <= 1'b0;
                            data_out   <= rx_shift;
                            data_valid <= 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end
            end
        end
    end
endmodule
