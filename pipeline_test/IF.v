module IF_test (
    input clk,
    input rst,
    input flush,
    input stall,
//
input wire        predicted_take,
input wire [31:0] predicted_pc,
input wire        actual_take,    
//
 // ex_take from EX (actual branch outcome)
    // Control signals from pipeline
    input jump,
    input jalr_enable,
    input branch,
    input zero,

    input [31:0]  rs1_data,
    input [31:0]  imm,
    input [2:0]   funct3,
    input [31:0]  alu_result,
    input [31:0]  branch_pc,

    //current PC
    output [31:0] instr_addr,// output to instruction memory

    // From instruction memory
    input  [31:0] instr_data,

    // To ID
    output [31:0] if_id_pc,
    output [31:0] if_id_instr
);

    reg [31:0] pc;
    wire [31:0] next_pc;

// IF/ID pipeline registers
    reg [31:0] if_id_pc_reg;
    reg [31:0] if_id_instr_reg;

    wire [31:0] pc_for_update;
    assign pc_for_update = flush ? branch_pc : pc;

    // Use the PC_update module
    PC_update pc_update_inst (
        .rs1_data(rs1_data),
        .jump(jump),
        .jalr_enable(jalr_enable),
        .branch(branch),
        .funct3(funct3),
        .alu_result(alu_result),
        .pc_address(pc_for_update),
        .imm(imm),
        .zero(zero),
        .next_pc(next_pc)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'h00000000;
            if_id_pc_reg <= 32'h00000000;
            if_id_instr_reg <= 32'h00000000;
        end else if (flush) begin
            pc <= next_pc;
            if_id_pc_reg <= 32'h00000000;
            if_id_instr_reg <= 32'h00000000;
        end else if (stall) begin
            pc <= pc;
            if_id_pc_reg <= if_id_pc_reg;
            if_id_instr_reg <= if_id_instr_reg;
        end else begin
            pc <= predicted_take ? predicted_pc : (pc + 32'd4);
            if (predicted_take) begin
                if_id_pc_reg <= pc;
                if_id_instr_reg <= 32'h00000000;  // predict jump
            end else begin
                if_id_pc_reg <= pc;
                if_id_instr_reg <= instr_data;
            end
        end
    end

    // Output
    assign instr_addr   = pc;
    assign if_id_pc     = if_id_pc_reg;
    assign if_id_instr  = if_id_instr_reg;

endmodule
