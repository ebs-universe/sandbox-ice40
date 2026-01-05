module sync1 #(
    parameter integer STAGES = 2
)(
    input  wire clk,
    input  wire din,     // async input
    output wire dout     // synced output
);

    reg [STAGES-1:0] ff = {STAGES{1'b0}};

    always @(posedge clk) begin
        ff <= {ff[STAGES-2:0], din};
    end

    assign dout = ff[STAGES-1];

endmodule
