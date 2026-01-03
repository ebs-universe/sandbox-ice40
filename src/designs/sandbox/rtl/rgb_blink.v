module rgb_blink #(
    parameter integer CLK_HZ      = 12_000_000,
    parameter integer WIDTH       = 32,
    parameter integer NTAPS       = 6,

    // Desired toggle periods (milliseconds)
    parameter integer R_PERIOD_MS = 1000,
    parameter integer G_PERIOD_MS = 700,
    parameter integer B_PERIOD_MS = 300,

    // Limit local divider size
    parameter integer MAX_DIV     = 255
)(
    input  clk,
    input  [NTAPS-1:0] taps,

    output reg r = 0,
    output reg g = 0,
    output reg b = 0
);

    // ---------------------------------------------
    // Tap bit index (must match timebase)
    // ---------------------------------------------
    function integer tap_bit;
        input integer i;
        begin
            tap_bit = (i * (WIDTH-1)) / (NTAPS-1);  
        end
    endfunction

    // ---------------------------------------------
    // Choose best tap (compile-time)
    // ---------------------------------------------
    function integer select_tap;
        input integer period_ms;
        integer i;
        integer coarse_hz;
        integer div;
        begin
            select_tap = 0;
            for (i = NTAPS-1; i >= 0; i = i - 1) begin
                coarse_hz = CLK_HZ >> (tap_bit(i) + 1);
                div = (coarse_hz * period_ms) / 1000;
                if (div > 0 && div <= MAX_DIV)
                    select_tap = i;
            end
        end
    endfunction

    localparam integer R_TAP = select_tap(R_PERIOD_MS);
    localparam integer G_TAP = select_tap(G_PERIOD_MS);
    localparam integer B_TAP = select_tap(B_PERIOD_MS);

    localparam integer R_DIV =
        ((CLK_HZ >> (tap_bit(R_TAP)+1)) * R_PERIOD_MS) / 1000;
    localparam integer G_DIV =
        ((CLK_HZ >> (tap_bit(G_TAP)+1)) * G_PERIOD_MS) / 1000;
    localparam integer B_DIV =
        ((CLK_HZ >> (tap_bit(B_TAP)+1)) * B_PERIOD_MS) / 1000;

    // ---------------------------------------------
    // Small local counters
    // ---------------------------------------------
    reg [$clog2(R_DIV)-1:0] r_cnt = 0;
    reg [$clog2(G_DIV)-1:0] g_cnt = 0;
    reg [$clog2(B_DIV)-1:0] b_cnt = 0;

    always @(posedge clk) begin
        // Red
        if (taps[R_TAP]) begin
            if (r_cnt == R_DIV-1) begin
                r_cnt <= 0;
                r <= ~r;
            end else
                r_cnt <= r_cnt + 1;
        end

        // Green
        if (taps[G_TAP]) begin
            if (g_cnt == G_DIV-1) begin
                g_cnt <= 0;
                g <= ~g;
            end else
                g_cnt <= g_cnt + 1;
        end

        // Blue
        if (taps[B_TAP]) begin
            if (b_cnt == B_DIV-1) begin
                b_cnt <= 0;
                b <= ~b;
            end else
                b_cnt <= b_cnt + 1;
        end
    end
endmodule
