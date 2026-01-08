// rgb_pwm_fade.v — tc + pwm_bank validation workload
// Version with pipelined ramp comparison (A. Split comparison from update)

module rgb_pwm_fade #(
    parameter integer CLK_HZ,

    // PWM parameters
    parameter integer PWM_BITS    = 10,
    parameter integer PWM_FREQ_HZ = 2_000,

    // Fade times (0 → max) in milliseconds
    parameter integer R_FADE_MS =  3_000,
    parameter integer G_FADE_MS =  4_330,
    parameter integer B_FADE_MS =  7_000,

    // Update cadence (human-scale)
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

    // ------------------------------------------------------------
    // PWM carrier period
    // ------------------------------------------------------------
    localparam integer PWM_PERIOD =
        CLK_HZ / PWM_FREQ_HZ - 1;

    // ------------------------------------------------------------
    // Slow update tick (data signal, NOT a clock)
    // ------------------------------------------------------------
    wire update_tick_raw;
    reg  update_tick;

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
        .tick    (update_tick_raw)
    );

    always @(posedge clk) begin
        if (!reset_n)
            update_tick <= 1'b0;
        else
            update_tick <= update_tick_raw;
    end

    // ------------------------------------------------------------
    // Fixed-amplitude quantum
    // ------------------------------------------------------------
    localparam integer RAMP_STEPS = 20;

    localparam integer Q =
        (PWM_LIMIT + RAMP_STEPS - 1) / RAMP_STEPS;

    localparam integer Q_SAFE = (Q < 1) ? 1 : Q;

    // ------------------------------------------------------------
    // Per-color cadence divisors
    // ------------------------------------------------------------
    localparam integer R_DIV = (R_FADE_MS * 1000) / (UPDATE_US * RAMP_STEPS);
    localparam integer G_DIV = (G_FADE_MS * 1000) / (UPDATE_US * RAMP_STEPS);
    localparam integer B_DIV = (B_FADE_MS * 1000) / (UPDATE_US * RAMP_STEPS);

    localparam integer R_DIV_S = (R_DIV < 1) ? 1 : R_DIV;
    localparam integer G_DIV_S = (G_DIV < 1) ? 1 : G_DIV;
    localparam integer B_DIV_S = (B_DIV < 1) ? 1 : B_DIV;

    // ------------------------------------------------------------
    // Ramp state
    // ------------------------------------------------------------
    reg [PWM_BITS-1:0] duty_r, duty_g, duty_b;
    reg                dir_r,  dir_g,  dir_b;

    reg [$clog2(R_DIV_S):0] r_cnt;
    reg [$clog2(G_DIV_S):0] g_cnt;
    reg [$clog2(B_DIV_S):0] b_cnt;

    // ------------------------------------------------------------
    // Stage 1: boundary detection (PIPELINED)
    // ------------------------------------------------------------
    reg hit_r, hit_g, hit_b;
    reg hit_r_min, hit_g_min, hit_b_min;

    always @(posedge clk) begin
        if (!reset_n) begin
            hit_r     <= 1'b0; hit_r_min <= 1'b0;
            hit_g     <= 1'b0; hit_g_min <= 1'b0;
            hit_b     <= 1'b0; hit_b_min <= 1'b0;
        end else if (update_tick) begin
            hit_r     <= (!dir_r) && (duty_r + Q_SAFE >= PWM_LIMIT);
            hit_r_min <= ( dir_r) && (duty_r <= Q_SAFE);

            hit_g     <= (!dir_g) && (duty_g + Q_SAFE >= PWM_LIMIT);
            hit_g_min <= ( dir_g) && (duty_g <= Q_SAFE);

            hit_b     <= (!dir_b) && (duty_b + Q_SAFE >= PWM_LIMIT);
            hit_b_min <= ( dir_b) && (duty_b <= Q_SAFE);
        end
    end

    // ------------------------------------------------------------
    // Stage 2: ramp update (via ramp_step)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            r_cnt <= 0;
            g_cnt <= 0;
            b_cnt <= 0;
        end else if (update_tick) begin
            r_cnt <= (r_cnt == R_DIV_S-1) ? 0 : r_cnt + 1'b1;
            g_cnt <= (g_cnt == G_DIV_S-1) ? 0 : g_cnt + 1'b1;
            b_cnt <= (b_cnt == B_DIV_S-1) ? 0 : b_cnt + 1'b1;
        end
    end

    reg step_r;

    always @(posedge clk) begin
        if (!reset_n)
            step_r <= 1'b0;
        else
            step_r <= update_tick && (r_cnt == R_DIV_S-1);
    end

    reg step_g;

    always @(posedge clk) begin
        if (!reset_n)
            step_g <= 1'b0;
        else
            step_g <= update_tick && (g_cnt == G_DIV_S-1);
    end
    
    reg step_b;

    always @(posedge clk) begin
        if (!reset_n)
            step_b <= 1'b0;
        else
            step_b <= update_tick && (b_cnt == B_DIV_S-1);
    end

    ramp_step #(.BITS(PWM_BITS)) u_ramp_r (
        .clk     (clk),
        .reset_n (reset_n),
        .step_en (step_r),
        .q       (Q_SAFE),
        .max_val (PWM_LIMIT),
        .dir_in  (dir_r),
        .val_in  (duty_r),
        .hit_max (hit_r),
        .hit_min (hit_r_min),
        .dir_out (dir_r),
        .val_out (duty_r)
    );

    ramp_step #(.BITS(PWM_BITS)) u_ramp_g (
        .clk     (clk),
        .reset_n (reset_n),
        .step_en (step_g),
        .q       (Q_SAFE),
        .max_val (PWM_LIMIT),
        .dir_in  (dir_g),
        .val_in  (duty_g),
        .hit_max (hit_g),
        .hit_min (hit_g_min),
        .dir_out (dir_g),
        .val_out (duty_g)
    );

    ramp_step #(.BITS(PWM_BITS)) u_ramp_b (
        .clk     (clk),
        .reset_n (reset_n),
        .step_en (step_b),
        .q       (Q_SAFE),
        .max_val (PWM_LIMIT),
        .dir_in  (dir_b),
        .val_in  (duty_b),
        .hit_max (hit_b),
        .hit_min (hit_b_min),
        .dir_out (dir_b),
        .val_out (duty_b)
    );

    // ------------------------------------------------------------
    // PWM bank (unchanged)
    // ------------------------------------------------------------
    wire [2:0] pwm_sig;

    pwm_bank #(
        .N_CH           (3),
        .CNT_BITS       (PWM_BITS),
        .PHASE_CORRECT  (1'b0),
        .HAS_PHASE_CTRL (1'b0),
        .HAS_CH_PHASE   (1'b0)
    ) u_pwm (
        .clk        (clk),
        .reset_n    (reset_n),
        .period     (PWM_PERIOD[PWM_BITS-1:0]),
        .duty       ({duty_b, duty_g, duty_r}),
        .enable_ch  (3'b111),
        .sync       (1'b0),
        .phase      ({PWM_BITS{1'b0}}),
        .use_phase  (1'b0),
        .ch_phase   ({3*PWM_BITS{1'b0}}),
        .pwm        (pwm_sig),
        .cycle_start()
    );

    assign r = pwm_sig[0];
    assign g = pwm_sig[1];
    assign b = pwm_sig[2];

endmodule
