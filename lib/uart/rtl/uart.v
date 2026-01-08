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
    // RX interface (future)
    // -------------------------
    input  wire       rx,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    input  wire       rx_ready
);

    // ------------------------------------------------------------
    // Baud generator
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
    // TX FIFO (with internal read buffering)
    // ------------------------------------------------------------
    wire [7:0] tx_fifo_rdata;
    wire       tx_fifo_rvalid;

    fifo8 u_tx_fifo (
        .clk     (clk),
        .reset_n (reset_n),

        // write side
        .wdata   (tx_data),
        .wvalid  (tx_valid),
        .wready  (tx_ready),

        // read side (buffered inside FIFO)
        .rdata   (tx_fifo_rdata),
        .rvalid  (tx_fifo_rvalid),
        .rready  (tx_tx_ready),

        .flush   (1'b0)
    );

    // ------------------------------------------------------------
    // UART TX engine
    // ------------------------------------------------------------
    wire tx_tx_ready;

    uart_tx u_tx (
        .clk     (clk),
        .reset_n (reset_n),

        .data    (tx_fifo_rdata),
        .valid   (tx_fifo_rvalid),
        .ready   (tx_tx_ready),

        .bit_ce  (bit_ce),
        .tx      (tx)
    );

    // ------------------------------------------------------------
    // RX placeholder
    // ------------------------------------------------------------
    assign rx_data  = 8'd0;
    assign rx_valid = 1'b0;

endmodule
