module rgb_blink #(
    parameter integer CLK_HZ      = 12_000_000,
    parameter integer WIDTH       = 27,
    parameter integer NTAPS       = 6,

    parameter integer R_PERIOD_MS = 1000,
    parameter integer G_PERIOD_MS = 700,
    parameter integer B_PERIOD_MS = 300,

    parameter integer MAX_DIV     = 255
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
        .WIDTH(WIDTH),
        .NTAPS(NTAPS),
        .PERIOD_MS(R_PERIOD_MS),
        .MAX_DIV(MAX_DIV)
    ) u_tick_r (
        .clk(clk),
        .taps(taps),
        .tick(r_tick)
    );

    periodic_tick #(
        .CLK_HZ(CLK_HZ),
        .WIDTH(WIDTH),
        .NTAPS(NTAPS),
        .PERIOD_MS(G_PERIOD_MS),
        .MAX_DIV(MAX_DIV)
    ) u_tick_g (
        .clk(clk),
        .taps(taps),
        .tick(g_tick)
    );

    periodic_tick #(
        .CLK_HZ(CLK_HZ),
        .WIDTH(WIDTH),
        .NTAPS(NTAPS),
        .PERIOD_MS(B_PERIOD_MS),
        .MAX_DIV(MAX_DIV)
    ) u_tick_b (
        .clk(clk),
        .taps(taps),
        .tick(b_tick)
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
