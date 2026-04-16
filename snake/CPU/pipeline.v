`timescale 1ns / 1ps

module pipeline (
    input  clk,
    input  rst,
    // --- 新增的 I/O 腳位 ---
    input  [3:0] btns,
    input  sw0,
    output [6:0] vram_disp_addr,
    input  [7:0] vram_disp_data
);
    // IF/ID outputs
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;
    // Instruction memory wires (internal)
    wire [31:0] instr_addr;
    wire [31:0] instr_data;
//branch
    wire id_predict_take;
    wire [31:0] id_branch_target;
    wire miss;
//
    // ID/EX data outputs (already registered inside ID)
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_imm;
    wire [4:0]  id_ex_rd;
    wire [31:0] id_ex_instr;

    // ID control outputs (combinational)
    wire [3:0] id_alu_op;
    wire       id_alu_src;
    wire       id_alu_src1;
    wire       id_reg_write;
    wire       id_mem_read;
    wire       id_mem_write;
    wire       id_mem_reg;
    wire       id_branch;
    wire       id_jump;
    wire       id_jalr_enable;

    // ID/EX control registers
    reg  [3:0] ex_alu_op;
    reg        ex_alu_src;
    reg        ex_alu_src1;
    reg        ex_reg_write;
    reg        ex_mem_read;
    reg        ex_mem_write;
    reg        ex_mem_reg;
    reg        ex_branch;
    reg        ex_jump;
    reg        ex_jalr_enable;
//
    reg ex_predicted_take;
//
    // EX outputs (combinational)
    wire [31:0] ex_alu_result;
    wire [31:0] ex_rs2_data;
    wire [4:0]  ex_rd;
    wire        ex_reg_write_out;
    wire        ex_mem_read_out;
    wire        ex_mem_write_out;
    wire        ex_mem_reg_out;
    wire [31:0] ex_mem_instruction;
    wire        ex_zero;
    wire        ex_take;
    wire [2:0]  ex_funct3;
    reg         ex_take_branch;
    wire [31:0] ex_pc_plus4;
    wire        hazard_stall;
    wire        mem_stall;
    wire        pipeline_stall;
    reg         mem_wait;
    wire [31:0] mem_forward_data;
    wire [31:0] mem_rs2_data;
    wire [1:0]  forwardA;
    wire [1:0]  forwardB;
    wire        mem_forward_from_wb;

    // Forwarding wires (to EX)
    wire [31:0] fwd_rs1_data;
    wire [31:0] fwd_rs2_data;
    wire [4:0]  ex_rs1_addr;
    wire [4:0]  ex_rs2_addr;

    // EX/MEM pipeline registers
    reg  [31:0] ex_mem_alu_result_reg;
    reg  [31:0] ex_mem_rs2_data_reg;
    reg  [4:0]  ex_mem_rd_reg;
    reg         ex_mem_reg_write_reg;
    reg         ex_mem_read_reg;
    reg         ex_mem_write_reg;
    reg         ex_mem_reg_reg;
    reg  [31:0] ex_mem_instruction_reg;
    reg  [31:0] ex_mem_pc_plus4_reg;
    reg         ex_mem_jump_reg;

    // MEM outputs (combinational)
    wire [31:0] mem_data;
    wire [31:0] mem_alu_result;
    wire [4:0]  mem_rd;
    wire        mem_reg_write;
    wire        mem_regout;

    // MEM/WB pipeline registers
    reg  [31:0] mem_wb_data_reg;
    reg  [31:0] mem_wb_alu_result_reg;
    reg  [4:0]  mem_wb_rd_reg;
    reg         mem_wb_reg_write_reg;
    reg         mem_wb_mem_reg_reg;
    reg  [31:0] mem_wb_pc_plus4_reg;
    reg         mem_wb_jump_reg;

    // WB outputs
    wire [31:0] wb_data;
    wire [4:0]  wb_rd;
    wire        wb_regwrite;

//
    assign miss = (ex_take != ex_predicted_take);
//
    // IF stage
    IF u_IF (
        .clk         (clk),
        .rst         (rst),
        .flush       (miss),//
        .stall       (pipeline_stall),
        .jump        (ex_jump),
        .jalr_enable (ex_jalr_enable),
        .branch      (ex_branch),
        .zero        (ex_zero),
        .rs1_data    (fwd_rs1_data),
        .imm         (id_ex_imm),
        .funct3      (ex_funct3),
        .alu_result  (ex_alu_result),
        .branch_pc   (id_ex_pc),
        .instr_addr  (instr_addr),
        .instr_data  (instr_data),
        .if_id_pc    (if_id_pc),
        .if_id_instr (if_id_instr),
        //
        .predicted_take(id_predict_take),
        .predicted_pc(id_branch_target),
        .actual_take(ex_take)
    );

    // Instruction Memory (combinational ROM)
    inst_mem instruction_memory (
        .pc_address  (instr_addr),
        .instruction (instr_data)
    );

    // Forwarding logic (EX stage operands)
    assign ex_rs1_addr = id_ex_instr[19:15];
    assign ex_rs2_addr = id_ex_instr[24:20];

    // Forward from MEM stage (use load data when mem_read)
    assign mem_forward_data = ex_mem_read_reg ? mem_data : ex_mem_alu_result_reg;

    // Forwarding unit
    forwarding_unit u_forwarding (
        .ex_mem_regwrite  (ex_mem_reg_write_reg),
        .ex_mem_rd        (ex_mem_rd_reg),
        .mem_wb_regwrite  (mem_wb_reg_write_reg),
        .mem_wb_rd        (mem_wb_rd_reg),
        .id_ex_rs1        (ex_rs1_addr),
        .id_ex_rs2        (ex_rs2_addr),
        .ex_mem_rs2       (ex_mem_instruction_reg[24:20]),
        .forwardA         (forwardA),
        .forwardB         (forwardB),
        .mem_forward_from_wb(mem_forward_from_wb)
    );

    assign fwd_rs1_data =
        (forwardA == 2'b10) ? mem_forward_data :
        (forwardA == 2'b01) ? wb_data :
        id_ex_rs1_data;

    assign fwd_rs2_data =
        (forwardB == 2'b10) ? mem_forward_data :
        (forwardB == 2'b01) ? wb_data :
        id_ex_rs2_data;

    // ID stage (includes IF/ID -> ID/EX data regs)
    ID u_ID (
        .clk          (clk),
        .rst          (rst),
        .flush        (miss),//static prediction
        .stall        (pipeline_stall),
        .if_id_pc     (if_id_pc),
        .if_id_instr  (if_id_instr),
        .wb_regwrite  (wb_regwrite),
        .wb_rd        (wb_rd),
        .wb_data      (wb_data),
        .id_alu_op    (id_alu_op),
        .id_alu_src   (id_alu_src),
        .id_alu_src1  (id_alu_src1),
        .id_reg_write (id_reg_write),
        .id_mem_read  (id_mem_read),
        .id_mem_write (id_mem_write),
        .id_mem_reg   (id_mem_reg),
        .id_branch    (id_branch),
        .id_jump      (id_jump),
        .id_jalr_enable(id_jalr_enable),
        .id_ex_pc     (id_ex_pc),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm    (id_ex_imm),
        .id_ex_rd     (id_ex_rd),
        .id_ex_instr  (id_ex_instr),
        //
        .id_predicted_take(id_predict_take),
        .id_branch_target(id_branch_target)
    );

    // ID/EX control registers
    always @(posedge clk or posedge rst) begin
        if (rst || miss) begin
            ex_alu_op      <= 4'b0000;
            ex_alu_src     <= 1'b0;
            ex_alu_src1    <= 1'b0;
            ex_reg_write   <= 1'b0;
            ex_mem_read    <= 1'b0;
            ex_mem_write   <= 1'b0;
            ex_mem_reg     <= 1'b0;
            ex_branch      <= 1'b0;
            ex_jump        <= 1'b0;
            ex_jalr_enable <= 1'b0;
            ex_predicted_take <= 1'b0;
        end else if (mem_stall) begin
            ex_alu_op      <= ex_alu_op;
            ex_alu_src     <= ex_alu_src;
            ex_alu_src1    <= ex_alu_src1;
            ex_reg_write   <= ex_reg_write;
            ex_mem_read    <= ex_mem_read;
            ex_mem_write   <= ex_mem_write;
            ex_mem_reg     <= ex_mem_reg;
            ex_branch      <= ex_branch;
            ex_jump        <= ex_jump;
            ex_jalr_enable <= ex_jalr_enable;
            ex_predicted_take <= ex_predicted_take;
        end else if (hazard_stall) begin
            ex_alu_op      <= 4'b0000;
            ex_alu_src     <= 1'b0;
            ex_alu_src1    <= 1'b0;
            ex_reg_write   <= 1'b0;
            ex_mem_read    <= 1'b0;
            ex_mem_write   <= 1'b0;
            ex_mem_reg     <= 1'b0;
            ex_branch      <= 1'b0;
            ex_jump        <= 1'b0;
            ex_jalr_enable <= 1'b0;
            ex_predicted_take <= 1'b0;
        end else begin
            ex_alu_op      <= id_alu_op;
            ex_alu_src     <= id_alu_src;
            ex_alu_src1    <= id_alu_src1;
            ex_reg_write   <= id_reg_write;
            ex_mem_read    <= id_mem_read;
            ex_mem_write   <= id_mem_write;
            ex_mem_reg     <= id_mem_reg;
            ex_branch      <= id_branch;
            ex_jump        <= id_jump;
            ex_jalr_enable <= id_jalr_enable;
            ex_predicted_take <= id_predict_take;
        end
    end

    // EX stage
    EX u_EX (
        .clk          (clk),
        .rst          (rst),
        .pc           (id_ex_pc),
        .rs1_data     (fwd_rs1_data),
        .rs2_data     (fwd_rs2_data),
        .imm          (id_ex_imm),
        .rd           (id_ex_rd),
        .instruction  (id_ex_instr),
        .alu_op       (ex_alu_op),
        .alu_src      (ex_alu_src),
        .alu_src1     (ex_alu_src1),
        .reg_write    (ex_reg_write),
        .mem_read     (ex_mem_read),
        .mem_write    (ex_mem_write),
        .mem_reg      (ex_mem_reg),
        .ex_alu_result(ex_alu_result),
        .ex_rs2_data  (ex_rs2_data),
        .ex_rd        (ex_rd),
        .ex_reg_write (ex_reg_write_out),
        .ex_mem_read  (ex_mem_read_out),
        .ex_mem_write (ex_mem_write_out),
        .ex_mem_reg   (ex_mem_reg_out),
        .ex_mem_instruction(ex_mem_instruction)
    );

    assign ex_zero = (ex_alu_result == 32'b0);
    assign ex_funct3 = id_ex_instr[14:12];
    assign ex_pc_plus4 = id_ex_pc + 32'd4;

    always @(*) begin
        ex_take_branch = 1'b0;
        case (ex_funct3)
            3'b000: ex_take_branch = (fwd_rs1_data == fwd_rs2_data);                         // BEQ
            3'b001: ex_take_branch = (fwd_rs1_data != fwd_rs2_data);                         // BNE
            3'b100: ex_take_branch = ($signed(fwd_rs1_data) <  $signed(fwd_rs2_data));       // BLT
            3'b101: ex_take_branch = ($signed(fwd_rs1_data) >= $signed(fwd_rs2_data));       // BGE
            3'b110: ex_take_branch = (fwd_rs1_data <  fwd_rs2_data);                          // BLTU
            3'b111: ex_take_branch = (fwd_rs1_data >= fwd_rs2_data);                          // BGEU
            default: ex_take_branch = 1'b0;
        endcase
    end

    assign ex_take = ex_jump | ex_jalr_enable | (ex_branch & ex_take_branch);

    // Load-use hazard detection (stall IF/ID, bubble ID/EX control)
    hazard_unit u_hazard (
        .id_ex_memread  (ex_mem_read),
        .id_ex_rd       (id_ex_rd),
        .if_id_rs1      (if_id_instr[19:15]),
        .if_id_rs2      (if_id_instr[24:20]),
        .flush          (miss),//
        .stall          (hazard_stall)
    );

    // Data memory stall for synchronous BRAM read (1 extra cycle per load)
    assign mem_stall = ex_mem_read_reg && !mem_wait;
    assign pipeline_stall = hazard_stall | mem_stall;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wait <= 1'b0;
        end else if (mem_stall) begin
            mem_wait <= 1'b1;
        end else if (mem_wait) begin
            mem_wait <= 1'b0;
        end
    end

    // EX/MEM pipeline registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem_alu_result_reg <= 32'b0;
            ex_mem_rs2_data_reg   <= 32'b0;
            ex_mem_rd_reg         <= 5'b0;
            ex_mem_reg_write_reg  <= 1'b0;
            ex_mem_read_reg       <= 1'b0;
            ex_mem_write_reg      <= 1'b0;
            ex_mem_reg_reg        <= 1'b0;
            ex_mem_instruction_reg<= 32'b0;
            ex_mem_pc_plus4_reg   <= 32'b0;
            ex_mem_jump_reg       <= 1'b0;
        end else if (mem_stall) begin
            ex_mem_alu_result_reg <= ex_mem_alu_result_reg;
            ex_mem_rs2_data_reg   <= ex_mem_rs2_data_reg;
            ex_mem_rd_reg         <= ex_mem_rd_reg;
            ex_mem_reg_write_reg  <= ex_mem_reg_write_reg;
            ex_mem_read_reg       <= ex_mem_read_reg;
            ex_mem_write_reg      <= ex_mem_write_reg;
            ex_mem_reg_reg        <= ex_mem_reg_reg;
            ex_mem_instruction_reg<= ex_mem_instruction_reg;
            ex_mem_pc_plus4_reg   <= ex_mem_pc_plus4_reg;
            ex_mem_jump_reg       <= ex_mem_jump_reg;
        end else begin
            ex_mem_alu_result_reg <= ex_alu_result;
            ex_mem_rs2_data_reg   <= ex_rs2_data;
            ex_mem_rd_reg         <= ex_rd;
            ex_mem_reg_write_reg  <= ex_reg_write_out;
            ex_mem_read_reg       <= ex_mem_read_out;
            ex_mem_write_reg      <= ex_mem_write_out;
            ex_mem_reg_reg        <= ex_mem_reg_out;
            ex_mem_instruction_reg<= ex_mem_instruction;
            ex_mem_pc_plus4_reg   <= ex_pc_plus4;
            ex_mem_jump_reg       <= ex_jump;
        end
    end

    // MEM stage
    // Store-data forwarding in MEM stage (from WB)
    assign mem_rs2_data = mem_forward_from_wb ? wb_data : ex_mem_rs2_data_reg;

    MEM u_MEM (
        .clk            (clk),
        .rst            (rst),
        .alu_result     (ex_mem_alu_result_reg),
        .rs2_data       (mem_rs2_data),
        .rd             (ex_mem_rd_reg),
        .reg_write      (ex_mem_reg_write_reg),
        .mem_write      (ex_mem_write_reg),
        .mem_read       (ex_mem_read_reg),
        .mem_reg        (ex_mem_reg_reg),
        .ex_mem_instruction(ex_mem_instruction_reg),
        .mem_data       (mem_data),
        .mem_alu_result (mem_alu_result),
        .mem_rd         (mem_rd),
        .mem_reg_write  (mem_reg_write),
        .mem_regout     (mem_regout),
        // --- 新增的 I/O 接線傳遞給 MEM ---
        .btns           (btns),
        .sw0            (sw0),
        .vram_disp_addr (vram_disp_addr),
        .vram_disp_data (vram_disp_data)
    );

    // MEM/WB pipeline registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wb_data_reg      <= 32'b0;
            mem_wb_alu_result_reg<= 32'b0;
            mem_wb_rd_reg        <= 5'b0;
            mem_wb_reg_write_reg <= 1'b0;
            mem_wb_mem_reg_reg   <= 1'b0;
            mem_wb_pc_plus4_reg  <= 32'b0;
            mem_wb_jump_reg      <= 1'b0;
        end else if (mem_stall) begin
            mem_wb_data_reg      <= mem_wb_data_reg;
            mem_wb_alu_result_reg<= mem_wb_alu_result_reg;
            mem_wb_rd_reg        <= mem_wb_rd_reg;
            mem_wb_reg_write_reg <= mem_wb_reg_write_reg;
            mem_wb_mem_reg_reg   <= mem_wb_mem_reg_reg;
            mem_wb_pc_plus4_reg  <= mem_wb_pc_plus4_reg;
            mem_wb_jump_reg      <= mem_wb_jump_reg;
        end else begin
            mem_wb_data_reg      <= mem_data;
            mem_wb_alu_result_reg<= mem_alu_result;
            mem_wb_rd_reg        <= mem_rd;
            mem_wb_reg_write_reg <= mem_reg_write;
            mem_wb_mem_reg_reg   <= mem_regout;
            mem_wb_pc_plus4_reg  <= ex_mem_pc_plus4_reg;
            mem_wb_jump_reg      <= ex_mem_jump_reg;
        end
    end

    // WB stage
    WB u_WB (
        .mem_data    (mem_wb_data_reg),
        .alu_result  (mem_wb_alu_result_reg),
        .pc_plus4    (mem_wb_pc_plus4_reg),
        .rd          (mem_wb_rd_reg),
        .reg_write   (mem_wb_reg_write_reg),
        .mem_reg     (mem_wb_mem_reg_reg),
        .jump        (mem_wb_jump_reg),
        .wb_data     (wb_data),
        .wb_rd       (wb_rd),
        .wb_regwrite (wb_regwrite)
    );

endmodule