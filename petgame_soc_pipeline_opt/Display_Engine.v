module Display_Engine (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cmd_data,    // [15:8]=PetID, [7:0]=ExpID
    input  wire        we,          // 来自 0x9000 写操作的使能脉冲
    output reg         busy,
    output reg         sclk,
    output reg         mosi,
    output reg         dc,
    output reg         cs
);
    // SPI 分频：若主时钟为 100MHz，SCLK_DIV=50 时 SCLK 约为 1MHz。
    localparam integer SCLK_DIV = 50;

    // 主状态机：上电初始化 -> 空闲等待命令 -> 分页取像素并发送 -> 回空闲
    localparam [4:0] ST_BOOT             = 5'd0;
    localparam [4:0] ST_INIT_NEXT        = 5'd1;
    localparam [4:0] ST_IDLE             = 5'd2;
    localparam [4:0] ST_PAGE_CMD0        = 5'd3;
    localparam [4:0] ST_PAGE_CMD1        = 5'd4;
    localparam [4:0] ST_PAGE_CMD2        = 5'd5;
    localparam [4:0] ST_DATA_REQ         = 5'd6;
    localparam [4:0] ST_DATA_WAIT        = 5'd7;
    localparam [4:0] ST_DATA_SAMPLE      = 5'd8;
    localparam [4:0] ST_DATA_SEND        = 5'd9;
    localparam [4:0] ST_DATA_NEXT        = 5'd10;
    localparam [4:0] ST_TX_SETUP         = 5'd11;
    localparam [4:0] ST_TX_HIGH          = 5'd12;
    localparam [4:0] ST_TX_LOW           = 5'd13;

    localparam [4:0] INIT_LAST = 5'd24; // 共 25 个初始化字节，索引 0..24

    reg [4:0] state;
    reg [4:0] next_state;

    reg [4:0] init_idx;

    reg [1:0] page;        // 页号 0..3（32 行 = 4 页，每页 8 行）
    reg [5:0] col;         // 列号 0..31
    reg [2:0] bit_row;     // 页内 bit 行号 0..7
    reg [7:0] frame_byte;  // 即将发给 OLED 的 1 字节页面数据

    reg [17:0] start_addr; // 当前贴图在 ROM 的起始地址：(PetID*5 + ExpID) * 1024
    reg [17:0] rom_addr;   // 送给 Picture_ROM 的读地址

    // SPI 发 1 字节的工作寄存器
    reg [7:0] tx_byte;
    reg       tx_dc;
    reg [2:0] tx_bit;
    reg [7:0] div_cnt;

    // 对非法 Pet/Exp 编号做钳位，避免越界访问图片 ROM。
    wire [2:0] cmd_pet = (cmd_data[15:8] < 8'd5) ? cmd_data[10:8] : 3'd0;
    wire [2:0] cmd_exp = (cmd_data[7:0]  < 8'd5) ? cmd_data[2:0]  : 3'd0;
    wire [17:0] cmd_start_addr =
        (({15'd0, cmd_pet} * 18'd5) + {15'd0, cmd_exp}) << 10;

    // 将 (page,col,bit_row) 映射到 32x32 图块中的像素索引。
    wire [5:0] y_in_tile = {page, 3'b000} + bit_row;
    wire [9:0] pixel_idx = ({4'd0, y_in_tile} << 5) + {4'd0, col};

    wire [15:0] current_pixel;
    Picture_ROM rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .dout(current_pixel)
    );

    // SSD1306 初始化命令表。
    function [7:0] init_cmd;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  init_cmd = 8'hAE; // 关闭显示
                5'd1:  init_cmd = 8'hD5; // 设置显示时钟分频
                5'd2:  init_cmd = 8'h80;
                5'd3:  init_cmd = 8'hA8; // 设置复用率
                5'd4:  init_cmd = 8'h3F;
                5'd5:  init_cmd = 8'hD3; // 设置显示偏移
                5'd6:  init_cmd = 8'h00;
                5'd7:  init_cmd = 8'h40; // 起始行
                5'd8:  init_cmd = 8'h8D; // 电荷泵配置
                5'd9:  init_cmd = 8'h14;
                5'd10: init_cmd = 8'h20; // 内存寻址模式
                5'd11: init_cmd = 8'h00; // 水平寻址
                5'd12: init_cmd = 8'hA1; // 段重映射
                5'd13: init_cmd = 8'hC8; // COM 扫描方向
                5'd14: init_cmd = 8'hDA; // COM 引脚配置
                5'd15: init_cmd = 8'h12;
                5'd16: init_cmd = 8'h81; // 对比度
                5'd17: init_cmd = 8'hCF;
                5'd18: init_cmd = 8'hD9; // 预充电周期
                5'd19: init_cmd = 8'hF1;
                5'd20: init_cmd = 8'hDB; // VCOMH 电平
                5'd21: init_cmd = 8'h40;
                5'd22: init_cmd = 8'hA4; // RAM 内容决定显示
                5'd23: init_cmd = 8'hA6; // 正常显示（非反色）
                5'd24: init_cmd = 8'hAF; // 开启显示
                default: init_cmd = 8'hAE;
            endcase
        end
    endfunction

    // RGB565 转单色：使用简化亮度阈值（适配 SSD1306 1bit 像素）。
    function pixel_to_mono;
        input [15:0] rgb565;
        reg [6:0] lum_approx;
        begin
            lum_approx = {2'b00, rgb565[15:11]} + {1'b0, rgb565[10:5]} + {2'b00, rgb565[4:0]};
            pixel_to_mono = (lum_approx >= 7'd24);
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state      <= ST_BOOT;
            next_state <= ST_BOOT;
            init_idx   <= 5'd0;
            page       <= 2'd0;
            col        <= 6'd0;
            bit_row    <= 3'd0;
            frame_byte <= 8'd0;
            start_addr <= 0;
            rom_addr   <= 0;
            tx_byte    <= 8'd0;
            tx_dc      <= 1'b0;
            tx_bit     <= 3'd0;
            div_cnt    <= 8'd0;
            busy       <= 1'b1; // 初始化期间保持忙碌
            sclk       <= 1'b0;
            mosi       <= 1'b0;
            dc         <= 1'b0;
            cs         <= 1'b1;
        end else begin
            case (state)
                ST_BOOT: begin
                    // 复位后先发送第一条初始化命令，后续在 ST_INIT_NEXT 继续发送。
                    busy       <= 1'b1;
                    tx_byte    <= init_cmd(5'd0);
                    tx_dc      <= 1'b0;
                    next_state <= ST_INIT_NEXT;
                    state      <= ST_TX_SETUP;
                end

                ST_INIT_NEXT: begin
                    busy <= 1'b1;
                    if (init_idx == INIT_LAST) begin
                        busy    <= 1'b0;
                        init_idx <= 5'd0;
                        state   <= ST_IDLE;
                    end else begin
                        init_idx   <= init_idx + 1'b1;
                        tx_byte    <= init_cmd(init_idx + 1'b1);
                        tx_dc      <= 1'b0;
                        next_state <= ST_INIT_NEXT;
                        state      <= ST_TX_SETUP;
                    end
                end

                ST_IDLE: begin
                    // 空闲：等待 CPU 写入 display 命令。
                    busy <= 1'b0;
                    cs   <= 1'b1;
                    sclk <= 1'b0;
                    if (we) begin
                        start_addr <= cmd_start_addr;
                        page       <= 2'd0;
                        col        <= 6'd0;
                        bit_row    <= 3'd0;
                        frame_byte <= 8'd0;
                        busy       <= 1'b1;
                        state      <= ST_PAGE_CMD0;
                    end
                end

                ST_PAGE_CMD0: begin
                    tx_byte    <= (8'hB0 + {6'd0, page}); // 设定页地址
                    tx_dc      <= 1'b0;
                    next_state <= ST_PAGE_CMD1;
                    state      <= ST_TX_SETUP;
                end

                ST_PAGE_CMD1: begin
                    tx_byte    <= 8'h00; // 列地址低位起始
                    tx_dc      <= 1'b0;
                    next_state <= ST_PAGE_CMD2;
                    state      <= ST_TX_SETUP;
                end

                ST_PAGE_CMD2: begin
                    tx_byte    <= 8'h10; // 列地址高位起始
                    tx_dc      <= 1'b0;
                    next_state <= ST_DATA_REQ;
                    state      <= ST_TX_SETUP;
                end

                ST_DATA_REQ: begin
                    // 发起一次 ROM 读请求。
                    rom_addr <= start_addr + {8'd0, pixel_idx};
                    state    <= ST_DATA_WAIT;
                end

                ST_DATA_WAIT: begin
                    // Picture_ROM 为同步读，这里等待 1 个周期。
                    state <= ST_DATA_SAMPLE;
                end

                ST_DATA_SAMPLE: begin
                    // 把一个像素转换后写入 frame_byte 对应 bit。
                    frame_byte[bit_row] <= pixel_to_mono(current_pixel);
                    if (bit_row == 3'd7) begin
                        state <= ST_DATA_SEND;
                    end else begin
                        bit_row <= bit_row + 1'b1;
                        state   <= ST_DATA_REQ;
                    end
                end

                ST_DATA_SEND: begin
                    // 每累计 8 个像素（竖向）发送 1 字节数据。
                    tx_byte    <= frame_byte;
                    tx_dc      <= 1'b1;
                    next_state <= ST_DATA_NEXT;
                    state      <= ST_TX_SETUP;
                end

                ST_DATA_NEXT: begin
                    // 更新列/页计数，决定继续发送还是结束一帧。
                    if (col == 6'd31) begin
                        col     <= 6'd0;
                        bit_row <= 3'd0;
                        if (page == 2'd3) begin
                            busy  <= 1'b0;
                            state <= ST_IDLE;
                        end else begin
                            page  <= page + 1'b1;
                            state <= ST_PAGE_CMD0;
                        end
                    end else begin
                        col        <= col + 1'b1;
                        bit_row    <= 3'd0;
                        frame_byte <= 8'd0;
                        state      <= ST_DATA_REQ;
                    end
                end

                ST_TX_SETUP: begin
                    // SPI 发字节准备：拉低 CS，装载首位，SCLK 置低。
                    cs      <= 1'b0;
                    dc      <= tx_dc;
                    sclk    <= 1'b0;
                    tx_bit  <= 3'd7;
                    mosi    <= tx_byte[7];
                    div_cnt <= 8'd0;
                    state   <= ST_TX_HIGH;
                end

                ST_TX_HIGH: begin
                    // 分频计数到点后把 SCLK 拉高。
                    if (div_cnt == (SCLK_DIV - 1)) begin
                        div_cnt <= 8'd0;
                        sclk    <= 1'b1;
                        state   <= ST_TX_LOW;
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                ST_TX_LOW: begin
                    // 分频计数到点后把 SCLK 拉低，并切换到下一位/下一状态。
                    if (div_cnt == (SCLK_DIV - 1)) begin
                        div_cnt <= 8'd0;
                        sclk    <= 1'b0;
                        if (tx_bit == 3'd0) begin
                            cs    <= 1'b1;
                            state <= next_state;
                        end else begin
                            tx_bit <= tx_bit - 1'b1;
                            mosi   <= tx_byte[tx_bit - 1'b1];
                            state  <= ST_TX_HIGH;
                        end
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
