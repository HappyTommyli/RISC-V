module IF (
    input clk,
    input rst,

    // Control signals from pipeline
    input jump,
    input jalr_enable,
    input branch,

    input [31:0]  rs1_data,
    input [31:0]  imm,

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

    // Use the PC_update module
    PC_update pc_update_inst (
        .rs1_data(rs1_data),
        .jump(jump),
        .jalr_enable(jalr_enable),
        .branch(branch),
        .pc_address(pc),
        .imm(imm),
        .zero(zero),
        .next_pc(next_pc)
    );

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h00000000;
        else
            pc <= next_pc;
    end

    // Output
    assign instr_addr   = pc;
    assign if_id_pc     = pc;
    assign if_id_instr  = instr_data;

endmodule
