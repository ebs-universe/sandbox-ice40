module reg8 (
    input        clk,
    input        en,
    input  [7:0] d,
    output reg [7:0] q = 8'd0
);
    always @(posedge clk) begin
        if (en)
            q <= d;
    end
endmodule
