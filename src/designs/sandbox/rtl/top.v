module top #(
    parameter integer CLK_HZ        = 12_000_000,
    parameter integer CLK_SYS_HZ    = 48_000_000,
    parameter integer NTAPS         = 6,
    parameter integer WIDTH         = 27,
    parameter integer MAX_DIV       = 255
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
    // 8 discrete LEDs
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
    // 7 segment display (PMOD DT2)
    // ------------------------------------------------------------
    output DT2_A,
    output DT2_B,
    output DT2_C,
    output DT2_D,
    output DT2_E,
    output DT2_F,
    output DT2_G,
    output DT2_SEL,

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
        
    pll #(
        .DIVR (0),
        .DIVF (63),
        .DIVQ (4)
    ) u_pll (
        .clk_in   (CLK),
        .clk_out  (clk_sys),
        .pll_lock (pll_lock)
    );

    // ============================================================
    // System
    // ============================================================
    
    wire sys_reset_n;

    reset u_reset (
        .clk         (clk_sys),
        .pll_lock    (pll_lock),
        .ext_reset_n (1'b1),
        .reset_n     (sys_reset_n)
    );

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
    // Inputs
    // ============================================================
    reg [3:0] step;

    pmod_dip4 u_dip (
        .clk        (clk_sys),
        .DIP_S4     (DIP_S4),
        .DIP_S3     (DIP_S3),
        .DIP_S2     (DIP_S2),
        .DIP_S1     (DIP_S1),
        .val        (step)
    );

    // ============================================================
    // Logic
    // ============================================================
    wire [7:0] ctr;

    stepped_counter #(
        .CLK_HZ(CLK_SYS_HZ),
        .PERIOD_MS(1000),
        .NTAPS(NTAPS),
        .WIDTH(WIDTH),
        .MAX_DIV(MAX_DIV)
    ) ctr8 (
        .clk        (clk_sys),
        .reset_n    (sys_reset_n),
        .taps       (taps),
        .step       (step),
        .ctr        (ctr)
    );

    wire [7:0] loop;

    stepped_loop #(
        .CLK_HZ(CLK_SYS_HZ),
        .PERIOD_MS(1000),
        .NTAPS(NTAPS),
        .WIDTH(WIDTH),
        .MAX_DIV(MAX_DIV)
    ) loop8 (
        .clk        (clk_sys),
        .reset_n    (sys_reset_n),
        .taps       (taps),
        .step       (step),
        .data       (loop)
    );
    
    wire r, g, b;

    rgb_blink #(
        .CLK_HZ(CLK_SYS_HZ),
        .R_PERIOD_MS(1000),
        .G_PERIOD_MS(700),
        .B_PERIOD_MS(300),
        .NTAPS(NTAPS),
        .WIDTH(WIDTH),
        .MAX_DIV(MAX_DIV)
    ) u_rgb_blink (
        .clk        (clk_sys),
        .reset_n    (sys_reset_n),
        .taps       (taps),
        .r          (r),
        .g          (g),
        .b          (b)
    );

    // ============================================================
    // Outputs 
    // ============================================================
    rgb_led u_rgb_led (
        .r     (r),
        .g     (g),
        .b     (b),
        .LED_R (LED_R),
        .LED_G (LED_G),
        .LED_B (LED_B)
    );

    pmod_led8 u_leds (
        .val    (loop),
        .LED_L1 (LED_L1),
        .LED_L2 (LED_L2),
        .LED_L3 (LED_L3),
        .LED_L4 (LED_L4),
        .LED_L5 (LED_L5),
        .LED_L6 (LED_L6),
        .LED_L7 (LED_L7),
        .LED_L8 (LED_L8)
    );

    pmod_dt2 #(
        .USE_EXTERNAL_TICK  (0),
        .CLK_HZ    (CLK_SYS_HZ),
        .PERIOD_MS (1),
        .NTAPS     (NTAPS),
        .WIDTH     (WIDTH),
        .MAX_DIV   (MAX_DIV)
    ) u_dt2 (
        .clk          (clk_sys),
        .reset_n      (sys_reset_n),
        .taps         (taps),
        .val          (ctr),
        .refresh_tick (),

        .DT2_A        (DT2_A),
        .DT2_B        (DT2_B),
        .DT2_C        (DT2_C),
        .DT2_D        (DT2_D),
        .DT2_E        (DT2_E),
        .DT2_F        (DT2_F),
        .DT2_G        (DT2_G),
        .DT2_SEL      (DT2_SEL)
    );

endmodule
