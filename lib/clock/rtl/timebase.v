module timebase #(
    parameter integer WIDTH = 32,
    parameter integer NTAPS = 6
)(
    input  clk,
    output reg [WIDTH-1:0] ticks,
    output reg [NTAPS-1:0] taps
);
    reg [NTAPS-1:0] prev;

    // Compute tap bit positions at elaboration time
    function integer tap_bit;
        input integer i;
        begin
            tap_bit = (i * (WIDTH-1)) / (NTAPS-1);
        end
    endfunction

    integer k;

    always @(posedge clk) begin
        ticks <= ticks + 1;

        for (k = 0; k < NTAPS; k = k + 1) begin
            prev[k] <= ticks[tap_bit(k)];
            taps[k] <= ticks[tap_bit(k)] ^ prev[k];
        end
    end
endmodule
