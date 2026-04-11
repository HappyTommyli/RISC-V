module Display_Engine (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cmd_data,    // [15:8]=PetID, [7:0]=ExpID
    input  wire        we,          // 0x9000 write enable
    output reg         busy,
    output reg         sclk,
    output reg         mosi,
    output reg         dc,
    output reg         cs
);
    // SSD1306 128x64, 1-bit color.
    // Pet 0: top-left, Pet 1: top-right, Pet 2: bottom-left, Pet 3: bottom-right.

    localparam integer SCLK_DIV = 50; // 100MHz -> ~1MHz SCLK

    localparam [4:0] ST_BOOT      = 5'd0;
    localparam [4:0] ST_INIT_NEXT = 5'd1;
    localparam [4:0] ST_IDLE      = 5'd2;
    localparam [4:0] ST_PAGE_CMD0 = 5'd3;
    localparam [4:0] ST_PAGE_CMD1 = 5'd4;
    localparam [4:0] ST_PAGE_CMD2 = 5'd5;
    localparam [4:0] ST_DATA_SEND = 5'd6;
    localparam [4:0] ST_DATA_NEXT = 5'd7;
    localparam [4:0] ST_TX_SETUP  = 5'd8;
    localparam [4:0] ST_TX_HIGH   = 5'd9;
    localparam [4:0] ST_TX_LOW    = 5'd10;

    localparam [4:0] INIT_LAST = 5'd24;

    reg [4:0] state;
    reg [4:0] next_state;
    reg [4:0] init_idx;

    reg [2:0] page;   // 0..7
    reg [6:0] col;    // 0..127

    reg [7:0] tx_byte;
    reg       tx_dc;
    reg [2:0] tx_bit;
    reg [7:0] div_cnt;

    reg [1:0] pet_id;
    reg       clear_phase;

    // Clamp PetID to 0..3
    wire [1:0] cmd_pet = (cmd_data[15:8] < 8'd4) ? cmd_data[9:8] : 2'd0;

    function [7:0] init_cmd;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  init_cmd = 8'hAE; // display off
                5'd1:  init_cmd = 8'hD5;
                5'd2:  init_cmd = 8'h80;
                5'd3:  init_cmd = 8'hA8;
                5'd4:  init_cmd = 8'h3F;
                5'd5:  init_cmd = 8'hD3;
                5'd6:  init_cmd = 8'h00;
                5'd7:  init_cmd = 8'h40;
                5'd8:  init_cmd = 8'h8D;
                5'd9:  init_cmd = 8'h14;
                5'd10: init_cmd = 8'h20;
                5'd11: init_cmd = 8'h02; // page addressing
                5'd12: init_cmd = 8'hA1;
                5'd13: init_cmd = 8'hC8;
                5'd14: init_cmd = 8'hDA;
                5'd15: init_cmd = 8'h12;
                5'd16: init_cmd = 8'h81;
                5'd17: init_cmd = 8'hCF;
                5'd18: init_cmd = 8'hD9;
                5'd19: init_cmd = 8'hF1;
                5'd20: init_cmd = 8'hDB;
                5'd21: init_cmd = 8'h40;
                5'd22: init_cmd = 8'hA4;
                5'd23: init_cmd = 8'hA6; // normal display
                5'd24: init_cmd = 8'hAF; // display on
                default: init_cmd = 8'hAE;
            endcase
        end
    endfunction

    // Return a data byte for (page, col) based on pet quadrant.
    function [7:0] quadrant_byte;
        input [1:0] pet;
        input [2:0] pg;
        input [6:0] cl;
        reg top;
        reg left;
        begin
            top  = (pg <= 3'd3);   // rows 0..31
            left = (cl <= 7'd63);  // cols 0..63
            case (pet)
                2'd0: quadrant_byte = (top && left)  ? 8'hFF : 8'h00;
                2'd1: quadrant_byte = (top && !left) ? 8'hFF : 8'h00;
                2'd2: quadrant_byte = (!top && left) ? 8'hFF : 8'h00;
                2'd3: quadrant_byte = (!top && !left)? 8'hFF : 8'h00;
                default: quadrant_byte = 8'h00;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state    <= ST_BOOT;
            next_state <= ST_BOOT;
            init_idx <= 5'd0;
            page     <= 3'd0;
            col      <= 7'd0;
            pet_id   <= 2'd0;
            clear_phase <= 1'b1;
            tx_byte  <= 8'd0;
            tx_dc    <= 1'b0;
            tx_bit   <= 3'd0;
            div_cnt  <= 8'd0;
            busy     <= 1'b1;
            sclk     <= 1'b0;
            mosi     <= 1'b0;
            dc       <= 1'b0;
            cs       <= 1'b1;
        end else begin
            case (state)
                ST_BOOT: begin
                    busy       <= 1'b1;
                    tx_byte    <= init_cmd(5'd0);
                    tx_dc      <= 1'b0;
                    next_state <= ST_INIT_NEXT;
                    state      <= ST_TX_SETUP;
                end

                ST_INIT_NEXT: begin
                    busy <= 1'b1;
                    if (init_idx == INIT_LAST) begin
                        busy     <= 1'b0;
                        init_idx <= 5'd0;
                        page     <= 3'd0;
                        col      <= 7'd0;
                        clear_phase <= 1'b1;
                        state    <= ST_PAGE_CMD0;
                    end else begin
                        init_idx   <= init_idx + 1'b1;
                        tx_byte    <= init_cmd(init_idx + 1'b1);
                        tx_dc      <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state      <= ST_TX_SETUP;
                    end
                end

                ST_IDLE: begin
                    busy <= 1'b0;
                    cs   <= 1'b1;
                    sclk <= 1'b0;
                    if (we) begin
                        pet_id <= cmd_pet;
                        page   <= 3'd0;
                        col    <= 7'd0;
                        clear_phase <= 1'b0;
                        busy   <= 1'b1;
                        state  <= ST_PAGE_CMD0;
                    end
                end

                ST_PAGE_CMD0: begin
                    tx_byte    <= 8'hB0 + {5'd0, page};
                    tx_dc      <= 1'b0;
                    next_state <= ST_PAGE_CMD1;
                    state      <= ST_TX_SETUP;
                end

                ST_PAGE_CMD1: begin
                    tx_byte    <= 8'h00; // column low
                    tx_dc      <= 1'b0;
                    next_state <= ST_PAGE_CMD2;
                    state      <= ST_TX_SETUP;
                end

                ST_PAGE_CMD2: begin
                    tx_byte    <= 8'h10; // column high
                    tx_dc      <= 1'b0;
                    next_state <= ST_DATA_SEND;
                    state      <= ST_TX_SETUP;
                end

                ST_DATA_SEND: begin
                    tx_byte    <= clear_phase ? 8'h00 : quadrant_byte(pet_id, page, col);
                    tx_dc      <= 1'b1;
                    next_state <= ST_DATA_NEXT;
                    state      <= ST_TX_SETUP;
                end

                ST_DATA_NEXT: begin
                    if (col == 7'd127) begin
                        col <= 7'd0;
                        if (page == 3'd7) begin
                            if (clear_phase) begin
                                clear_phase <= 1'b0;
                            end
                            state <= ST_IDLE;
                        end else begin
                            page <= page + 1'b1;
                            state <= ST_PAGE_CMD0;
                        end
                    end else begin
                        col <= col + 1'b1;
                        state <= ST_DATA_SEND;
                    end
                end

                ST_TX_SETUP: begin
                    cs    <= 1'b0;
                    dc    <= tx_dc;
                    mosi  <= tx_byte[7];
                    tx_bit <= 3'd7;
                    div_cnt <= 8'd0;
                    state <= ST_TX_HIGH;
                end

                ST_TX_HIGH: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk <= 1'b1;
                        div_cnt <= 8'd0;
                        state <= ST_TX_LOW;
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                ST_TX_LOW: begin
                    if (div_cnt == SCLK_DIV - 1) begin
                        sclk <= 1'b0;
                        div_cnt <= 8'd0;
                        if (tx_bit == 3'd0) begin
                            cs <= 1'b1;
                            state <= next_state;
                        end else begin
                            tx_bit <= tx_bit - 1'b1;
                            mosi <= tx_byte[tx_bit - 1'b1];
                            state <= ST_TX_HIGH;
                        end
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
