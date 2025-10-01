module mux(
    input wire [31:0] in0, // first input
    input wire [31:0] in1, // second input
    input wire ctrl,    // control signal
    output reg [31:0] out // output
);
    always @(*) begin
        out = ctrl ? in1 : in0;
    end
endmodule
