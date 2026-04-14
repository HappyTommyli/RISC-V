// Hazard Detection Unit (load-use)
// If ID/EX is a load, and IF/ID uses its destination, stall 1 cycle.
module hazard_unit (
    input  wire       id_ex_memread,
    input  wire [4:0] id_ex_rd,
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    input  wire       flush,
    output wire       stall
);
    wire raw_stall;
    assign raw_stall =
        id_ex_memread &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

    // If a branch/jump is flushing the pipe, don't stall on a soon-to-be-killed instr
    assign stall = raw_stall && !flush;
endmodule
