// Forwarding Unit
// ForwardA/ForwardB encoding:
// 2'b00 = ID/EX value
// 2'b10 = EX/MEM value
// 2'b01 = MEM/WB value
module forwarding_unit (
    input  wire        ex_mem_regwrite,
    input  wire [4:0]  ex_mem_rd,
    input  wire        mem_wb_regwrite,
    input  wire [4:0]  mem_wb_rd,
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    input  wire [4:0]  ex_mem_rs2,
    output reg  [1:0]  forwardA,
    output reg  [1:0]  forwardB,
    output reg         mem_forward_from_wb
);
    always @(*) begin
        // Defaults: no forwarding
        forwardA = 2'b00;
        forwardB = 2'b00;
        mem_forward_from_wb = 1'b0;

        // EX stage operand A forwarding
        if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            forwardA = 2'b10; // from EX/MEM
        end else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1)) begin
            forwardA = 2'b01; // from MEM/WB
        end

        // EX stage operand B forwarding
        if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            forwardB = 2'b10; // from EX/MEM
        end else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2)) begin
            forwardB = 2'b01; // from MEM/WB
        end

        // MEM stage store-data forwarding (from WB)
        if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == ex_mem_rs2)) begin
            mem_forward_from_wb = 1'b1;
        end
    end
endmodule
