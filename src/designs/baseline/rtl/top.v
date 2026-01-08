module top #(
    parameter integer CLK_HZ        = 12_000_000,
    parameter integer CLK_HFINT_HZ  = 24_000_000,
    parameter integer CLK_LFINT_HZ  = 10_000,
    parameter integer CLK_SYS_HZ    = 48_000_000,
    parameter integer NTAPS         = 6,
    parameter integer WIDTH         = 27,
    parameter integer MAX_DIV       = 255
)(
    input  CLK,
);

    // ============================================================
    // System
    // ============================================================
    
    wire clk_sys;
    wire pll_lock;
        
    pll #(
        .DIVR (0),
        .DIVF (63),
        .DIVQ (4)
    ) u_pll (
        .clk_in   (CLK),
        .clk_out  (clk_sys),
        .pll_lock (pll_lock)
    );
    
    wire sys_reset_n;

    reset u_reset (
        .clk         (clk_sys),
        .pll_lock    (pll_lock),
        .ext_reset_n (1'b1),
        .reset_n     (sys_reset_n)
    );

    wire [26:0] ticks;
    wire [(NTAPS-1):0]  taps;
    
    timebase #(
        .NTAPS(NTAPS)
    ) u_timebase (
        .clk     (clk_sys),
        .reset_n (sys_reset_n),
        .ticks   (ticks),
        .taps    (taps)
    );

    reg r1;
    reg r2;
    wire lut_out;

    // Explicit LUT to force an interior timing path
    (* keep *)
    SB_LUT4 #(
        .LUT_INIT(16'hAAAA)   // simple pass-through / invert pattern
    ) u_lut (
        .I0(r1),
        .I1(1'b0),
        .I2(1'b0),
        .I3(1'b0),
        .O(lut_out)
    );

    always @(posedge CLK) begin
        r1 <= ~r1;
        r2 <= lut_out;
    end

endmodule
