`timescale 1ns / 1ps

module lode_runner_game (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_60hz,
    input  wire        btn_up,
    input  wire        btn_down,
    input  wire        btn_left,
    input  wire        btn_right,
    input  wire [9:0]  rd_addr,
    output reg  [7:0]  rd_data,
    output reg  [7:0]  score,
    output reg         game_over,
    output reg         game_win
);
    localparam MAP_W = 24;
    localparam MAP_H = 14;
    localparam MAP_SZ = MAP_W * MAP_H;
    localparam WORLD_W = 192;
    localparam WORLD_H = 112;

    reg [2:0] map      [0:MAP_SZ-1];
    reg [2:0] map_init [0:MAP_SZ-1];

    reg [7:0] player_x;
    reg [7:0] player_y;
    reg [7:0] enemy_x;
    reg [7:0] enemy_y;
    reg       anim_phase;

    integer i;

    initial begin
        $readmemh("lode_runner_map.mem", map_init);
        for (i = 0; i < MAP_SZ; i = i + 1) begin
            map[i] = map_init[i];
        end
    end

    function [8:0] map_index;
        input [4:0] bx;
        input [4:0] by;
        begin
            map_index = (by * MAP_W) + bx;
        end
    endfunction

    function [2:0] map_get_block;
        input [4:0] bx;
        input [4:0] by;
        reg [8:0] idx;
        begin
            if ((bx >= MAP_W) || (by >= MAP_H)) begin
                map_get_block = 3'd5;
            end else begin
                idx = map_index(bx, by);
                map_get_block = map[idx];
            end
        end
    endfunction

    function [2:0] block_at_xy;
        input [7:0] px;
        input [7:0] py;
        begin
            block_at_xy = map_get_block(px[7:3], py[7:3]);
        end
    endfunction

    function is_walkable;
        input [2:0] b;
        begin
            is_walkable = (b == 3'd0) || (b == 3'd2) || (b == 3'd3) || (b == 3'd4);
        end
    endfunction

    function is_solid;
        input [2:0] b;
        begin
            is_solid = (b == 3'd1) || (b == 3'd2) || (b == 3'd5);
        end
    endfunction

    function is_pipe;
        input [2:0] b;
        begin
            is_pipe = (b == 3'd3);
        end
    endfunction

    function is_stair;
        input [2:0] b;
        begin
            is_stair = (b == 3'd2);
        end
    endfunction

    function is_gold;
        input [2:0] b;
        begin
            is_gold = (b == 3'd4);
        end
    endfunction

    function [7:0] clamp_u8;
        input signed [9:0] val;
        input [7:0] lo;
        input [7:0] hi;
        begin
            if (val < $signed({2'b00, lo})) begin
                clamp_u8 = lo;
            end else if (val > $signed({2'b00, hi})) begin
                clamp_u8 = hi;
            end else begin
                clamp_u8 = val[7:0];
            end
        end
    endfunction

    function tile_pixel_on;
        input [2:0] tile;
        input [2:0] lx;
        input [2:0] ly;
        reg checker;
        begin
            checker = lx[0] ^ ly[0];
            case (tile)
                3'd0: tile_pixel_on = 1'b0;
                3'd1: tile_pixel_on = (ly == 3'd0) || (ly == 3'd7) || checker;
                3'd2: tile_pixel_on = (lx == 3'd3) || (lx == 3'd4) || (ly[1:0] == 2'b00);
                3'd3: tile_pixel_on = (ly == 3'd3) || (ly == 3'd4);
                3'd4: tile_pixel_on = ((lx >= 3'd2) && (lx <= 3'd5) && (ly >= 3'd2) && (ly <= 3'd5)) &&
                                       !((lx == 3'd2 || lx == 3'd5) && (ly == 3'd2 || ly == 3'd5));
                3'd5: tile_pixel_on = 1'b1;
                default: tile_pixel_on = 1'b0;
            endcase
        end
    endfunction

    function player_pixel_on;
        input [2:0] sx;
        input [2:0] sy;
        input       anim;
        begin
            player_pixel_on = 1'b0;
            if ((sy == 3'd0) && (sx >= 3'd2) && (sx <= 3'd5)) player_pixel_on = 1'b1;
            if ((sy >= 3'd1) && (sy <= 3'd4) && (sx == 3'd3 || sx == 3'd4)) player_pixel_on = 1'b1;
            if ((sy == 3'd2) && (sx >= 3'd1) && (sx <= 3'd6)) player_pixel_on = 1'b1;
            if (anim) begin
                if ((sy == 3'd6) && (sx == 3'd2 || sx == 3'd5)) player_pixel_on = 1'b1;
                if ((sy == 3'd7) && (sx == 3'd1 || sx == 3'd6)) player_pixel_on = 1'b1;
            end else begin
                if ((sy == 3'd6) && (sx == 3'd1 || sx == 3'd6)) player_pixel_on = 1'b1;
                if ((sy == 3'd7) && (sx == 3'd2 || sx == 3'd5)) player_pixel_on = 1'b1;
            end
        end
    endfunction

    function enemy_pixel_on;
        input [2:0] sx;
        input [2:0] sy;
        begin
            enemy_pixel_on = 1'b0;
            if ((sx == sy) || (sx + sy == 3'd7)) enemy_pixel_on = 1'b1;
            if ((sy >= 3'd2) && (sy <= 3'd5) && (sx >= 3'd2) && (sx <= 3'd5)) enemy_pixel_on = 1'b1;
        end
    endfunction

    reg [2:0] pb, pf, ph, pc, pr, pl;
    reg [2:0] eb, ef, eh, ec, er, el;
    reg [8:0] center_idx;
    reg [7:0] next_px, next_py, next_ex, next_ey;
    reg [7:0] viewport_x;
    reg [7:0] viewport_y;
    reg [2:0] wlx;
    reg [2:0] wly;
    reg [4:0] tile_x;
    reg [4:0] tile_y;
    reg [2:0] tile;
    reg [7:0] xpix;
    reg [7:0] ypix;
    reg [7:0] world_x;
    reg [7:0] world_y;
    reg pixel_on;
    integer bit_idx;

    always @(posedge clk) begin
        if (rst) begin
            player_x <= 8'd8;
            player_y <= 8'd8;
            enemy_x <= 8'd72;
            enemy_y <= 8'd8;
            anim_phase <= 1'b0;
            score <= 8'd0;
            game_over <= 1'b0;
            game_win <= 1'b0;
            for (i = 0; i < MAP_SZ; i = i + 1) begin
                map[i] <= map_init[i];
            end
        end else if (tick_60hz) begin
            next_px = player_x;
            next_py = player_y;
            next_ex = enemy_x;
            next_ey = enemy_y;

            pb = block_at_xy(player_x + 8'd4, player_y + 8'd7);
            pf = block_at_xy(player_x + 8'd4, player_y + 8'd8);
            ph = block_at_xy(player_x + 8'd4, player_y);
            pc = block_at_xy(player_x + 8'd4, player_y + 8'd4);
            pr = block_at_xy(player_x + 8'd8, player_y + 8'd4);
            pl = block_at_xy(player_x - 8'd1, player_y + 8'd4);

            if (!is_solid(pf) && !(is_pipe(ph) && is_pipe(pb))) begin
                next_px = {player_x[7:3], 3'b000};
                if (player_y < (WORLD_H - 8)) begin
                    next_py = player_y + 8'd1;
                end
            end else begin
                if (btn_right && is_walkable(pr) && (player_x < (WORLD_W - 8))) begin
                    next_px = player_x + 8'd1;
                end else if (btn_left && is_walkable(pl) && (player_x > 0)) begin
                    next_px = player_x - 8'd1;
                end else if (btn_up && (is_stair(pb) || is_stair(pc)) && (player_y > 0)) begin
                    next_px = {player_x[7:3], 3'b000};
                    next_py = player_y - 8'd1;
                end else if (btn_down && (is_pipe(pb) || is_walkable(pf)) && (player_y < (WORLD_H - 8))) begin
                    next_px = {player_x[7:3], 3'b000};
                    next_py = player_y + 8'd1;
                end
            end

            player_x <= next_px;
            player_y <= next_py;

            center_idx = map_index((next_px + 8'd4) >> 3, (next_py + 8'd4) >> 3);
            if (is_gold(map[center_idx])) begin
                map[center_idx] <= 3'd0;
                score <= score + 8'd1;
            end

            eb = block_at_xy(enemy_x + 8'd4, enemy_y + 8'd7);
            ef = block_at_xy(enemy_x + 8'd4, enemy_y + 8'd8);
            eh = block_at_xy(enemy_x + 8'd4, enemy_y);
            ec = block_at_xy(enemy_x + 8'd4, enemy_y + 8'd4);
            er = block_at_xy(enemy_x + 8'd8, enemy_y + 8'd4);
            el = block_at_xy(enemy_x - 8'd1, enemy_y + 8'd4);

            if (!is_solid(ef) && !(is_pipe(eh) && is_pipe(eb))) begin
                next_ex = {enemy_x[7:3], 3'b000};
                if (enemy_y < (WORLD_H - 8)) begin
                    next_ey = enemy_y + 8'd1;
                end
            end else begin
                if ((enemy_y > next_py) && (is_stair(ec) || is_stair(eb)) && (enemy_y > 0)) begin
                    next_ex = {enemy_x[7:3], 3'b000};
                    next_ey = enemy_y - 8'd1;
                end else if ((enemy_y < next_py) && (is_pipe(eb) || is_walkable(ef)) && (enemy_y < (WORLD_H - 8))) begin
                    next_ex = {enemy_x[7:3], 3'b000};
                    next_ey = enemy_y + 8'd1;
                end else if ((enemy_x < next_px) && is_walkable(er) && (enemy_x < (WORLD_W - 8))) begin
                    next_ex = enemy_x + 8'd1;
                end else if ((enemy_x > next_px) && is_walkable(el) && (enemy_x > 0)) begin
                    next_ex = enemy_x - 8'd1;
                end
            end

            enemy_x <= next_ex;
            enemy_y <= next_ey;

            if (((next_ex + 8'd7) >= next_px) && ((next_px + 8'd7) >= next_ex) &&
                ((next_ey + 8'd7) >= next_py) && ((next_py + 8'd7) >= next_ey)) begin
                game_over <= 1'b1;
            end

            if (score >= 8'd11) begin
                game_win <= 1'b1;
            end

            anim_phase <= ~anim_phase;
        end
    end

    always @(*) begin
        viewport_x = clamp_u8($signed({2'b00, player_x}) - 10'sd60, 8'd0, 8'd64);
        viewport_y = clamp_u8($signed({2'b00, player_y}) - 10'sd28, 8'd0, 8'd48);

        xpix = rd_addr[6:0];
        rd_data = 8'h00;
        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            ypix = {rd_addr[9:7], 3'b000} + bit_idx[7:0];
            world_x = viewport_x + xpix;
            world_y = viewport_y + ypix;

            tile_x = world_x[7:3];
            tile_y = world_y[7:3];
            wlx = world_x[2:0];
            wly = world_y[2:0];
            tile = map_get_block(tile_x, tile_y);

            pixel_on = tile_pixel_on(tile, wlx, wly);

            if ((world_x >= player_x) && (world_x < player_x + 8) &&
                (world_y >= player_y) && (world_y < player_y + 8)) begin
                pixel_on = pixel_on | player_pixel_on(world_x - player_x, world_y - player_y, anim_phase);
            end

            if ((world_x >= enemy_x) && (world_x < enemy_x + 8) &&
                (world_y >= enemy_y) && (world_y < enemy_y + 8)) begin
                pixel_on = pixel_on | enemy_pixel_on(world_x - enemy_x, world_y - enemy_y);
            end

            if (game_over) begin
                if ((xpix > 7'd40) && (xpix < 7'd88) && (ypix > 7'd24) && (ypix < 7'd40)) begin
                    pixel_on = 1'b1;
                end
            end

            if (game_win) begin
                if (((xpix + ypix) & 8'h07) == 8'h00) begin
                    pixel_on = 1'b1;
                end
            end

            rd_data[bit_idx] = pixel_on;
        end
    end
endmodule
