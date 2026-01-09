// ------------------------------------------------------------
// uart_baudgen.v — Baud generator with external phase reset
// ------------------------------------------------------------
// Generates a 1-cycle CE pulse at RATE_HZ.
// phase_reset allows RX to realign sampling to a start bit.
// ------------------------------------------------------------

module uart_baudgen #(
    parameter integer CLK_HZ  = 48_000_000,
    parameter integer RATE_HZ = 1_000_000
)(
    input  wire clk,
    input  wire reset_n,

    input  wire phase_reset,   // NEW: synchronous phase reset
    output reg  ce              // 1-cycle pulse @ RATE_HZ
);

    localparam integer DIV   = CLK_HZ / RATE_HZ;
    localparam integer DIV_W = $clog2(DIV);

    reg [DIV_W-1:0] div_cnt;

    always @(posedge clk) begin
        if (!reset_n || phase_reset) begin
            div_cnt <= {DIV_W{1'b0}};
            ce      <= 1'b0;
        end else begin
            if (div_cnt == DIV-1) begin
                div_cnt <= {DIV_W{1'b0}};
                ce      <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 1'b1;
                ce      <= 1'b0;
            end
        end
    end

endmodule
