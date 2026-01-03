module top #(
    parameter integer CLK_HZ = 12_000_000
)(
    input  CLK,
    output LED_R,
    output LED_G,
    output LED_B
);
    // ------------------------------------------------------------
    // System timebase (still global, as intended)
    // ------------------------------------------------------------
    wire [31:0] cycles;
    wire [31:0] us;
    wire tick_100ms;

    timebase #(
        .CLK_HZ(CLK_HZ)
    ) tb (
        .clk   (CLK),
        .cycles(cycles),
        .us    (us)
    );

    tick_100ms #(
        .CLK_HZ(CLK_HZ)
    ) tickgen (
        .clk (CLK),
        .tick(tick_100ms)
    );

    // ------------------------------------------------------------
    // RGB blink (self-contained timing)
    // ------------------------------------------------------------
    wire r, g, b;

    rgb_blink blink (
        .clk        (CLK),
        .tick_100ms (tick_100ms),
        .r          (r),
        .g          (g),
        .b          (b)
    );

    // ------------------------------------------------------------
    // Physical LED outputs
    // ------------------------------------------------------------
    rgb_led leds (
        .r(r),
        .g(g),
        .b(b),
        .LED_R(LED_R),
        .LED_G(LED_G),
        .LED_B(LED_B)
    );
endmodule
