module stepped_counter #(
    parameter integer CLK_HZ      = 12_000_000,
    parameter integer WIDTH       = 32,
    parameter integer NTAPS       = 6,
    parameter integer PERIOD_MS   = 1000,
    parameter integer MAX_DIV     = 255
)(
    input              clk,
    input  [NTAPS-1:0] taps,
    input  [3:0]       step,
    output reg [7:0]   ctr = 8'd0
);

    // ---------------------------------------------
    // Tap helpers (compile-time)
    // ---------------------------------------------
    function integer tap_bit;
        input integer i;
        begin
            tap_bit = (i * (WIDTH-1)) / (NTAPS-1);
        end
    endfunction

    function integer select_tap;
        input integer period_ms;
        integer i, hz, div;
        begin
            select_tap = 0;
            for (i = NTAPS-1; i >= 0; i = i - 1) begin
                hz  = CLK_HZ >> (tap_bit(i) + 1);
                div = (hz * period_ms) / 1000;
                if (div > 0 && div <= MAX_DIV)
                    select_tap = i;
            end
        end
    endfunction

    localparam integer TAP = select_tap(PERIOD_MS);
    localparam integer DIV =
        ((CLK_HZ >> (tap_bit(TAP)+1)) * PERIOD_MS) / 1000;

    // ---------------------------------------------
    // Local divider
    // ---------------------------------------------
    reg [$clog2(DIV)-1:0] div_cnt = 0;
    wire tick = (div_cnt == DIV-1);

    always @(posedge clk) begin
        if (taps[TAP]) begin
            if (tick)
                div_cnt <= 0;
            else
                div_cnt <= div_cnt + 1;
        end
    end

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
    always @(posedge clk) begin
        if (taps[TAP] && tick)
            ctr <= sum;
    end

endmodule
