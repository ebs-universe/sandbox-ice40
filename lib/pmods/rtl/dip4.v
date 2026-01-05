module pmod_dip4 (
    input        clk,

    input        DIP_S4,
    input        DIP_S3,
    input        DIP_S2,
    input        DIP_S1,

    output reg [3:0] val
);

    always @(posedge clk) begin
        val <= {
            DIP_S4,
            DIP_S3,
            DIP_S2,
            DIP_S1
        };
    end

endmodule
