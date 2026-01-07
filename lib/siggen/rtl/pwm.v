// pwm.v — single-channel PWM (CE-safe, bank-aligned)
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
    // Duty register and next-state logic (NO clock enable)
    // ------------------------------------------------------------
    reg [CNT_BITS-1:0] duty_r;
    reg [CNT_BITS-1:0] duty_next;

    always @(*) begin
        duty_next = duty_r;

        if (cycle_start) begin
            if (duty > period)
                duty_next = period;
            else
                duty_next = duty;
        end
    end

    // ------------------------------------------------------------
    // Register duty (always update)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n)
            duty_r <= {CNT_BITS{1'b0}};
        else
            duty_r <= duty_next;
    end

    // ------------------------------------------------------------
    // PWM compare (combinational)
    // ------------------------------------------------------------
    wire pwm_raw =
        enable &&
        (cnt < duty_r);

    // ------------------------------------------------------------
    // Register PWM output (break routing / fanout)
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
