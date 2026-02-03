`timescale 1ns / 1ps

module SingleCycle_RISCV (
    input wire clk,    // System clock
    input wire rst     // Global reset
);

    // Wires
    wire [31:0] next_pc;
    wire [31:0] pc_address;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] imm;
    wire [31:0] instruction;
    wire [31:0] alu_result;
    wire [31:0] data_mem_data;
    wire [31:0] writeback_data; // Data to be written to RegFile
    wire [31:0] alu_operand_2;  // Output of Mux ALU
    wire [31:0] alu_operand_1;
    wire alu_src1; 
    wire is_lui = (instruction[6:0] == 7'b0110111); // LUI should use 0 as rs1

    // Control Signals
    wire jump;
    wire jalr_enable;
    wire branch;
    wire mem_read;
    wire mem_write;
    wire reg_write;
    wire mem_to_reg;
    wire alu_src;
    wire [3:0] alu_op;
    wire zero;
    wire overflow;
    
    // CSR Signals (保留原樣)
    wire [11:0] csr_addr;
    wire csr_write_enable;
    wire [1:0] csr_op;
    wire [4:0] csr_imm;
    wire [2:0] csr_funct3;
    wire [31:0] csr_rdata;

    // Extract funct3 for PC_update branching logic
    wire [2:0] funct3 = instruction[14:12];

    // --- 1. PC Module ---
    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc_address(pc_address)
    );

    // --- 2. Instruction Memory ---
    blk_mem_gen_0 instruction_memory (
        .clka (clk),
        .addra (pc_address[14:2]), // Mapping byte address to word address
        .douta (instruction)
    );

    // --- 3. Control Unit ---
    CU CU_inst (
        .instruction(instruction),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .alu_src(alu_src),
        .alu_src1(alu_src1),
        .alu_op(alu_op),
        .branch(branch),
        .jalr_enable(jalr_enable),
        .jump(jump),
        .csr_addr(csr_addr),
        .csr_write_enable(csr_write_enable),
        .csr_op(csr_op),
        .csr_imm(csr_imm),
        .csr_funct3(csr_funct3)
    );

    // --- 4. Register File ---
    // [FIX] Write Back Logic Mux
    // If Jump (JAL/JALR), write PC+4. Else if MemToReg, write Mem. Else write ALU.
    assign writeback_data = (jump) ? (pc_address + 32'd4) : 
                            (mem_to_reg ? data_mem_data : alu_result);

    Reg_File Reg_File_inst (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .instruction(instruction),
        .write_data(writeback_data), // 連接修正後的數據
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // --- 5. Immediate Generator ---
    imm_generator imm_generator_inst (
        .instruction(instruction),
        .imm(imm)
    );

    // --- 6. ALU Mux ---
    // LUI uses 0 as rs1 to avoid rs1 field aliasing into immediate
    wire [31:0] rs1_or_zero = is_lui ? 32'b0 : rs1_data;
    mux mux_alu_1(    //(處理 AUIPC)
        .in0(rs1_or_zero),
        .in1(pc_address),
        .ctrl(alu_src1),
        .out(alu_operand_1)
    );

    mux mux_alu_2(   //(處理 I-Type/Load/Store)
        .in0(rs2_data),
        .in1(imm),
        .ctrl(alu_src),
        .out(alu_operand_2)
    );

    // --- 7. ALU ---
    ALU ALU_inst (
        .rs1_data(alu_operand_1),
        .rs2_data(alu_operand_2),
        .alu_op(alu_op),
        .zero(zero),
        .alu_result(alu_result),
        .overflow(overflow)
    );

    // --- 8. CSR (Optional) ---
    csr_reg csr_reg_inst (
        .clk(clk),
        .rst(rst),
        .csr_addr(csr_addr),
        .csr_write_enable(csr_write_enable),
        .csr_op(csr_op),
        .csr_funct3(csr_funct3),
        .rs1_data(rs1_data),
        .csr_imm(csr_imm),
        .csr_rdata(csr_rdata)
    );

    // --- 9. Data Memory ---
    Data_Memory Data_Memory_inst (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .rs2_data(rs2_data),
        .alu_result(alu_result),
        .instruction(instruction),
        .data_mem_data(data_mem_data)
    );

    // --- 10. PC Update Logic ---
    PC_update PC_update_inst (
        .rs1_data(rs1_data),
        .jump(jump),
        .jalr_enable(jalr_enable),
        .branch(branch),
        .funct3(funct3),       // [FIX] Added funct3 input
        .alu_result(alu_result), // [FIX] Added alu_result for magnitude check
        .pc_address(pc_address),
        .imm(imm),
        .zero(zero),
        .next_pc(next_pc)
    );

endmodule
