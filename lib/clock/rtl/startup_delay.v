// ------------------------------------------------------------
// startup_delay.v — latched startup delay with clean edge
// ------------------------------------------------------------
//
// PURPOSE
// -------
// Convert a slow periodic tick (typically 1 Hz) into a
// *one-shot startup enable* signal with a clean rising edge.
//
// This module is intentionally simple and conservative.
// It is designed to be rock-solid at reset and immune to
// refactoring mistakes.
//
//
// BEHAVIOR
// --------
// 1. After reset, `enable` is LOW
// 2. Each `tick` increments an internal counter
// 3. When the counter reaches DELAY_TICKS:
//      - `enable` goes HIGH
//      - `enable` stays HIGH forever
// 4. `enable_rise` pulses HIGH for exactly ONE clock cycle
//    when `enable` first transitions 0 -> 1
//
//
// DESIGN RULES (IMPORTANT)
// ------------------------
// * `enable` is a LEVEL, not a pulse
// * `enable_rise` is the ONLY event trigger
// * `tick` MUST be a one-cycle pulse
// * This module MUST NOT be modified casually
//
// If you break any of the above, downstream FSMs WILL fail.
//
//
// TYPICAL USAGE
// -------------
//
//   wire startup_en;
//   wire startup_en_rise;
//
//   startup_delay #(
//       .DELAY_TICKS(3)          // wait 3 ticks
//   ) u_delay (
//       .clk         (clk),
//       .reset_n     (reset_n),
//       .tick        (sec_tick), // 1 Hz pulse
//       .enable      (startup_en),
//       .enable_rise (startup_en_rise)
//   );
//
//   // Arm a one-shot FSM
//   if (startup_en_rise) begin
//       fsm_start <= 1'b1;
//   end
//
//
// DEBUGGING
// ---------
// You can safely:
//   - put `enable` on an LED
//   - put `enable_rise` on a pulse LED
//   - observe the counter on LEDs
//
// You should NEVER:
//   - gate `tick`
//   - reassign `enable` elsewhere
//   - use `enable` as a trigger instead of `enable_rise`
//
// ------------------------------------------------------------

module startup_delay #(
    // Number of tick pulses to wait before enabling
    // Example:
    //   tick = 1 Hz
    //   DELAY_TICKS = 3
    //   -> enable after ~3 seconds
    parameter integer DELAY_TICKS = 3
)(
    input  wire clk,
    input  wire reset_n,

    // One-cycle periodic pulse (e.g. 1 Hz)
    input  wire tick,

    // LEVEL output: goes high once and stays high
    output reg  enable,

    // EDGE output: one-cycle pulse when enable rises
    output wire enable_rise
);

    // --------------------------------------------------------
    // Internal counter
    // Width chosen to safely hold DELAY_TICKS
    // --------------------------------------------------------
    reg [$clog2(DELAY_TICKS+1)-1:0] cnt;

    // --------------------------------------------------------
    // Delay + latch logic
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            cnt    <= 0;
            enable <= 1'b0;
        end else if (tick) begin
            // Only count until enable latches
            if (!enable) begin
                if (cnt == DELAY_TICKS-1) begin
                    enable <= 1'b1;   // latch permanently
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end
    end

    // --------------------------------------------------------
    // Rising edge detector for enable
    // --------------------------------------------------------
    reg enable_d;

    always @(posedge clk) begin
        if (!reset_n)
            enable_d <= 1'b0;
        else
            enable_d <= enable;
    end

    assign enable_rise = enable & ~enable_d;

endmodule
