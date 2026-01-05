module rgb_blink #(
    parameter integer CLK_HZ,
    parameter integer R_PERIOD_MS,
    parameter integer G_PERIOD_MS,
    parameter integer B_PERIOD_MS,
    parameter integer NTAPS,
    parameter integer WIDTH,
    parameter integer MAX_DIV
)(
    input  wire             clk,
    input  wire             reset_n,
    input  wire [NTAPS-1:0] taps,

    output reg              r = 0,
    output reg              g = 0,
    output reg              b = 0
);

    wire r_tick;
    wire g_tick;
    wire b_tick;

    periodic_tick #(
        .CLK_HZ(CLK_HZ),
        .PERIOD_MS(R_PERIOD_MS),
        .WIDTH(WIDTH),
        .NTAPS(NTAPS),
        .MAX_DIV(MAX_DIV)
    ) u_tick_r (
        .clk        (clk),
        .reset_n    (reset_n),
        .taps       (taps),
        .tick       (r_tick)
    );

    periodic_tick #(
        .CLK_HZ(CLK_HZ),
        .PERIOD_MS(G_PERIOD_MS),
        .WIDTH(WIDTH),
        .NTAPS(NTAPS),
        .MAX_DIV(MAX_DIV)
    ) u_tick_g (
        .clk        (clk),
        .reset_n    (reset_n),
        .taps       (taps),
        .tick       (g_tick)
    );

    periodic_tick #(
        .CLK_HZ(CLK_HZ),
        .PERIOD_MS(B_PERIOD_MS),
        .WIDTH(WIDTH),
        .NTAPS(NTAPS),
        .MAX_DIV(MAX_DIV)
    ) u_tick_b (
        .clk        (clk),
        .reset_n    (reset_n),
        .taps       (taps),
        .tick       (b_tick)
    );

    reg r_tick_d, g_tick_d, b_tick_d;

    always @(posedge clk) begin
        if (reset_n == 0) begin
            r_tick_d <= 0;
            g_tick_d <= 0;
            b_tick_d <= 0;
        end else begin
            r_tick_d <= r_tick;
            g_tick_d <= g_tick;
            b_tick_d <= b_tick;
        end
    end

    always @(posedge clk) begin
        if (reset_n == 0) begin
            r <= 0;
            g <= 0;
            b <= 0;
        end else begin
            r <= r_tick_d ? ~r : r;
            g <= g_tick_d ? ~g : g;
            b <= b_tick_d ? ~b : b;
        end
    end

endmodule
