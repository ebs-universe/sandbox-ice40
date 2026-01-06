// ------------------------------------------------------------
// High-Frequency Internal Oscillator (SB_HFOSC)
// ------------------------------------------------------------
module hfosc #(
    // 0 = 48 MHz
    // 1 = 24 MHz
    // 2 = 12 MHz
    // 3 = 6 MHz
    parameter integer DIV = 0,
    parameter integer ENABLED = 1
)(
    output wire clk_out
);

    // Convert integer selector to required STRING
    localparam CLKHF_DIV_STR =
        (DIV == 0) ? "0b00" :
        (DIV == 1) ? "0b01" :
        (DIV == 2) ? "0b10" :
                     "0b11" ;

    SB_HFOSC #(
        .CLKHF_DIV (CLKHF_DIV_STR)
    ) u_hfosc (
        .CLKHFPU (ENABLED ? 1'b1 : 1'b0),
        .CLKHFEN (ENABLED ? 1'b1 : 1'b0),
        .CLKHF   (clk_out)
    );

endmodule
