// ------------------------------------------------------------
// uart_ex2.v — TX-only banner + debug LEDs (fixed one-shot)
// ------------------------------------------------------------
// Behavior:
//   - Wait ~N seconds after reset
//   - Transmit "ex2\r\n" exactly once
//   - Go idle forever
//
// Design rules enforced here:
//   - ALL one-shot actions are EDGE-triggered
//   - banner_enable is a LEVEL
//   - banner_enable_rise is the ONLY trigger
// ------------------------------------------------------------

module uart_ex2 #(
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
    input  wire uart_rx,   // unused for now
    output wire uart_tx,

    // Debug LEDs (active high)
    output wire [7:0] led
);

    // ========================================================
    // [BLOCK A] UART TX interface
    // ========================================================
    reg  [7:0] tx_data;
    reg        tx_valid;
    wire       tx_ready;

    // ========================================================
    // [BLOCK B] Startup delay (periodic tick @ 1s)
    // ========================================================
    wire sec_tick;

    periodic_tick #(
        .CLK_HZ    (CLK_HZ),
        .PERIOD_US (1_000_000),   // 1 second
        .NTAPS     (NTAPS),
        .WIDTH     (WIDTH),
        .MAX_DIV   (MAX_DIV)
    ) u_start_delay (
        .clk     (clk),
        .reset_n (reset_n),
        .taps    (taps),
        .tick    (sec_tick)
    );

    // ========================================================
    // [BLOCK C] Delay counter → banner_enable (LEVEL)
    // ========================================================
    reg [3:0] sec_cnt;
    reg       banner_enable;

    always @(posedge clk) begin
        if (!reset_n) begin
            sec_cnt       <= 4'd0;
            banner_enable <= 1'b0;
        end else if (sec_tick) begin
            if (!banner_enable) begin
                if (sec_cnt == 4'd0) begin
                    banner_enable <= 1'b1;   // latch permanently
                end else begin
                    sec_cnt <= sec_cnt + 1'b1;
                end
            end
        end
    end

    // ========================================================
    // [BLOCK D] banner_enable EDGE detector (CRITICAL FIX)
    // ========================================================
    reg banner_enable_d;

    always @(posedge clk) begin
        if (!reset_n)
            banner_enable_d <= 1'b0;
        else
            banner_enable_d <= banner_enable;
    end

    wire banner_enable_rise = banner_enable && !banner_enable_d;

    // ========================================================
    // [BLOCK E] 1 Hz debug LED
    // ========================================================
    reg sec_tick_led;

    always @(posedge clk) begin
        if (!reset_n)
            sec_tick_led <= 1'b0;
        else if (sec_tick)
            sec_tick_led <= ~sec_tick_led;
    end

    // ========================================================
    // [BLOCK F] Banner ROM
    // ========================================================
    localparam integer BANNER_LEN = 6;

    reg [7:0] banner [0:BANNER_LEN-1];
    initial begin
        banner[0] = "e";
        banner[1] = "x";
        banner[2] = "2";
        banner[3] = "\r";
        banner[4] = "\n";
        banner[5] = 8'h00;   // terminator (not transmitted)
    end

    // ========================================================
    // [BLOCK G] Banner control FSM (ONE-SHOT, EDGE-TRIGGERED)
    // ========================================================
    reg [$clog2(BANNER_LEN)-1:0] banner_idx;
    reg                          banner_active;
    reg                          banner_started;
    reg                          banner_primed;

    always @(posedge clk) begin
        if (!reset_n) begin
            banner_idx     <= 0;
            banner_active  <= 1'b0;
            banner_started <= 1'b0;
            banner_primed  <= 1'b0;

            tx_data        <= 8'h00;
            tx_valid       <= 1'b0;
        end else begin
            tx_valid <= 1'b0;

            // Arm banner exactly once
            if (banner_enable_rise) begin                
                banner_active  <= 1'b1;
                banner_started <= 1'b1;
                banner_primed  <= 1'b0;   // <-- IMPORTANT
                banner_idx     <= 0;
            end

            // One-cycle priming delay
            if (banner_active && !banner_primed) begin
                banner_primed <= 1'b1;
            end else if (banner_active && banner_primed) begin
                if (tx_ready && !tx_valid) begin
                    if (banner[banner_idx] != 8'h00) begin
                        tx_data  <= banner[banner_idx];
                        tx_valid <= 1'b1;   // assert and HOLD
                    end else begin
                        banner_active <= 1'b0;
                    end
                end else if (tx_ready && tx_valid) begin
                    // byte accepted
                    tx_valid   <= 1'b0;
                    banner_idx <= banner_idx + 1'b1;
                end
            end
        end
    end


    // ========================================================
    // [BLOCK H] UART core
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

        // RX unused for now
        .rx        (uart_rx),
        .rx_data   (),
        .rx_valid  (),
        .rx_ready  (1'b0)
    );

    // ========================================================
    // [BLOCK I] Debug LEDs
    // ========================================================
    // LED meanings:
    //   LED0 — banner_enable (level, after delay)
    //   LED1 — banner_active (high during TX)
    //   LED2 — tx_ready
    //   LED3 — tx_valid pulse
    //   LED4 — uart_tx pin
    //   LED6:5 — sec_cnt
    //   LED7 — sec_tick LED (1 Hz)
    //
    assign led[0]   = banner_enable;
    assign led[1]   = banner_active;
    assign led[2]   = tx_ready;
    assign led[3]   = tx_valid;
    assign led[4]   = uart_tx;
    assign led[6:5] = sec_cnt[1:0];
    assign led[7]   = sec_tick_led;

endmodule
