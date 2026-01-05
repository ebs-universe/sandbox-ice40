module top #(
    parameter integer CLK_HZ     = 12_000_000,
    parameter integer CLK_SYS_HZ = 25_000_000,
    parameter integer NTAPS  = 6
)(
    input  CLK,

    // ------------------------------------------------------------
    // DIP switches (step value)
    // ------------------------------------------------------------
    input  DIP_S4,
    input  DIP_S3,
    input  DIP_S2,
    input  DIP_S1,

    // ------------------------------------------------------------
    // 8 discrete LEDs (counter display)
    // ------------------------------------------------------------
    output LED_L1,
    output LED_L2,
    output LED_L3,
    output LED_L4,
    output LED_L5,
    output LED_L6,
    output LED_L7,
    output LED_L8,

    // ------------------------------------------------------------
    // RGB LED
    // ------------------------------------------------------------
    output LED_R,
    output LED_G,
    output LED_B
);

    // ============================================================
    // PLL
    // ============================================================
    wire clk_sys;
    wire pll_lock;

    pll u_pll (
        .clk_in   (CLK),
        .clk_out  (clk_sys),
        .pll_lock (pll_lock)
    );

    // ============================================================
    // System reset
    // ============================================================
    wire sys_reset_n;

    reset u_reset (
        .clk         (clk_sys),
        .pll_lock    (pll_lock),
        .ext_reset_n (1'b1),
        .reset_n     (sys_reset_n)
    );

    // ============================================================
    // Coarse system timebase        .NTAPS(NTAPS)
    // ============================================================
    wire [31:0] ticks;
    wire [(NTAPS-1):0]  taps;

    timebase #(
        .NTAPS(NTAPS)
    ) u_timebase (
        .clk     (clk_sys),
        .reset_n (sys_reset_n),
        .ticks   (ticks),
        .taps    (taps)
    );

    // ============================================================
    // DIP switches → 4-bit step
    // ============================================================
    wire [3:0] step;

    pmod_dip4 u_dip (
        .DIP_S4(DIP_S4),
        .DIP_S3(DIP_S3),
        .DIP_S2(DIP_S2),
        .DIP_S1(DIP_S1),
        .val   (step)
    );

    // ============================================================
    // 8-bit stepper counter (updates every ~1 second)
    // ============================================================
    wire [7:0] ctr;

    stepped_counter #(
        .CLK_HZ(CLK_SYS_HZ),
        .NTAPS(NTAPS),
        .PERIOD_MS(1000)
    ) ctr8 (
        .clk        (clk_sys),
        .reset_n    (sys_reset_n),
        .taps       (taps),
        .step       (step),
        .ctr        (ctr)
    );

    // ============================================================
    // Display counter on 8 LEDs
    // ============================================================
    pmod_led8 u_leds (
        .val    (ctr),
        .LED_L1 (LED_L1),
        .LED_L2 (LED_L2),
        .LED_L3 (LED_L3),
        .LED_L4 (LED_L4),
        .LED_L5 (LED_L5),
        .LED_L6 (LED_L6),
        .LED_L7 (LED_L7),
        .LED_L8 (LED_L8)
    );

    // ============================================================
    // RGB blink logic
    // ============================================================
    wire r, g, b;

    rgb_blink #(
        .CLK_HZ(CLK_SYS_HZ),
        .NTAPS(NTAPS),
        .R_PERIOD_MS(1000),
        .G_PERIOD_MS(700),
        .B_PERIOD_MS(300)
    ) u_rgb_blink (
        .clk        (clk_sys),
        .reset_n    (sys_reset_n),
        .taps       (taps),
        .r          (r),
        .g          (g),
        .b          (b)
    );

    // ============================================================
    // Physical RGB LED outputs 
    // ============================================================
    rgb_led u_rgb_led (
        .r     (r),
        .g     (g),
        .b     (b),
        .LED_R (LED_R),
        .LED_G (LED_G),
        .LED_B (LED_B)
    );

endmodule
