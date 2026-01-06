module stepped_loop #(
    parameter integer CLK_HZ,
    parameter integer PERIOD_US,
    parameter integer NTAPS,
    parameter integer WIDTH,
    parameter integer MAX_DIV
)(
    input              clk,
    input              reset_n,
    input  [NTAPS-1:0] taps,
    input  [3:0]       step,
    output     [7:0]   data
);

    // ------------------------------------------------------------
    // Periodic tick (raw)
    // ------------------------------------------------------------
    wire tick_raw;

    periodic_tick #(
        .CLK_HZ    (CLK_HZ),
        .PERIOD_US (PERIOD_US),
        .WIDTH     (WIDTH),
        .NTAPS     (NTAPS),
        .MAX_DIV   (MAX_DIV)
    ) u_timer (
        .clk     (clk),
        .reset_n (reset_n),
        .taps    (taps),
        .tick    (tick_raw)
    );

    // ------------------------------------------------------------
    // Locally registered tick (timing boundary)
    // ------------------------------------------------------------
    reg tick;

    always @(posedge clk) begin
        if (!reset_n)
            tick <= 1'b0;
        else
            tick <= tick_raw;
    end

    // ------------------------------------------------------------
    // Step control (FULLY CLOCKED, NO ENABLE)
    // ------------------------------------------------------------
    reg [3:0] steps_left;
    reg [3:0] steps_next;

    always @(*) begin
        // Default: hold state
        steps_next = steps_left;

        // Load on tick when idle
        if (tick && steps_left == 0 && step != 0)
            steps_next = step;
        // Count down while active
        else if (steps_left != 0)
            steps_next = steps_left - 4'd1;
    end

    always @(posedge clk) begin
        if (!reset_n)
            steps_left <= 4'd0;
        else
            steps_left <= steps_next;
    end

    // ------------------------------------------------------------
    // Shift enable (data-path gating only)
    // ------------------------------------------------------------
    wire shift_en = (steps_left != 0);

    // ------------------------------------------------------------
    // Shift register (unchanged)
    // ------------------------------------------------------------
    shift8 #(
        .INITIAL(8'h01)
    ) u_shift (
        .clk     (clk),
        .reset_n (reset_n),
        .enable  (shift_en),
        .d_in    (data[7]),
        .data    (data),
        .d_out   ()
    );

endmodule
