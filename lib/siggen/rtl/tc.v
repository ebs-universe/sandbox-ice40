module tc #(
    parameter integer CNT_BITS = 10,
    parameter bit     UP_DOWN  = 0,
    parameter bit     HAS_SYNC = 0
)(
    input  wire                     clk,
    input  wire                     reset_n,

    input  wire [CNT_BITS-1:0]      period,

    input  wire                     sync,
    input  wire [CNT_BITS-1:0]      sync_value,

    output reg  [CNT_BITS-1:0]      cnt,
    output reg                      dir,
    output wire                     cycle_start
);

    // ------------------------------------------------------------
    // Latched period (safe update point)
    // ------------------------------------------------------------
    reg [CNT_BITS-1:0] period_r;

    assign cycle_start = (cnt == {CNT_BITS{1'b0}});

    always @(posedge clk) begin
        if (!reset_n)
            period_r <= {CNT_BITS{1'b0}};
        else if (cycle_start)
            period_r <= period;
    end

    // ------------------------------------------------------------
    // Counter core
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            cnt <= {CNT_BITS{1'b0}};
            dir <= 1'b0;

        end else if (HAS_SYNC && sync) begin
            cnt <= sync_value;
            dir <= 1'b0;

        end else if (UP_DOWN) begin
            if (!dir) begin
                if (cnt == period_r) begin
                    dir <= 1'b1;
                    cnt <= cnt - 1'b1;
                end else
                    cnt <= cnt + 1'b1;
            end else begin
                if (cnt == 0) begin
                    dir <= 1'b0;
                    cnt <= cnt + 1'b1;
                end else
                    cnt <= cnt - 1'b1;
            end
        end else begin
            if (cnt == period_r)
                cnt <= {CNT_BITS{1'b0}};
            else
                cnt <= cnt + 1'b1;
        end
    end

endmodule
