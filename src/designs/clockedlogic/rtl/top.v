module top #(
    parameter integer CLK_HZ        = 12_000_000,
    parameter integer CLK_HFINT_HZ  = 24_000_000,
    parameter integer CLK_LFINT_HZ  = 10_000,
    parameter integer CLK_SYS_HZ    = 48_000_000,
    parameter integer NTAPS         = 6,
    parameter integer WIDTH         = 27,
    parameter integer MAX_DIV       = 255
)(
    input  CLK,

    // ------------------------------------------------------------
    // DIP switches (step value)
    // ------------------------------------------------------------
    // input  DIP_S4,
    // input  DIP_S3,
    // input  DIP_S2,
    // input  DIP_S1,

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
    output LED_B,

    // ------------------------------------------------------------
    // UART
    // ------------------------------------------------------------
    output UART_TX,
    input UART_RX
);

    // ============================================================
    // System
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
    
    wire sys_reset_n;

    reset u_reset (
        .clk         (clk_sys),
        .pll_lock    (pll_lock),
        .ext_reset_n (1'b1),
        .reset_n     (sys_reset_n)
    );

    wire [26:0] ticks;
    wire [(NTAPS-1):0]  taps;
    
    timebase #(
        .NTAPS(NTAPS)
    ) u_timebase (
        .clk     (clk_sys),
        .reset_n (sys_reset_n),
        .ticks   (ticks),
        .taps    (taps)
    );

    // Secondary Clock Domain : HFINT
    wire clk_hfint;
    
    hfosc #(
        .DIV(1)       // 24 MHz
    ) u_hfosc (
        .clk_out(clk_hfint)
    );

    wire [26:0] hfint_ticks;
    wire [(NTAPS-1):0]  hfint_taps;
    
    timebase #(
        .NTAPS(NTAPS)
    ) u_hfint_timebase (
        .clk     (clk_hfint),
        .reset_n (sys_reset_n),
        .ticks   (hfint_ticks),
        .taps    (hfint_taps)
    );

    // Tertiary Clock Domain : LFINT
    wire clk_lfint;

    lfosc u_lfosc (
        .clk_out(clk_lfint)
    );

    wire [26:0] lfint_ticks;
    wire [1:0]  lfint_taps;

    timebase #(
        .NTAPS(2)
    ) u_lfint_timebase (
        .clk     (clk_lfint),
        .reset_n (sys_reset_n),
        .ticks   (lfint_ticks),
        .taps    (lfint_taps)
    );

    // ============================================================
    // UART
    // ============================================================


    // ============================================================
    // Inputs
    // ============================================================
    reg [3:0] step = 4'b0001;

    // DIP4 conflicts with UART.
    // pmod_dip4 u_dip (
    //     .clk        (clk_sys),
    //     .DIP_S4     (DIP_S4),
    //     .DIP_S3     (DIP_S3),
    //     .DIP_S2     (DIP_S2),
    //     .DIP_S1     (DIP_S1),
    //     .val        (step)
    // );

    // ============================================================
    // Logic
    // ============================================================
    wire [7:0] ctr;

    stepped_counter #(
        .CLK_HZ(CLK_SYS_HZ),
        .PERIOD_US(1_000_000),
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
        .PERIOD_US(1_000_000),
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

    // rgb_blink #(
    //     .CLK_HZ(CLK_SYS_HZ),
    //     .R_PERIOD_US(1_000_000),
    //     .G_PERIOD_US(  700_000),
    //     .B_PERIOD_US(  300_000),
    //     .NTAPS(NTAPS),
    //     .WIDTH(WIDTH),
    //     .MAX_DIV(MAX_DIV)
    // ) u_rgb_blink (
    //     .clk        (clk_sys),
    //     .reset_n    (sys_reset_n),
    //     .taps       (taps),
    //     .r          (r),
    //     .g          (g),
    //     .b          (b)
    // );

    localparam [9:0] RGB_MAX = 10'd64;  

    rgb_pwm_fade #(
        .CLK_HZ     (CLK_SYS_HZ),
        .NTAPS      (NTAPS),
        .WIDTH      (WIDTH),
        .MAX_DIV    (MAX_DIV),
        .PWM_LIMIT  (RGB_MAX)
    ) u_rgb_pwm (
        .clk     (clk_sys),
        .reset_n (sys_reset_n),
        .taps    (taps),
        .r       (r),
        .g       (g),
        .b       (b)
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
        .PERIOD_US (1_000),
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
