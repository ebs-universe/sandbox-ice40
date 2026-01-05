module pll #(
    // Default values should work for 12 MHz -> 25 MHz
    parameter integer DIVR          = 0,
    parameter integer DIVF          = 24,
    parameter integer DIVQ          = 3,
    parameter integer FILTER_RANGE  = 1
)(
    input  wire clk_in,     // raw clock pin
    output wire clk_out,    // system clock
    output wire pll_lock    // PLL locked
);

    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR         (DIVR[3:0]),
        .DIVF         (DIVF[6:0]),
        .DIVQ         (DIVQ[2:0]),
        .FILTER_RANGE (FILTER_RANGE[2:0])
    ) u_pll (
        .PACKAGEPIN (clk_in),
        .PLLOUTCORE (clk_out),
        .LOCK       (pll_lock),
        .RESETB     (1'b1),
        .BYPASS     (1'b0)
    );

endmodule
