// pwm.v — single-channel PWM (bank-structured, timing-safe)
module pwm #(
    parameter integer CNT_BITS       = 12,
    parameter bit     PHASE_CORRECT  = 1,
    parameter bit     HAS_PHASE_CTRL = 0
)(
    input  wire                     clk,
    input  wire                     reset_n,

    // Carrier configuration
    input  wire [CNT_BITS-1:0]      period,

    // Duty and enable
    input  wire [CNT_BITS-1:0]      duty,
    input  wire                     enable,

    // Optional phase control
    input  wire                     sync,
    input  wire [CNT_BITS-1:0]      phase,
    input  wire                     use_phase,

    // Outputs
    output wire                     pwm,
    output wire                     cycle_start
);

    // ------------------------------------------------------------
    // Shared carrier (identical to pwm_bank_base)
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
    // Duty register (always clocked, clamp at cycle boundary)
    // ------------------------------------------------------------
    reg [CNT_BITS-1:0] duty_r;

    always @(posedge clk) begin
        if (!reset_n)
            duty_r <= {CNT_BITS{1'b0}};
        else if (cycle_start) begin
            if (duty > period)
                duty_r <= period;
            else
                duty_r <= duty;
        end
    end

    // ------------------------------------------------------------
    // Compare (purely combinational)
    // ------------------------------------------------------------
    wire pwm_raw =
        enable &&
        (cnt < duty_r);

    // ------------------------------------------------------------
    // Registered output (timing-critical)
    // ------------------------------------------------------------
    reg pwm_r;

    always @(posedge clk) begin
        if (!reset_n)
            pwm_r <= 1'b0;
        else
            pwm_r <= pwm_raw;
    end

    assign pwm = pwm_r;

endmodule
