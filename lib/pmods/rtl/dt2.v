module pmod_dt2 #(
    // Dual-mode control
    parameter bit USE_EXTERNAL_TICK = 0,

    // Internal refresh configuration (used only if internal)
    parameter integer CLK_HZ,
    parameter integer PERIOD_US = 1_000,
    parameter integer NTAPS,
    parameter integer WIDTH,
    parameter integer MAX_DIV
)(
    input  wire        clk,
    input  wire        reset_n,

    // timebase taps (only required if internal tick is used)
    input  wire [NTAPS-1:0] taps,

    // display value
    input  wire [7:0]  val,

    // external refresh tick (1-cycle pulse, synchronous to clk)
    input  wire        refresh_tick,

    // PMOD DT2 pins
    output wire DT2_A,
    output wire DT2_B,
    output wire DT2_C,
    output wire DT2_D,
    output wire DT2_E,
    output wire DT2_F,
    output wire DT2_G,
    output wire DT2_SEL
);

    // ============================================================
    // Refresh tick selection
    // ============================================================

    wire tick_int;
    wire tick;

    generate
        if (USE_EXTERNAL_TICK) begin : g_ext_tick
            assign tick = refresh_tick;
        end else begin : g_int_tick

            periodic_tick #(
                .CLK_HZ    (CLK_HZ),
                .PERIOD_US (PERIOD_US),
                .NTAPS     (NTAPS),
                .WIDTH     (WIDTH),
                .MAX_DIV   (MAX_DIV)
            ) u_refresh (
                .clk     (clk),
                .reset_n (reset_n),
                .taps    (taps),
                .tick    (tick_int)
            );

            assign tick = tick_int;
        end
    endgenerate

    // ============================================================
    // Digit select (toggles on refresh tick)
    // ============================================================

    reg digit_sel;

    always @(posedge clk) begin
        if (!reset_n)
            digit_sel <= 1'b0;
        else if (tick)
            digit_sel <= ~digit_sel;
    end

    // Physical digit select (matches DT2 polarity)
    wire phys_sel = ~digit_sel;
    assign DT2_SEL = phys_sel;

    // ============================================================
    // Nibble select (pure combinational)
    // ============================================================

    wire [3:0] nibble =
        phys_sel ? val[3:0] : val[7:4];

    // ============================================================
    // Hex → 7-segment decode (active LOW)
    // seg = {g,f,e,d,c,b,a}
    // ============================================================

    reg [6:0] seg;

    always @(*) begin
        case (nibble)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end

    // ============================================================
    // Segment pin mapping
    // ============================================================

    assign {
        DT2_G,
        DT2_F,
        DT2_E,
        DT2_D,
        DT2_C,
        DT2_B,
        DT2_A
    } = seg;

endmodule
