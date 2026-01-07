module pwm_bank #(
    parameter integer N_CH           = 3,
    parameter integer CNT_BITS       = 12,
    parameter bit     PHASE_CORRECT  = 1,
    parameter bit     HAS_PHASE_CTRL = 0
)(
    input  wire                         clk,
    input  wire                         reset_n,

    // Shared carrier configuration
    input  wire [CNT_BITS-1:0]          period,

    // Per-channel duty and enable (packed)
    input  wire [N_CH*CNT_BITS-1:0]     duty,
    input  wire [N_CH-1:0]              enable_ch,

    // Optional phase control
    input  wire                         sync,
    input  wire [CNT_BITS-1:0]          phase,
    input  wire                         use_phase,

    // Outputs
    output wire [N_CH-1:0]              pwm,
    output wire                         cycle_start
);

    // ------------------------------------------------------------
    // Shared timer / counter
    // ------------------------------------------------------------
    wire [CNT_BITS-1:0] cnt;
    wire                dir;

    tc #(
        .CNT_BITS (CNT_BITS),
        .UP_DOWN  (PHASE_CORRECT),
        .HAS_SYNC (HAS_PHASE_CTRL)
    ) u_tc (
        .clk         (clk),
        .reset_n     (reset_n),
        .period      (period),
        .sync        (sync),
        .sync_value  (use_phase ? phase : {CNT_BITS{1'b0}}),
        .cnt         (cnt),
        .dir         (dir),
        .cycle_start (cycle_start)
    );

    // ------------------------------------------------------------
    // Duty registers (one per channel)
    // ------------------------------------------------------------
    reg [CNT_BITS-1:0] duty_r     [N_CH];
    reg [CNT_BITS-1:0] duty_next  [N_CH];

    integer i;

    // ------------------------------------------------------------
    // Next-state duty logic (NO clock enable)
    // ------------------------------------------------------------
    always @(*) begin
        for (i = 0; i < N_CH; i = i + 1) begin
            duty_next[i] = duty_r[i];

            if (cycle_start) begin
                if (duty[i*CNT_BITS +: CNT_BITS] > period)
                    duty_next[i] = period;
                else
                    duty_next[i] = duty[i*CNT_BITS +: CNT_BITS];
            end
        end
    end

    // ------------------------------------------------------------
    // Register duties (always update)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < N_CH; i = i + 1)
                duty_r[i] <= {CNT_BITS{1'b0}};
        end else begin
            for (i = 0; i < N_CH; i = i + 1)
                duty_r[i] <= duty_next[i];
        end
    end

    // ------------------------------------------------------------
    // PWM compare (combinational)
    // ------------------------------------------------------------
    wire [N_CH-1:0] pwm_raw;

    genvar k;
    generate
        for (k = 0; k < N_CH; k = k + 1) begin : gen_pwm
            assign pwm_raw[k] =
                enable_ch[k] &&
                (cnt < duty_r[k]);
        end
    endgenerate

    // ------------------------------------------------------------
    // Register PWM outputs (break long routing)
    // ------------------------------------------------------------
    reg [N_CH-1:0] pwm_r;

    always @(posedge clk) begin
        if (!reset_n)
            pwm_r <= {N_CH{1'b0}};
        else
            pwm_r <= pwm_raw;
    end

    assign pwm = pwm_r;

endmodule
