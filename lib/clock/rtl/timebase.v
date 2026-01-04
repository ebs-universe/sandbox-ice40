module timebase #(
    parameter integer NTAPS = 6
)(
    input  clk,

    output reg [26:0]      ticks,  // 27-bit monotonic timebase
    output reg [NTAPS-1:0] taps
);

    // ------------------------------------------------------------
    // Stage 0: low half counter (12 bits)
    // ------------------------------------------------------------
    reg [11:0] lo;

    // ------------------------------------------------------------
    // Stage 1: registered carry from low half
    // ------------------------------------------------------------
    reg        lo_carry_d;

    // ------------------------------------------------------------
    // Stage 2: high half counter (15 bits)
    // ------------------------------------------------------------
    reg [14:0] hi;

    // ------------------------------------------------------------
    // Stage 3: tap sampling and edge detection
    // ------------------------------------------------------------
    reg [NTAPS-1:0] prev;
    reg [NTAPS-1:0] edge;

    integer k;

    // ------------------------------------------------------------
    // Compute tap bit positions at elaboration time
    // Spread evenly across 27 bits
    // ------------------------------------------------------------
    function integer tap_bit;
        input integer i;
        begin
            tap_bit = (i * 26) / (NTAPS - 1);
        end
    endfunction

    // ------------------------------------------------------------
    // Sequential logic
    // ------------------------------------------------------------
    always @(posedge clk) begin
        // --------------------------------------------------------
        // Stage 0: increment low half every cycle
        // --------------------------------------------------------
        lo <= lo + 1'b1;

        // --------------------------------------------------------
        // Stage 1: register carry (PHYSICAL pipeline break)
        // --------------------------------------------------------
        lo_carry_d <= (lo == 12'hFFF);

        // --------------------------------------------------------
        // Stage 2: increment high half using REGISTERED carry
        // --------------------------------------------------------
        hi <= hi + lo_carry_d;

        // --------------------------------------------------------
        // Stage 3: sample tap bits & edge detect
        // Uses the REGISTERED tick value
        // --------------------------------------------------------
        for (k = 0; k < NTAPS; k = k + 1) begin
            edge[k] <= ticks[tap_bit(k)] ^ prev[k];
            prev[k] <= ticks[tap_bit(k)];
        end

        // --------------------------------------------------------
        // Stage 4: publish outputs
        // --------------------------------------------------------
        ticks <= {hi, lo};
        taps  <= edge;
    end

endmodule
