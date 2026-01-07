// tc.v — generic timer / counter (safe-latched period, equality compare)
module tc #(
    parameter integer CNT_BITS = 12,
    parameter bit     UP_DOWN  = 0,  // 0 = up only, 1 = up/down
    parameter bit     HAS_SYNC = 0   // 1 = enable sync input
)(
    input  wire                     clk,
    input  wire                     reset_n,

    // Runtime configuration
    input  wire [CNT_BITS-1:0]      period,

    // Optional sync / phase control
    input  wire                     sync,
    input  wire [CNT_BITS-1:0]      sync_value,

    // Outputs
    output reg  [CNT_BITS-1:0]      cnt,
    output reg                      dir,          // valid if UP_DOWN=1
    output wire                     cycle_start
);

    // ------------------------------------------------------------
    // Latched period (only updates at safe boundary)
    // ------------------------------------------------------------
    reg [CNT_BITS-1:0] period_r;

    // registered cycle_start (breaks cnt → CE path)
    reg cycle_start_r;

    always @(posedge clk) begin
        if (!reset_n)
            cycle_start_r <= 1'b0;
        else
            cycle_start_r <= (cnt == {CNT_BITS{1'b0}});
    end

    assign cycle_start = cycle_start_r;

    // latch period using data mux, not CE
    always @(posedge clk) begin
        if (!reset_n)
            period_r <= {CNT_BITS{1'b0}};
        else
            period_r <= cycle_start_r ? period : period_r;
    end

    // ------------------------------------------------------------
    // Counter logic
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            cnt <= {CNT_BITS{1'b0}};
            dir <= 1'b0;

        end else if (HAS_SYNC && sync) begin
            // Immediate phase realignment
            cnt <= sync_value;
            dir <= 1'b0;

        end else begin
            if (UP_DOWN) begin
                // ------------------------------------------------
                // Up / down (triangle)
                // ------------------------------------------------
                if (!dir) begin
                    // counting up
                    if (cnt == period_r) begin
                        dir <= 1'b1;
                        cnt <= cnt - 1'b1;
                    end else begin
                        cnt <= cnt + 1'b1;
                    end
                end else begin
                    // counting down
                    if (cnt == 0) begin
                        dir <= 1'b0;
                        cnt <= cnt + 1'b1;
                    end else begin
                        cnt <= cnt - 1'b1;
                    end
                end
            end else begin
                // ------------------------------------------------
                // Up only (sawtooth)
                // ------------------------------------------------
                if (cnt == period_r)
                    cnt <= {CNT_BITS{1'b0}};
                else
                    cnt <= cnt + 1'b1;
            end
        end
    end

endmodule
