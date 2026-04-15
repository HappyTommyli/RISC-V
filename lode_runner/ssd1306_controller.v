`timescale 1ns / 1ps

module ssd1306_controller (
    input  wire       clk,
    input  wire       rst,
    output reg [9:0]  fb_addr,
    input  wire [7:0] fb_data,
    output reg        oled_sclk,
    output reg        oled_mosi,
    output reg        oled_dc,
    output reg        oled_res,
    output reg        oled_cs,
    output reg        oled_vbat,
    output reg        oled_vdd
);
    localparam integer DIVIDER = 25; // 100MHz / (2*25) = 2MHz SPI clock

    localparam ST_PWR_WAIT   = 4'd0;
    localparam ST_INIT_LOAD  = 4'd1;
    localparam ST_INIT_SEND  = 4'd2;
    localparam ST_PAGE_CMD   = 4'd3;
    localparam ST_PAGE_SEND  = 4'd4;

    reg [3:0]  state;
    reg [7:0]  init_rom [0:25];
    reg [5:0]  init_idx;
    reg [7:0]  shreg;
    reg [2:0]  bit_cnt;
    reg [15:0] div_cnt;
    reg [7:0]  pwr_wait_cnt;
    reg [2:0]  page;
    reg [1:0]  cmd_step;
    reg        spi_busy;

    initial begin
        init_rom[0]  = 8'hAE;
        init_rom[1]  = 8'hD5;
        init_rom[2]  = 8'h80;
        init_rom[3]  = 8'hA8;
        init_rom[4]  = 8'h3F;
        init_rom[5]  = 8'hD3;
        init_rom[6]  = 8'h00;
        init_rom[7]  = 8'h40;
        init_rom[8]  = 8'h8D;
        init_rom[9]  = 8'h14;
        init_rom[10] = 8'h20;
        init_rom[11] = 8'h00;
        init_rom[12] = 8'hA1;
        init_rom[13] = 8'hC8;
        init_rom[14] = 8'hDA;
        init_rom[15] = 8'h12;
        init_rom[16] = 8'h81;
        init_rom[17] = 8'hCF;
        init_rom[18] = 8'hD9;
        init_rom[19] = 8'hF1;
        init_rom[20] = 8'hDB;
        init_rom[21] = 8'h40;
        init_rom[22] = 8'hA4;
        init_rom[23] = 8'hA6;
        init_rom[24] = 8'hAF;
        init_rom[25] = 8'h00;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_PWR_WAIT;
            oled_sclk <= 1'b0;
            oled_mosi <= 1'b0;
            oled_dc <= 1'b0;
            oled_res <= 1'b0;
            oled_cs <= 1'b0;
            oled_vbat <= 1'b0;
            oled_vdd <= 1'b0;
            init_idx <= 6'd0;
            bit_cnt <= 3'd0;
            div_cnt <= 16'd0;
            pwr_wait_cnt <= 8'd0;
            page <= 3'd0;
            cmd_step <= 2'd0;
            fb_addr <= 10'd0;
            spi_busy <= 1'b0;
        end else begin
            if (spi_busy) begin
                if (div_cnt == DIVIDER - 1) begin
                    div_cnt <= 16'd0;
                    oled_sclk <= ~oled_sclk;
                    if (oled_sclk == 1'b0) begin
                        oled_mosi <= shreg[7];
                        shreg <= {shreg[6:0], 1'b0};
                        if (bit_cnt == 3'd7) begin
                            spi_busy <= 1'b0;
                            bit_cnt <= 3'd0;
                        end else begin
                            bit_cnt <= bit_cnt + 3'd1;
                        end
                    end
                end else begin
                    div_cnt <= div_cnt + 16'd1;
                end
            end else begin
                oled_sclk <= 1'b0;
                case (state)
                    ST_PWR_WAIT: begin
                        pwr_wait_cnt <= pwr_wait_cnt + 8'd1;
                        if (pwr_wait_cnt == 8'hFF) begin
                            oled_res <= 1'b1;
                            state <= ST_INIT_LOAD;
                            init_idx <= 6'd0;
                        end
                    end

                    ST_INIT_LOAD: begin
                        oled_dc <= 1'b0;
                        shreg <= init_rom[init_idx];
                        spi_busy <= 1'b1;
                        state <= ST_INIT_SEND;
                    end

                    ST_INIT_SEND: begin
                        if (!spi_busy) begin
                            if (init_idx == 6'd24) begin
                                state <= ST_PAGE_CMD;
                                page <= 3'd0;
                                cmd_step <= 2'd0;
                                fb_addr <= 10'd0;
                            end else begin
                                init_idx <= init_idx + 6'd1;
                                state <= ST_INIT_LOAD;
                            end
                        end
                    end

                    ST_PAGE_CMD: begin
                        oled_dc <= 1'b0;
                        case (cmd_step)
                            2'd0: shreg <= {5'b10110, page};
                            2'd1: shreg <= 8'h00;
                            default: shreg <= 8'h10;
                        endcase
                        spi_busy <= 1'b1;
                        cmd_step <= cmd_step + 2'd1;
                        if (cmd_step == 2'd2) begin
                            cmd_step <= 2'd0;
                            state <= ST_PAGE_SEND;
                        end
                    end

                    ST_PAGE_SEND: begin
                        if (!spi_busy) begin
                            oled_dc <= 1'b1;
                            shreg <= fb_data;
                            spi_busy <= 1'b1;
                            if (fb_addr[6:0] == 7'd127) begin
                                if (page == 3'd7) begin
                                    page <= 3'd0;
                                    fb_addr <= 10'd0;
                                    state <= ST_PAGE_CMD;
                                end else begin
                                    page <= page + 3'd1;
                                    fb_addr <= {page + 3'd1, 7'd0};
                                    state <= ST_PAGE_CMD;
                                end
                            end else begin
                                fb_addr <= fb_addr + 10'd1;
                            end
                        end
                    end

                    default: state <= ST_PWR_WAIT;
                endcase
            end
        end
    end
endmodule
