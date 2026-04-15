module PC_update (
    input [31:0] rs1_data,
    input jump,
    input jalr_enable,
    input branch,
    input [2:0] funct3,      // Added for checking BNE, BLT, etc.
    input [31:0] alu_result, // Added for checking SLT results
    input [31:0] pc_address,
    input [31:0] imm,
    input zero,
    output reg [31:0] next_pc
);
    reg take_branch;

    always @(*) begin
        take_branch = 0;
        
        // 分支邏輯判斷
        if (branch) begin
            case (funct3)
                3'b000: take_branch = zero;             // BEQ: zero == 1
                3'b001: take_branch = ~zero;            // BNE: zero == 0
                3'b100: take_branch = alu_result[0];    // BLT: result == 1
                3'b101: take_branch = alu_result[0];    // BGE: ALU logic (User logic outputs 1 if GE)
                3'b110: take_branch = alu_result[0];    // BLTU
                3'b111: take_branch = ~alu_result[0];   // BGEU: invert SLTU result
                default: take_branch = 0;
            endcase
        end

        // Next PC Calculation
        if (jump && jalr_enable) begin
            // JALR: (rs1 + imm) & ~1
            next_pc = (rs1_data + imm) & 32'hFFFFFFFE;
        end
        else if ((jump && !jalr_enable) || (branch && take_branch)) begin
            // JAL or Branch Taken: PC + imm (imm already shifted in generator)
            next_pc = pc_address + imm; 
        end
        else begin
            // Default: PC + 4
            next_pc = pc_address + 32'd4;
        end
    end
endmodule
