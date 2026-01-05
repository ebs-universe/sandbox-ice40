module timebase #(
    parameter integer NTAPS = 6
)(
    input  clk,
    input reset_n,
    output reg [26:0]      ticks,  // 27-bit monotonic timebase
    output reg [NTAPS-1:0] taps
);

    reg [11:0] lo;
    reg lo_carry_d;
    reg [14:0] hi;
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
        if (!reset_n) begin
            lo          <= 12'h000;
            lo_carry_d  <= 1'b0;
            hi          <= 15'h0000;
            ticks       <= 27'h0000000;
            taps        <= {NTAPS{1'b0}};
            prev        <= {NTAPS{1'b0}};
            edge        <= {NTAPS{1'b0}};
        end else begin
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
    end

endmodule
