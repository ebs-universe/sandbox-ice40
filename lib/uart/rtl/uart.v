// ------------------------------------------------------------
// uart.v — UART wrapper with RX FIFO integration
// ------------------------------------------------------------
// RX behavior preserved:
//   - RX never blocks sampling
//   - Valid frames enqueue exactly once
//   - FIFO full → rx_overrun asserted (sticky)
//   - rx_valid / rx_data sourced from FIFO
// ------------------------------------------------------------

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
    input  wire       rx_ready,

    output wire       rx_framing_error,
    output wire       rx_break,
    output wire       rx_overrun
);

    // ============================================================
    // TX Baud generator (UNCHANGED)
    // ============================================================
    wire tx_bit_ce;

    uart_baudgen #(
        .CLK_HZ  (CLK_HZ),
        .RATE_HZ (BAUD)
    ) u_tx_baudgen (
        .clk         (clk),
        .reset_n     (reset_n),
        .phase_reset (1'b0),   // TX never rephases
        .ce          (tx_bit_ce)
    );

    // ============================================================
    // TX FIFO (UNCHANGED)
    // ============================================================
    wire [7:0] tx_fifo_rdata;
    wire       tx_fifo_rvalid;
    wire       tx_tx_ready;

    fifo8 u_tx_fifo (
        .clk     (clk),
        .reset_n (reset_n),

        .wdata   (tx_data),
        .wvalid  (tx_valid),
        .wready  (tx_ready),

        .rdata   (tx_fifo_rdata),
        .rvalid  (tx_fifo_rvalid),
        .rready  (tx_tx_ready),

        .flush   (1'b0)
    );

    // ============================================================
    // UART TX engine (UNCHANGED)
    // ============================================================
    uart_tx u_tx (
        .clk     (clk),
        .reset_n (reset_n),

        .data    (tx_fifo_rdata),
        .valid   (tx_fifo_rvalid),
        .ready   (tx_tx_ready),

        .bit_ce  (tx_bit_ce),
        .tx      (tx)
    );

    // ============================================================
    // RX Baud generator (phase-reset capable)
    // ============================================================
    wire rx_sample_ce;
    wire rx_phase_reset;

    uart_baudgen #(
        .CLK_HZ  (CLK_HZ),
        .RATE_HZ (BAUD * 8)
    ) u_rx_baudgen (
        .clk         (clk),
        .reset_n     (reset_n),
        .phase_reset (rx_phase_reset),
        .ce          (rx_sample_ce)
    );

    // ============================================================
    // RX core
    // ============================================================
    wire [7:0] rx_data_i;
    wire       rx_valid_i;
    wire       rx_frame_err_i;
    wire       rx_break_i;
    wire       rx_overrun_i;

    uart_rx u_rx (
        .clk            (clk),
        .reset_n        (reset_n),

        .rx             (rx),
        .sample_ce      (rx_sample_ce),
        .rx_phase_reset (rx_phase_reset),

        .rx_data        (rx_data_i),
        .rx_valid       (rx_valid_i),
        .rx_ready       (rx_ready),

        .framing_error  (rx_frame_err_i),
        .break_detect   (rx_break_i),
        .rx_overrun     (rx_overrun_i)
    );

    // ============================================================
    // RX FIFO (NEW)
    // ============================================================
    wire       rx_fifo_wready;
    wire       rx_fifo_rvalid;
    wire [7:0] rx_fifo_rdata;

    fifo8 u_rx_fifo (
        .clk     (clk),
        .reset_n (reset_n),

        // write side (from RX core)
        .wdata   (rx_data_i),
        .wvalid  (rx_valid_i),
        .wready  (rx_fifo_wready),

        // read side (to user)
        .rdata   (rx_fifo_rdata),
        .rvalid  (rx_fifo_rvalid),
        .rready  (rx_ready),

        .flush   (1'b0)
    );

    // ============================================================
    // RX overrun logic (STICKY)
    // ============================================================
    reg rx_overrun_r;

    always @(posedge clk) begin
        if (!reset_n) begin
            rx_overrun_r <= 1'b0;
        end else begin
            // RX completed a valid frame but FIFO full
            if (rx_valid_i && !rx_fifo_wready)
                rx_overrun_r <= 1'b1;

            // Clear overrun on user acknowledge
            if (rx_overrun_r && rx_ready)
                rx_overrun_r <= 1'b0;
        end
    end

    // ============================================================
    // RX outputs
    // ============================================================
    assign rx_data          = rx_fifo_rdata;
    assign rx_valid         = rx_fifo_rvalid;
    assign rx_framing_error = rx_frame_err_i;
    assign rx_break         = rx_break_i;
    assign rx_overrun       = rx_overrun_r;

endmodule
