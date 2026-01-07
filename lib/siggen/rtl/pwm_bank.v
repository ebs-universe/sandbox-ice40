module pwm_bank #(
    parameter integer N_CH           = 3,
    parameter integer CNT_BITS       = 10,

    // Feature switches
    parameter bit     PHASE_CORRECT  = 0,  // up/down carrier
    parameter bit     HAS_PHASE_CTRL = 0,  // bank-level phase sync
    parameter bit     HAS_CH_PHASE   = 0   // per-channel fixed phase offset
)(
    input  wire                         clk,
    input  wire                         reset_n,

    // Carrier configuration
    input  wire [CNT_BITS-1:0]          period,

    // Duty inputs (packed)
    input  wire [N_CH*CNT_BITS-1:0]     duty,
    input  wire [N_CH-1:0]              enable_ch,

    // Optional bank-level phase control
    input  wire                         sync,
    input  wire [CNT_BITS-1:0]          phase,
    input  wire                         use_phase,

    // Optional per-channel phase offsets (packed)
    input  wire [N_CH*CNT_BITS-1:0]     ch_phase,

    // Outputs
    output wire [N_CH-1:0]              pwm,
    output wire                         cycle_start
);

    // ------------------------------------------------------------
    // Shared timer / carrier
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
        .sync        (HAS_PHASE_CTRL && sync),
        .sync_value  (use_phase ? phase : {CNT_BITS{1'b0}}),
        .cnt         (cnt),
        .dir         (dir),
        .cycle_start (cycle_start)
    );

    // ------------------------------------------------------------
    // Duty registers (always clocked, no CE)
    // ------------------------------------------------------------
    reg [CNT_BITS-1:0] duty_r [N_CH-1:0];
    integer i;

    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < N_CH; i = i + 1)
                duty_r[i] <= {CNT_BITS{1'b0}};
        end else begin
            for (i = 0; i < N_CH; i = i + 1)
                duty_r[i] <= duty[i*CNT_BITS +: CNT_BITS];
        end
    end

    // ------------------------------------------------------------
    // Effective counter per channel (phase-offset compare)
    // ------------------------------------------------------------
    wire [CNT_BITS-1:0] cnt_eff [N_CH-1:0];

    genvar k;
    generate
        for (k = 0; k < N_CH; k = k + 1) begin : GEN_PHASE
            if (HAS_CH_PHASE) begin
                // Wrap-safe subtract: (cnt - phase) mod period
                assign cnt_eff[k] =
                    (cnt >= ch_phase[k*CNT_BITS +: CNT_BITS]) ?
                        (cnt - ch_phase[k*CNT_BITS +: CNT_BITS]) :
                        (cnt + period - ch_phase[k*CNT_BITS +: CNT_BITS]);
            end else begin
                assign cnt_eff[k] = cnt;
            end
        end
    endgenerate

    // ------------------------------------------------------------
    // Compare
    // ------------------------------------------------------------
    wire [N_CH-1:0] pwm_raw;

    generate
        for (k = 0; k < N_CH; k = k + 1) begin : GEN_PWM
            assign pwm_raw[k] =
                enable_ch[k] &&
                (cnt_eff[k] < duty_r[k]);
        end
    endgenerate

    // ------------------------------------------------------------
    // Registered outputs (timing-critical)
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
