module uart #(
    parameter integer CLK_HZ = 48_000_000,
    parameter integer BAUD   = 1_000_000,
    parameter integer TX_FIFO_DEPTH = 1024
)(
    input  wire clk,
    input  wire reset_n,

    // -------------------------
    // TX interface (unchanged)
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
    input  wire       rx_ready,

    // -------------------------
    // Optional TX status
    // -------------------------
    output wire       tx_almost_full,
    output wire       tx_almost_empty
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
    // TX FIFO
    // ------------------------------------------------------------
    wire [7:0] tx_fifo_rdata;
    wire       tx_fifo_rvalid;
    reg        tx_fifo_rready;

    fifo8 #(
        .DEPTH (TX_FIFO_DEPTH)
    ) u_tx_fifo (
        .clk          (clk),
        .reset_n      (reset_n),

        // write side
        .wdata        (tx_data),
        .wvalid       (tx_valid),
        .wready       (tx_ready),

        // read side
        .rdata        (tx_fifo_rdata),
        .rvalid       (tx_fifo_rvalid),
        .rready       (tx_fifo_rready),

        .flush        (1'b0),

        .level        (),
        .almost_full  (tx_almost_full),
        .almost_empty (tx_almost_empty)
    );

    // ------------------------------------------------------------
    // TX holding register (CRITICAL)
    // ------------------------------------------------------------
    reg  [7:0] tx_hold_data;
    reg        tx_hold_valid;

    wire tx_accept;

    assign tx_accept = tx_hold_valid && tx_tx_ready;

    always @(posedge clk) begin
        if (!reset_n) begin
            tx_hold_valid <= 1'b0;
            tx_fifo_rready   <= 1'b0;
        end else begin
            tx_fifo_rready <= 1'b0;

            // consume by uart_tx
            if (tx_accept) begin
                tx_hold_valid <= 1'b0;
            end

            // load from FIFO when empty
            if (!tx_hold_valid && tx_fifo_rvalid) begin
                tx_hold_data  <= tx_fifo_rdata;
                tx_hold_valid <= 1'b1;
                tx_fifo_rready   <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------
    // UART TX (UNCHANGED behavior)
    // ------------------------------------------------------------
    wire tx_tx_ready;

    uart_tx u_tx (
        .clk     (clk),
        .reset_n (reset_n),

        .data    (tx_hold_data),
        .valid   (tx_hold_valid),
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
