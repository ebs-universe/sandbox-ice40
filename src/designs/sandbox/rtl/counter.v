module stepped_counter #(
    parameter integer CLK_HZ      = 12_000_000,
    parameter integer WIDTH       = 27,
    parameter integer NTAPS       = 6,
    parameter integer PERIOD_MS   = 1000,
    parameter integer MAX_DIV     = 255
)(
    input              clk,
    input              reset_n,
    input  [NTAPS-1:0] taps,
    input  [3:0]       step,
    output reg [7:0]   ctr = 8'd0
);

    wire tick;

    periodic_tick #(
        .CLK_HZ(CLK_HZ),
        .WIDTH(WIDTH),
        .NTAPS(NTAPS),
        .PERIOD_MS(PERIOD_MS),
        .MAX_DIV(MAX_DIV)
    ) u_timer (
        .clk(clk),
        .taps(taps),
        .tick(tick)
    );

    // ---------------------------------------------
    // Adder
    // ---------------------------------------------
    wire [7:0] sum;

    adder8_4 u_add (
        .a(ctr),
        .b(step),
        .y(sum)
    );

    // ---------------------------------------------
    // Register update
    // ---------------------------------------------

    reg tick_d;

    always @(posedge clk)
        if (!reset_n)
            tick_d <= 0;
        else
            tick_d <= tick;

    always @(posedge clk)
        if (!reset_n)
            ctr <= 8'd0;
        else
            ctr <= tick_d ? sum : ctr;    

endmodule