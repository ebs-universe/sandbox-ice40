// ------------------------------------------------------------
// uart_ex1.v — UART TX incrementing counter example
// ------------------------------------------------------------

module uart_ex1 (
    input  wire clk,
    input  wire reset_n,

    output wire uart_tx,
    input  wire uart_rx    // unused, but wired for completeness
);

    // ------------------------------------------------------------
    // Simple TX data source
    // ------------------------------------------------------------
    reg [7:0] tx_data;
    reg       tx_valid;
    wire      tx_ready;

    always @(posedge clk) begin
        if (!reset_n) begin
            tx_data  <= 8'h00;
            tx_valid <= 1'b0;
        end else begin
            // Generate a 1-cycle tx_valid pulse when ready
            tx_valid <= (tx_ready && !tx_valid);

            // Advance data only on successful transfer
            if (tx_valid && tx_ready)
                tx_data <= tx_data + 1'b1;
        end
    end

    // ------------------------------------------------------------
    // UART instance
    // ------------------------------------------------------------
    uart u_uart (
        .clk       (clk),
        .reset_n   (reset_n),

        .tx_data   (tx_data),
        .tx_valid  (tx_valid),
        .tx_ready  (tx_ready),
        .tx        (uart_tx),

        .rx        (uart_rx),
        .rx_data   (),
        .rx_valid  (),
        .rx_ready  (1'b1),

        .rx_framing_error (),
        .rx_break         ()
    );

endmodule
