// ------------------------------------------------------------
// ~10 kHz Low-Frequency Internal Oscillator (SB_LFOSC)
// ------------------------------------------------------------
module lfosc #(
    parameter integer ENABLED = 1
)(
    output wire clk_out
);

    SB_LFOSC u_lfosc (
        .CLKLFPU (ENABLED ? 1'b1 : 1'b0), // power up
        .CLKLFEN (ENABLED ? 1'b1 : 1'b0), // enable
        .CLKLF   (clk_out)
    );

endmodule
