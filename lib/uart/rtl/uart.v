module uart #(
    parameter integer CLK_HZ = 48_000_000,
    parameter integer BAUD   = 1_000_000
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

    fifo8 u_tx_fifo (
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
    );

    // ------------------------------------------------------------
    // TX holding register (CE-FREE, PIPELINED)
    // ------------------------------------------------------------
    reg  [7:0] tx_hold_data;
    reg        tx_hold_valid;
    reg        tx_fifo_rready;

    // tx_accept is now simply uart_tx readiness
    wire tx_accept = tx_tx_ready;

    // combinational load condition
    wire load_hold = tx_tx_ready && tx_fifo_rvalid;

    always @(posedge clk) begin
        if (!reset_n) begin
            tx_hold_data   <= 8'd0;
            tx_hold_valid  <= 1'b0;
            tx_fifo_rready <= 1'b0;
        end else begin
            // ----------------------------------------------------
            // tx_hold_data — UNCONDITIONAL REGISTER (NO CEN)
            // ----------------------------------------------------
            tx_hold_data <= load_hold ? tx_fifo_rdata : tx_hold_data;

            // ----------------------------------------------------
            // tx_hold_valid — pipeline semantics
            // ----------------------------------------------------
            if (tx_tx_ready) begin
                tx_hold_valid <= tx_fifo_rvalid;
            end

            // ----------------------------------------------------
            // FIFO read handshake
            // ----------------------------------------------------
            tx_fifo_rready <= load_hold;
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
