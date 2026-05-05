module mux(
    input wire [31:0] in0,
    input wire [31:0] in1,
    input wire ctrl,
    output reg [31:0] out
);
    always @(*) out = ctrl ? in1 : in0;
endmodule