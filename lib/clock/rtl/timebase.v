module timebase #(
    parameter integer CLK_HZ = 12_000_000
)(
    input        clk,
    output reg [31:0] cycles = 0,
    output reg [31:0] us     = 0
);
    localparam integer CYCLES_PER_US = CLK_HZ / 1_000_000;

    reg [$clog2(CYCLES_PER_US)-1:0] us_div = 0;

    always @(posedge clk) begin
        cycles <= cycles + 1;

        // Free-running divider
        us_div <= us_div + 1;

        if (us_div == CYCLES_PER_US-1) begin
            us_div <= 0;
            us     <= us + 1;
        end
    end
endmodule
