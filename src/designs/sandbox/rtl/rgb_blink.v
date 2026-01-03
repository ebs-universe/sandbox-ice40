module rgb_blink #(
    parameter integer R_PERIOD = 10, // 10 × 100ms = 1.0s
    parameter integer G_PERIOD = 6,  // 600ms
    parameter integer B_PERIOD = 2   // 200ms
)(
    input  clk,
    input  tick_100ms,

    output reg r,
    output reg g,
    output reg b
);
    localparam integer RW = $clog2(R_PERIOD);
    localparam integer GW = $clog2(G_PERIOD);
    localparam integer BW = $clog2(B_PERIOD);

    reg [RW-1:0] r_cnt;
    reg [GW-1:0] g_cnt;
    reg [BW-1:0] b_cnt;

    always @(posedge clk) begin
        if (tick_100ms) begin
            // Red
            if (r_cnt == R_PERIOD-1) begin
                r_cnt <= 0;
                r <= ~r;
            end else
                r_cnt <= r_cnt + 1;

            // Green
            if (g_cnt == G_PERIOD-1) begin
                g_cnt <= 0;
                g <= ~g;
            end else
                g_cnt <= g_cnt + 1;

            // Blue
            if (b_cnt == B_PERIOD-1) begin
                b_cnt <= 0;
                b <= ~b;
            end else
                b_cnt <= b_cnt + 1;
        end
    end
endmodule
