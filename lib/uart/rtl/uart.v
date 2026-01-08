// uart.v — UART wrapper (TX implemented, RX placeholder)
module uart #(
    parameter integer CLK_HZ = 48_000_000,
    parameter integer BAUD   = 1_000_000
)(
    input  wire clk,
    input  wire reset_n,

    // -------------------------
    // TX interface
    // -------------------------
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output wire       tx_ready,
    output wire       tx,

    // -------------------------
    // RX interface
    // -------------------------
    input  wire       rx,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    input  wire       rx_ready
);

    // ------------------------------------------------------------
    // Baud generator (shared)
    // ------------------------------------------------------------
    wire bit_ce;

    uart_baudgen #(
        .CLK_HZ (CLK_HZ),
        .BAUD   (BAUD)
    ) u_baudgen (
        .clk     (clk),
        .reset_n (reset_n),
        .bit_ce  (bit_ce)
    );

    // ------------------------------------------------------------
    // TX path
    // ------------------------------------------------------------
    uart_tx u_tx (
        .clk     (clk),
        .reset_n (reset_n),

        .data    (tx_data),
        .valid   (tx_valid),
        .ready   (tx_ready),

        .bit_ce  (bit_ce),
        .tx      (tx)
    );

    // ------------------------------------------------------------
    // RX placeholder (not implemented yet)
    // ------------------------------------------------------------
    assign rx_data  = 8'd0;
    assign rx_valid = 1'b0;
    // rx_ready intentionally unused for now

endmodule
