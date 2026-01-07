// ramp_step.v — single-step bidirectional ramp kernel
// Purely synchronous, tick-driven, no counters, no clocks, no combinational outputs
module ramp_step #(
    parameter integer BITS = 10
)(
    input  wire              clk,
    input  wire              reset_n,
    input  wire              step_en,   // 1-cycle pulse

    input  wire [BITS-1:0]   q,         // quantum
    input  wire [BITS-1:0]   max_val,

    input  wire              dir_in,
    input  wire [BITS-1:0]   val_in,

    input  wire              hit_max,
    input  wire              hit_min,

    output reg               dir_out,
    output reg  [BITS-1:0]   val_out
);

    always @(posedge clk) begin
        if (!reset_n) begin
            dir_out <= 1'b0;
            val_out <= {BITS{1'b0}};
        end else if (step_en) begin
            if (!dir_in) begin
                if (hit_max) begin
                    val_out <= max_val;
                    dir_out <= 1'b1;
                end else begin
                    val_out <= val_in + q;
                    dir_out <= dir_in;
                end
            end else begin
                if (hit_min) begin
                    val_out <= {BITS{1'b0}};
                    dir_out <= 1'b0;
                end else begin
                    val_out <= val_in - q;
                    dir_out <= dir_in;
                end
            end
        end
    end

endmodule
