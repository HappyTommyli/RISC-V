`timescale 1ns / 1ps

// MMIO helper for pipeline_lut_opt Data_Memory integration.
// Address map:
// 0x8000_0000 : UART TX write (low 8-bit)
// 0x8000_0004 : UART RX read  (low 8-bit)
// 0x8000_0008 : UART RX status bit0 (1=data ready)
// 0x8000_000C : timer_seconds
module mmio_timer_uart #(
    parameter CLK_HZ = 57_800_000
)(
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] addr,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] wdata,

    output reg  [31:0] rdata,
    output wire        mmio_hit,

    // Hook these to your real UART blocks.
    output reg         uart_tx_we,
    output reg  [7:0]  uart_tx_data,

    input  wire [7:0]  uart_rx_data,
    input  wire        uart_rx_valid,
    output reg         uart_rx_pop
);
    localparam UART_TX_ADDR   = 32'h8000_0000;
    localparam UART_RX_ADDR   = 32'h8000_0004;
    localparam UART_STAT_ADDR = 32'h8000_0008;
    localparam TIMER_ADDR     = 32'h8000_000C;

    wire is_tx   = (addr == UART_TX_ADDR);
    wire is_rx   = (addr == UART_RX_ADDR);
    wire is_stat = (addr == UART_STAT_ADDR);
    wire is_tim  = (addr == TIMER_ADDR);

    assign mmio_hit = is_tx | is_rx | is_stat | is_tim;

    reg [31:0] sec_div;
    reg [31:0] timer_seconds;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sec_div       <= 32'd0;
            timer_seconds <= 32'd0;
        end else begin
            if (sec_div == (CLK_HZ - 1)) begin
                sec_div       <= 32'd0;
                timer_seconds <= timer_seconds + 32'd1;
            end else begin
                sec_div <= sec_div + 32'd1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            uart_tx_we   <= 1'b0;
            uart_tx_data <= 8'h00;
            uart_rx_pop  <= 1'b0;
        end else begin
            uart_tx_we  <= 1'b0;
            uart_rx_pop <= 1'b0;

            if (mem_write && is_tx) begin
                uart_tx_data <= wdata[7:0];
                uart_tx_we   <= 1'b1;
            end

            if (mem_read && is_rx && uart_rx_valid) begin
                uart_rx_pop <= 1'b1;
            end
        end
    end

    always @(*) begin
        rdata = 32'b0;
        if (mem_read) begin
            if (is_rx) begin
                rdata = {24'b0, uart_rx_data};
            end else if (is_stat) begin
                rdata = {31'b0, uart_rx_valid};
            end else if (is_tim) begin
                rdata = timer_seconds;
            end
        end
    end
endmodule
