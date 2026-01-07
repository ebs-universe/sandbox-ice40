// rgb_pwm_fade.v — CE-safe RGB PWM fade demo
module rgb_pwm_fade #(
    parameter integer CLK_HZ,

    parameter integer PWM_BITS    = 10,
    parameter integer PWM_FREQ_HZ = 2_000,

    // Fade times (0 → max) in ms
    parameter integer R_FADE_MS =  9_000,
    parameter integer G_FADE_MS = 13_000,
    parameter integer B_FADE_MS = 21_000,

    // Ramp update rate
    parameter integer UPDATE_US = 10_000,

    // Brightness cap
    parameter integer PWM_LIMIT = (1 << PWM_BITS) - 1,

    // timebase parameters
    parameter integer NTAPS,
    parameter integer WIDTH,
    parameter integer MAX_DIV
)(
    input  wire clk,
    input  wire reset_n,
    input  wire [NTAPS-1:0] taps,

    output wire r,
    output wire g,
    output wire b
);

    localparam integer PWM_PERIOD =
        CLK_HZ / PWM_FREQ_HZ - 1;

    // ------------------------------------------------------------
    // Update tick (data signal only)
    // ------------------------------------------------------------
    wire update_tick;

    periodic_tick #(
        .CLK_HZ    (CLK_HZ),
        .PERIOD_US (UPDATE_US),
        .NTAPS     (NTAPS),
        .WIDTH     (WIDTH),
        .MAX_DIV   (MAX_DIV)
    ) u_update (
        .clk     (clk),
        .reset_n (reset_n),
        .taps    (taps),
        .tick    (update_tick)
    );

    // ------------------------------------------------------------
    // Step sizes
    // ------------------------------------------------------------
    localparam integer R_STEPS = (R_FADE_MS * 1000) / UPDATE_US;
    localparam integer G_STEPS = (G_FADE_MS * 1000) / UPDATE_US;
    localparam integer B_STEPS = (B_FADE_MS * 1000) / UPDATE_US;

    localparam integer R_STEP = (PWM_LIMIT + R_STEPS - 1) / R_STEPS;
    localparam integer G_STEP = (PWM_LIMIT + G_STEPS - 1) / G_STEPS;
    localparam integer B_STEP = (PWM_LIMIT + B_STEPS - 1) / B_STEPS;

    // ------------------------------------------------------------
    // Duty + direction state
    // ------------------------------------------------------------
    reg [PWM_BITS-1:0] duty_r, duty_g, duty_b;
    reg                dir_r,  dir_g,  dir_b;

    reg [PWM_BITS-1:0] duty_r_n, duty_g_n, duty_b_n;
    reg                dir_r_n,  dir_g_n,  dir_b_n;

    // ------------------------------------------------------------
    // Next-state ramp logic (NO CE)
    // ------------------------------------------------------------
    always @(*) begin
        duty_r_n = duty_r;  dir_r_n = dir_r;
        duty_g_n = duty_g;  dir_g_n = dir_g;
        duty_b_n = duty_b;  dir_b_n = dir_b;

        if (update_tick) begin
            // R
            if (!dir_r) begin
                if (duty_r + R_STEP >= PWM_LIMIT) begin
                    duty_r_n = PWM_LIMIT;
                    dir_r_n  = 1'b1;
                end else
                    duty_r_n = duty_r + R_STEP;
            end else begin
                if (duty_r <= R_STEP) begin
                    duty_r_n = 0;
                    dir_r_n  = 1'b0;
                end else
                    duty_r_n = duty_r - R_STEP;
            end

            // G
            if (!dir_g) begin
                if (duty_g + G_STEP >= PWM_LIMIT) begin
                    duty_g_n = PWM_LIMIT;
                    dir_g_n  = 1'b1;
                end else
                    duty_g_n = duty_g + G_STEP;
            end else begin
                if (duty_g <= G_STEP) begin
                    duty_g_n = 0;
                    dir_g_n  = 1'b0;
                end else
                    duty_g_n = duty_g - G_STEP;
            end

            // B
            if (!dir_b) begin
                if (duty_b + B_STEP >= PWM_LIMIT) begin
                    duty_b_n = PWM_LIMIT;
                    dir_b_n  = 1'b1;
                end else
                    duty_b_n = duty_b + B_STEP;
            end else begin
                if (duty_b <= B_STEP) begin
                    duty_b_n = 0;
                    dir_b_n  = 1'b0;
                end else
                    duty_b_n = duty_b - B_STEP;
            end
        end
    end

    // ------------------------------------------------------------
    // Register ramp state (always update)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            duty_r <= 0; dir_r <= 0;
            duty_g <= 0; dir_g <= 0;
            duty_b <= 0; dir_b <= 0;
        end else begin
            duty_r <= duty_r_n; dir_r <= dir_r_n;
            duty_g <= duty_g_n; dir_g <= dir_g_n;
            duty_b <= duty_b_n; dir_b <= dir_b_n;
        end
    end

    // ------------------------------------------------------------
    // PWM bank
    // ------------------------------------------------------------
    wire [2:0] pwm_sig;

    pwm_bank #(
        .N_CH     (3),
        .CNT_BITS (PWM_BITS)
    ) u_pwm (
        .clk        (clk),
        .reset_n    (reset_n),
        .period     (PWM_PERIOD[PWM_BITS-1:0]),
        .duty       ({duty_b, duty_g, duty_r}),
        .enable_ch  (3'b111),
        .sync       (1'b0),
        .phase      ({PWM_BITS{1'b0}}),
        .use_phase  (1'b0),
        .pwm        (pwm_sig),
        .cycle_start()
    );

    assign r = pwm_sig[0];
    assign g = pwm_sig[1];
    assign b = pwm_sig[2];

endmodule
