module periodic_tick #(
    parameter integer CLK_HZ,
    parameter integer PERIOD_US,
    parameter integer NTAPS,
    parameter integer WIDTH,
    parameter integer MAX_DIV
)(
    input  wire             clk,
    input  wire             reset_n,
    input  wire [NTAPS-1:0] taps,
    output wire             tick     // 1-cycle pulse
);

    // ------------------------------------------------------------
    // Helper functions
    // ------------------------------------------------------------
    function automatic longint abs64;
        input longint x;
        begin
            abs64 = (x < 0) ? -x : x;
        end
    endfunction

    function automatic integer tap_bit;
        input integer i;
        begin
            tap_bit = (i * (WIDTH-1)) / (NTAPS-1);
        end
    endfunction

    // ------------------------------------------------------------
    // Select TAP and DIV (tap-only, deterministic)
    // ------------------------------------------------------------
    function automatic integer select_tap;
        integer i;
        longint best_err;
        longint err;
        longint tap_period_ns;
        longint ideal_div;
        longint actual_us;
        begin
            best_err   = 64'h7FFF_FFFF_FFFF_FFFF;
            select_tap = 0;

            for (i = 0; i < NTAPS; i = i + 1) begin
                tap_period_ns =
                    (64'd1 << (tap_bit(i) + 1)) * 64'd1_000_000_000 / CLK_HZ;

                ideal_div =
                    (PERIOD_US * 1_000 + tap_period_ns/2) / tap_period_ns;

                if (ideal_div < 1)
                    ideal_div = 1;
                if (ideal_div > MAX_DIV)
                    ideal_div = MAX_DIV;

                actual_us = (ideal_div * tap_period_ns) / 1_000;
                err = abs64(actual_us - PERIOD_US);

                if (err < best_err) begin
                    best_err   = err;
                    select_tap = i;
                end
            end
        end
    endfunction

    function automatic integer select_div;
        input integer tap;
        longint tap_period_ns;
        longint ideal_div;
        begin
            tap_period_ns =
                (64'd1 << (tap_bit(tap) + 1)) * 64'd1_000_000_000 / CLK_HZ;

            ideal_div =
                (PERIOD_US * 1_000 + tap_period_ns/2) / tap_period_ns;

            if (ideal_div < 1)
                select_div = 1;
            else if (ideal_div > MAX_DIV)
                select_div = MAX_DIV;
            else
                select_div = ideal_div;
        end
    endfunction

    // ------------------------------------------------------------
    // Elaboration-time constants
    // ------------------------------------------------------------
    localparam integer TAP = select_tap();
    localparam integer DIV = select_div(TAP);

    // NOTE:
    // Tap mode is mathematically valid up to ~480 kHz @ 48 MHz clock.
    // Frequencies above ~100 kHz are allowed but not recommended due
    // to increasing divider quantization error.

    // ------------------------------------------------------------
    // Rising-edge detection on selected tap
    // ------------------------------------------------------------
    reg tap_d;

    always @(posedge clk) begin
        if (!reset_n)
            tap_d <= 1'b0;
        else
            tap_d <= taps[TAP];
    end

    wire tap_rise = taps[TAP] && !tap_d;

    // ------------------------------------------------------------
    // Divider (counts tap periods)
    // ------------------------------------------------------------
    reg [$clog2(DIV)-1:0] div_cnt;

    reg tick_r;

    always @(posedge clk) begin
        if (!reset_n) begin
            div_cnt <= 0;
            tick_r  <= 1'b0;
        end else begin
            tick_r <= 1'b0;

            if (tap_rise) begin
                if (div_cnt == DIV-1) begin
                    div_cnt <= 0;
                    tick_r  <= 1'b1;
                end else begin
                    div_cnt <= div_cnt + 1'b1;
                end
            end
        end
    end

    assign tick = tick_r;

endmodule
