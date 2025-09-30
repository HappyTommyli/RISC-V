module mux(
    input wire [31:0] in0,
    input wire [31:0] in1,
    input wire ctrl,
    output reg [31:0] ou
)
    always @(*) begin
        if (ctrl) begin
            out = in1;
        end else begin
            out = in0;
        end
    end
