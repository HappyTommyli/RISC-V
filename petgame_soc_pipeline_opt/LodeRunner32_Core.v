module LodeRunner32_Core (
    input  wire       clk,
    input  wire       reset,
    input  wire       btn_up,
    input  wire       btn_down,
    input  wire       btn_left,
    input  wire       btn_right,
    input  wire [6:0] rd_addr,
    output reg  [7:0] rd_data,
    output reg  [3:0] score,
    output reg        game_clear
);
    // 4x4 tiles, each 8x8 pixels -> 32x32 screen.
    reg [2:0] tile_map [0:15];

    reg [5:0] player_x;
    reg [5:0] player_y;
    reg [2:0] anim_kind;
    reg       anim_phase;
    reg [23:0] tick_cnt;

    localparam integer TICK_DIV = 24'd8_000_000; // ~80ms @100MHz

    localparam [2:0] TILE_EMPTY  = 3'd0;
    localparam [2:0] TILE_BRICK  = 3'd1;
    localparam [2:0] TILE_STAIR  = 3'd2;
    localparam [2:0] TILE_PIPE   = 3'd3;
    localparam [2:0] TILE_GOLD   = 3'd4;
    localparam [2:0] TILE_WALL   = 3'd5;

    localparam [2:0] ANIM_FLYING = 3'd0;
    localparam [2:0] ANIM_UPDOWN = 3'd1;
    localparam [2:0] ANIM_LEFT   = 3'd2;
    localparam [2:0] ANIM_RIGHT  = 3'd3;
    localparam [2:0] ANIM_RPIPE  = 3'd4;
    localparam [2:0] ANIM_LPIPE  = 3'd5;

    function [4:0] sat5;
        input signed [6:0] v;
        begin
            if (v < 0) sat5 = 5'd0;
            else if (v > 31) sat5 = 5'd31;
            else sat5 = v[4:0];
        end
    endfunction

    function [1:0] tile_x_of;
        input [4:0] x;
        begin
            tile_x_of = x[4:3];
        end
    endfunction

    function [1:0] tile_y_of;
        input [4:0] y;
        begin
            tile_y_of = y[4:3];
        end
    endfunction

    function [4:0] tile_index_xy;
        input [1:0] tx;
        input [1:0] ty;
        begin
            tile_index_xy = {ty, tx}; // ty*4 + tx
        end
    endfunction

    function [2:0] map_value_at;
        input [4:0] x;
        input [4:0] y;
        reg [1:0] tx;
        reg [1:0] ty;
        begin
            tx = tile_x_of(x);
            ty = tile_y_of(y);
            map_value_at = tile_map[tile_index_xy(tx, ty)];
        end
    endfunction

    function is_walkable;
        input [2:0] t;
        begin
            is_walkable = (t == TILE_EMPTY) || (t == TILE_STAIR) || (t == TILE_PIPE) || (t == TILE_GOLD);
        end
    endfunction

    function is_solid;
        input [2:0] t;
        begin
            is_solid = (t == TILE_BRICK) || (t == TILE_STAIR) || (t == TILE_WALL);
        end
    endfunction

    function is_pipe;
        input [2:0] t;
        begin
            is_pipe = (t == TILE_PIPE);
        end
    endfunction

    function is_stair;
        input [2:0] t;
        begin
            is_stair = (t == TILE_STAIR);
        end
    endfunction

    function [7:0] tile_row_bits;
        input [2:0] t;
        input [2:0] ry;
        begin
            case (t)
                TILE_BRICK: begin
                    case (ry)
                        3'd0: tile_row_bits = 8'b01110111;
                        3'd1: tile_row_bits = 8'b01110111;
                        3'd2: tile_row_bits = 8'b01110000;
                        3'd3: tile_row_bits = 8'b01110111;
                        3'd4: tile_row_bits = 8'b01110111;
                        3'd5: tile_row_bits = 8'b00000111;
                        3'd6: tile_row_bits = 8'b01110111;
                        default: tile_row_bits = 8'b01110111;
                    endcase
                end
                TILE_STAIR: begin
                    case (ry)
                        3'd0: tile_row_bits = 8'b00010001;
                        3'd1: tile_row_bits = 8'b11111111;
                        3'd2: tile_row_bits = 8'b00010001;
                        3'd3: tile_row_bits = 8'b00010001;
                        3'd4: tile_row_bits = 8'b00010001;
                        3'd5: tile_row_bits = 8'b11111111;
                        3'd6: tile_row_bits = 8'b00010001;
                        default: tile_row_bits = 8'b00000000;
                    endcase
                end
                TILE_PIPE: begin
                    tile_row_bits = 8'b00000010;
                end
                TILE_GOLD: begin
                    case (ry)
                        3'd2: tile_row_bits = 8'b00111100;
                        3'd3: tile_row_bits = 8'b01100110;
                        3'd4: tile_row_bits = 8'b00111100;
                        default: tile_row_bits = 8'b00000000;
                    endcase
                end
                TILE_WALL: begin
                    case (ry)
                        3'd7: tile_row_bits = 8'b00000000;
                        default: tile_row_bits = 8'b01111111;
                    endcase
                end
                default: tile_row_bits = 8'b00000000;
            endcase
        end
    endfunction

    function [7:0] player_row_bits;
        input [2:0] kind;
        input       phase;
        input [2:0] ry;
        begin
            case (kind)
                ANIM_FLYING: begin
                    if (!phase) begin
                        case (ry)
                            3'd0: player_row_bits = 8'h00;
                            3'd1: player_row_bits = 8'h04;
                            3'd2: player_row_bits = 8'h88;
                            3'd3: player_row_bits = 8'h4B;
                            3'd4: player_row_bits = 8'h3F;
                            3'd5: player_row_bits = 8'h48;
                            3'd6: player_row_bits = 8'h88;
                            default: player_row_bits = 8'h04;
                        endcase
                    end else begin
                        case (ry)
                            3'd0: player_row_bits = 8'h00;
                            3'd1: player_row_bits = 8'h10;
                            3'd2: player_row_bits = 8'h08;
                            3'd3: player_row_bits = 8'hCB;
                            3'd4: player_row_bits = 8'h3F;
                            3'd5: player_row_bits = 8'hC8;
                            3'd6: player_row_bits = 8'h08;
                            default: player_row_bits = 8'h10;
                        endcase
                    end
                end
                ANIM_LEFT: begin
                    if (!phase) begin
                        case (ry)
                            3'd0: player_row_bits = 8'h00;
                            3'd1: player_row_bits = 8'h10;
                            3'd2: player_row_bits = 8'h10;
                            3'd3: player_row_bits = 8'hCB;
                            3'd4: player_row_bits = 8'h3F;
                            3'd5: player_row_bits = 8'h48;
                            3'd6: player_row_bits = 8'h90;
                            default: player_row_bits = 8'h00;
                        endcase
                    end else begin
                        case (ry)
                            3'd0: player_row_bits = 8'h00;
                            3'd1: player_row_bits = 8'h00;
                            3'd2: player_row_bits = 8'h20;
                            3'd3: player_row_bits = 8'h1B;
                            3'd4: player_row_bits = 8'hFF;
                            3'd5: player_row_bits = 8'hD8;
                            default: player_row_bits = 8'h00;
                        endcase
                    end
                end
                ANIM_RIGHT: begin
                    if (!phase) begin
                        case (ry)
                            3'd0: player_row_bits = 8'h00;
                            3'd1: player_row_bits = 8'h90;
                            3'd2: player_row_bits = 8'h48;
                            3'd3: player_row_bits = 8'h3F;
                            3'd4: player_row_bits = 8'hCB;
                            3'd5: player_row_bits = 8'h10;
                            3'd6: player_row_bits = 8'h10;
                            default: player_row_bits = 8'h00;
                        endcase
                    end else begin
                        case (ry)
                            3'd0: player_row_bits = 8'h00;
                            3'd1: player_row_bits = 8'h00;
                            3'd2: player_row_bits = 8'hD8;
                            3'd3: player_row_bits = 8'hFF;
                            3'd4: player_row_bits = 8'h1B;
                            3'd5: player_row_bits = 8'h20;
                            default: player_row_bits = 8'h00;
                        endcase
                    end
                end
                default: begin
                    if (!phase) begin
                        case (ry)
                            3'd0: player_row_bits = 8'h00;
                            3'd1: player_row_bits = 8'h00;
                            3'd2: player_row_bits = 8'h90;
                            3'd3: player_row_bits = 8'h4B;
                            3'd4: player_row_bits = 8'h3F;
                            3'd5: player_row_bits = 8'h28;
                            3'd6: player_row_bits = 8'h66;
                            default: player_row_bits = 8'h00;
                        endcase
                    end else begin
                        case (ry)
                            3'd0: player_row_bits = 8'h00;
                            3'd1: player_row_bits = 8'h00;
                            3'd2: player_row_bits = 8'h66;
                            3'd3: player_row_bits = 8'h2B;
                            3'd4: player_row_bits = 8'h3F;
                            3'd5: player_row_bits = 8'h48;
                            3'd6: player_row_bits = 8'h90;
                            default: player_row_bits = 8'h00;
                        endcase
                    end
                end
            endcase
        end
    endfunction

    function pixel_on;
        input [4:0] x;
        input [4:0] y;
        reg [2:0] t;
        reg [2:0] lx;
        reg [2:0] ly;
        reg [7:0] bg_row;
        reg [7:0] pl_row;
        reg bg_bit;
        reg pl_bit;
        begin
            t = map_value_at(x, y);
            lx = x[2:0];
            ly = y[2:0];
            bg_row = tile_row_bits(t, ly);
            bg_bit = bg_row[7 - lx];

            pl_bit = 1'b0;
            if ((x >= player_x[4:0]) && (x < player_x[4:0] + 5'd8) &&
                (y >= player_y[4:0]) && (y < player_y[4:0] + 5'd8)) begin
                pl_row = player_row_bits(anim_kind, anim_phase, y - player_y[4:0]);
                pl_bit = pl_row[7 - (x - player_x[4:0])];
            end

            pixel_on = bg_bit | pl_bit;
        end
    endfunction

    integer i;
    reg [2:0] center_t, bottom_t, feet_t, left_t, right_t, hand_t;
    reg [4:0] center_x, center_y;

    always @(posedge clk) begin
        if (reset) begin
            // Simple compact level inspired by upstream layout.
            tile_map[0]  <= TILE_WALL;  tile_map[1]  <= TILE_GOLD;  tile_map[2]  <= TILE_PIPE;  tile_map[3]  <= TILE_WALL;
            tile_map[4]  <= TILE_WALL;  tile_map[5]  <= TILE_STAIR; tile_map[6]  <= TILE_EMPTY; tile_map[7]  <= TILE_WALL;
            tile_map[8]  <= TILE_WALL;  tile_map[9]  <= TILE_EMPTY; tile_map[10] <= TILE_GOLD;  tile_map[11] <= TILE_WALL;
            tile_map[12] <= TILE_BRICK; tile_map[13] <= TILE_BRICK; tile_map[14] <= TILE_BRICK; tile_map[15] <= TILE_BRICK;
            player_x <= 6'd8;
            player_y <= 6'd8;
            anim_kind <= ANIM_RIGHT;
            anim_phase <= 1'b0;
            tick_cnt <= 24'd0;
            score <= 4'd0;
            game_clear <= 1'b0;
        end else begin
            if (tick_cnt == TICK_DIV - 1) begin
                tick_cnt <= 24'd0;

                center_x = sat5($signed({1'b0,player_x}) + 7'sd4);
                center_y = sat5($signed({1'b0,player_y}) + 7'sd4);
                center_t = map_value_at(center_x, center_y);
                bottom_t = map_value_at(center_x, sat5($signed({1'b0,player_y}) + 7'sd7));
                feet_t   = map_value_at(center_x, sat5($signed({1'b0,player_y}) + 7'sd8));
                hand_t   = map_value_at(center_x, player_y[4:0]);
                left_t   = map_value_at(sat5($signed({1'b0,player_x}) - 7'sd1), center_y);
                right_t  = map_value_at(sat5($signed({1'b0,player_x}) + 7'sd8), center_y);

                if (!is_solid(feet_t) && !(is_pipe(hand_t) && is_pipe(bottom_t))) begin
                    if (player_y < 6'd24) player_y <= player_y + 1'b1;
                    anim_kind <= ANIM_FLYING;
                end else if (btn_right && is_walkable(right_t)) begin
                    if (player_x < 6'd24) player_x <= player_x + 1'b1;
                    anim_kind <= is_pipe(center_t) ? ANIM_RPIPE : ANIM_RIGHT;
                    anim_phase <= ~anim_phase;
                end else if (btn_left && is_walkable(left_t)) begin
                    if (player_x > 0) player_x <= player_x - 1'b1;
                    anim_kind <= is_pipe(center_t) ? ANIM_LPIPE : ANIM_LEFT;
                    anim_phase <= ~anim_phase;
                end else if (btn_up && (is_stair(bottom_t) || is_stair(center_t))) begin
                    if (player_y > 0) player_y <= player_y - 1'b1;
                    anim_kind <= ANIM_UPDOWN;
                    anim_phase <= ~anim_phase;
                end else if (btn_down && (is_stair(feet_t) || (!is_solid(feet_t) && is_pipe(hand_t)))) begin
                    if (player_y < 6'd24) player_y <= player_y + 1'b1;
                    anim_kind <= ANIM_UPDOWN;
                    anim_phase <= ~anim_phase;
                end

                center_x = sat5($signed({1'b0,player_x}) + 7'sd4);
                center_y = sat5($signed({1'b0,player_y}) + 7'sd4);
                if (map_value_at(center_x, center_y) == TILE_GOLD) begin
                    tile_map[tile_index_xy(tile_x_of(center_x), tile_y_of(center_y))] <= TILE_EMPTY;
                    if (score != 4'hF) score <= score + 1'b1;
                end

                game_clear <= 1'b1;
                for (i = 0; i < 16; i = i + 1) begin
                    if (tile_map[i] == TILE_GOLD) game_clear <= 1'b0;
                end
            end else begin
                tick_cnt <= tick_cnt + 1'b1;
            end
        end
    end

    integer b;
    reg [1:0] page;
    reg [4:0] col;
    reg [7:0] byte_v;
    always @(*) begin
        page = rd_addr[6:5];
        col  = rd_addr[4:0];
        byte_v = 8'h00;
        for (b = 0; b < 8; b = b + 1) begin
            byte_v[b] = pixel_on(col, {page, 3'b000} + b[2:0]);
        end

        // Flash border once game is clear.
        if (game_clear && (col == 0 || col == 31 || page == 0 || page == 3)) begin
            rd_data = byte_v ^ 8'hFF;
        end else begin
            rd_data = byte_v;
        end
    end
endmodule
