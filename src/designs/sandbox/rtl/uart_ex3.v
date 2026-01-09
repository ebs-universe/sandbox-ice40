// ------------------------------------------------------------
// uart_ex3.v — Banner TX + RX Echo
// ------------------------------------------------------------

module uart_ex3 #(
    parameter integer CLK_HZ,
    parameter integer BAUD,
    parameter integer NTAPS,
    parameter integer WIDTH,
    parameter integer MAX_DIV
)(
    input  wire             clk,
    input  wire             reset_n,
    input  wire [NTAPS-1:0] taps,

    // UART pins
    input  wire uart_rx,
    output wire uart_tx,

    // Debug LEDs
    output wire [7:0] led
);

    // ========================================================
    // [BLOCK A] UART TX interface
    // ========================================================
    reg  [7:0] tx_data;
    reg        tx_valid;
    wire       tx_ready;

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_ready;
    wire       rx_framing_error;
    wire       rx_break;

    assign rx_ready = 1'b1;

    // ========================================================
    // [BLOCK B] Startup tick (1 Hz)
    // ========================================================
    wire sec_tick;

    periodic_tick #(
        .CLK_HZ    (CLK_HZ),
        .PERIOD_US (1_000_000),
        .NTAPS     (NTAPS),
        .WIDTH     (WIDTH),
        .MAX_DIV   (MAX_DIV)
    ) u_start_delay_tick (
        .clk     (clk),
        .reset_n (reset_n),
        .taps    (taps),
        .tick    (sec_tick)
    );

    // ========================================================
    // [BLOCK C] Startup delay
    // ========================================================
    wire banner_enable;
    wire banner_enable_rise;

    startup_delay #(
        .DELAY_TICKS (2)
    ) u_startup_delay (
        .clk         (clk),
        .reset_n     (reset_n),
        .tick        (sec_tick),
        .enable      (banner_enable),
        .enable_rise (banner_enable_rise)
    );

    // ========================================================
    // [BLOCK D] Banner ROM
    // ========================================================
    localparam integer BANNER_LEN = 6;

    reg [7:0] banner [0:BANNER_LEN-1];
    initial begin
        banner[0] = "e";
        banner[1] = "x";
        banner[2] = "2";
        banner[3] = "\r";
        banner[4] = "\n";
        banner[5] = 8'h00;
    end

    // ========================================================
    // [BLOCK E] Banner TX FSM
    // ========================================================
    reg [$clog2(BANNER_LEN)-1:0] banner_idx;
    reg                          banner_active;
    reg                          banner_primed;

    // --------------------------------------------------------
    // TX source mux control
    // --------------------------------------------------------
    wire echo_enable = !banner_active;

    always @(posedge clk) begin
        if (!reset_n) begin
            banner_idx    <= 0;
            banner_active <= 1'b0;
            banner_primed <= 1'b0;
            tx_data       <= 8'h00;
            tx_valid      <= 1'b0;
        end else begin
            tx_valid <= 1'b0;

            // ----------------------------
            // Banner trigger
            // ----------------------------
            if (banner_enable_rise) begin
                banner_active <= 1'b1;
                banner_primed <= 1'b0;
                banner_idx    <= 0;
            end

            // ----------------------------
            // Banner transmit
            // ----------------------------
            if (banner_active && !banner_primed) begin
                banner_primed <= 1'b1;
            end else if (banner_active && banner_primed) begin
                if (tx_ready) begin
                    if (banner[banner_idx] != 8'h00) begin
                        tx_data  <= banner[banner_idx];
                        tx_valid <= 1'b1;
                        banner_idx <= banner_idx + 1'b1;
                    end else begin
                        banner_active <= 1'b0;
                    end
                end
            end

            // ----------------------------
            // RX echo (only when banner idle)
            // ----------------------------
            else if (echo_enable && rx_valid && tx_ready) begin
                tx_data  <= rx_data;
                tx_valid <= 1'b1;
            end
        end
    end

    // ========================================================
    // [BLOCK F] UART core
    // ========================================================
    uart #(
        .CLK_HZ (CLK_HZ),
        .BAUD   (BAUD)
    ) u_uart (
        .clk       (clk),
        .reset_n   (reset_n),

        .tx_data   (tx_data),
        .tx_valid  (tx_valid),
        .tx_ready  (tx_ready),
        .tx        (uart_tx),

        .rx        (uart_rx),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid),
        .rx_ready  (rx_ready),

        .rx_framing_error (rx_framing_error),
        .rx_break         (rx_break)
    );

    // ========================================================
    // RX debug LEDs
    // ========================================================
    reg rx_valid_toggle;

    always @(posedge clk) begin
        if (!reset_n)
            rx_valid_toggle <= 1'b0;
        else if (rx_valid)
            rx_valid_toggle <= ~rx_valid_toggle;
    end

    assign led[0]   = rx_valid_toggle;
    assign led[7:1] = rx_data[6:0];

endmodule
