// ------------------------------------------------------------
// uart_rx.v — START QUALIFICATION + PHASE RESET
//             DATA BIT SAMPLING + STOP-BIT VALIDATION
//             TRUE BREAK DETECTION
//             RX OVERRUN FLAG
//             DATA LATCHED ONLY ON rx_valid
// ------------------------------------------------------------

module uart_rx (
    input  wire clk,
    input  wire reset_n,

    input  wire rx,              // async RX pin
    input  wire sample_ce,       // 8× baud enable
    output wire rx_phase_reset,  // phase reset to baudgen

    output reg  [7:0] rx_data,   // VALID data byte only
    output reg        rx_valid,  // CLK-domain level
    
    input  wire       rx_ready,  // acknowledge read
    
    output reg framing_error,    // STOP bit error (per frame)
    output reg break_detect,     // TRUE BREAK (level)
    output reg rx_overrun        // latched overrun flag
);

    // ------------------------------------------------------------
    // RX synchronizer
    // ------------------------------------------------------------
    wire rx_sync;

    sync1 #(.STAGES(2)) u_sync_rx (
        .clk  (clk),
        .din  (rx),
        .dout (rx_sync)
    );

    // ------------------------------------------------------------
    // Majority glitch filter
    // ------------------------------------------------------------
    wire rx_filt;

    filter_majority #(
        .TAPS      (3),
        .RESET_VAL (1'b1)
    ) u_rx_filter (
        .clk       (clk),
        .reset_n   (reset_n),
        .sample_en (sample_ce),
        .din       (rx_sync),
        .dout      (rx_filt)
    );

    // ------------------------------------------------------------
    // Start-bit qualification (half-bit LOW)
    // ------------------------------------------------------------
    wire start_level;

    level_duration_detect #(
        .COUNT_MAX    (4),
        .ACTIVE_LEVEL (1'b0)
    ) u_start_qual (
        .clk       (clk),
        .reset_n   (reset_n),
        .sample_en (sample_ce),
        .din       (rx_filt),
        .active    (start_level)
    );

    reg start_level_d;

    always @(posedge clk) begin
        if (!reset_n)
            start_level_d <= 1'b0;
        else if (sample_ce)
            start_level_d <= start_level;
    end

    wire start_pulse_ce = sample_ce && start_level && !start_level_d;

    // ------------------------------------------------------------
    // TRUE BREAK detection (RX LOW ≥ 10 bits)
    // ------------------------------------------------------------
    wire break_level;

    level_duration_detect #(
        .COUNT_MAX    (80),
        .ACTIVE_LEVEL (1'b0)
    ) u_break_detect (
        .clk       (clk),
        .reset_n   (reset_n),
        .sample_en (sample_ce),
        .din       (rx_filt),
        .active    (break_level)
    );

    // ------------------------------------------------------------
    // Sample counter (START → STOP mid-bit)
    // ------------------------------------------------------------
    reg [6:0] sample_cnt;
    reg       active;

    localparam integer STOP_SAMPLE = 7'd77;

    wire stop_sample_ce = sample_ce && active && (sample_cnt == STOP_SAMPLE);

    // ------------------------------------------------------------
    // Working register for data sampling
    // ------------------------------------------------------------
    reg [7:0] rx_data_work;

    // ------------------------------------------------------------
    // Main RX timing + data sampling
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            sample_cnt    <= 7'd0;
            active        <= 1'b0;
            framing_error <= 1'b0;
            break_detect  <= 1'b0;
            rx_data_work  <= 8'd0;
        end else if (sample_ce) begin

            // BREAK handling
            if (break_level) begin
                active        <= 1'b0;
                sample_cnt    <= 7'd0;
                framing_error <= 1'b0;
                break_detect  <= 1'b1;
            end else begin
                break_detect <= 1'b0;

                if (active)
                    sample_cnt <= sample_cnt + 1'b1;

                // START detected
                if (start_pulse_ce && !active) begin
                    active        <= 1'b1;
                    sample_cnt    <= 7'd0;
                    framing_error <= 1'b0;
                end

                // --------------------------------------------
                // Data bit sampling → WORK register only
                // --------------------------------------------
                case (sample_cnt)
                    7'd5  : rx_data_work[0] <= rx_filt;
                    7'd13 : rx_data_work[1] <= rx_filt;
                    7'd21 : rx_data_work[2] <= rx_filt;
                    7'd29 : rx_data_work[3] <= rx_filt;
                    7'd37 : rx_data_work[4] <= rx_filt;
                    7'd45 : rx_data_work[5] <= rx_filt;
                    7'd53 : rx_data_work[6] <= rx_filt;
                    7'd61 : rx_data_work[7] <= rx_filt;
                    default: ;
                endcase

                // STOP bit sample
                if (stop_sample_ce) begin
                    active <= 1'b0;

                    if (!rx_filt)
                        framing_error <= 1'b1;
                end
            end
        end
    end

    // ------------------------------------------------------------
    // Phase reset export
    // ------------------------------------------------------------
    assign rx_phase_reset = start_pulse_ce && !active && !break_level;

    // ------------------------------------------------------------
    // rx_valid, rx_data latch, and overrun logic (CLK domain)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            rx_valid   <= 1'b0;
            rx_data    <= 8'd0;
            rx_overrun <= 1'b0;
        end else begin
            // Consume byte
            if (rx_valid && rx_ready)
                rx_valid <= 1'b0;

            // New valid frame completed
            if (stop_sample_ce && rx_filt && !framing_error && !break_level) begin
                // Overrun detection
                if (rx_valid && !rx_ready)
                    rx_overrun <= 1'b1;

                rx_data  <= rx_data_work;  // ATOMIC COMMIT
                rx_valid <= 1'b1;
            end

            // Clear overrun on acknowledge
            if (rx_overrun && rx_ready)
                rx_overrun <= 1'b0;
        end
    end

endmodule
