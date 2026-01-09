// ------------------------------------------------------------
// uart_rx.v — RX with registered sample_ce (Option A)
// ------------------------------------------------------------

module uart_rx (
    input  wire clk,
    input  wire reset_n,         // global reset (sync deasserted upstream)

    input  wire rx,              // async RX pin
    input  wire sample_ce,       // 8× baud enable (from baudgen)
    output wire rx_phase_reset,  // phase reset to baudgen

    output reg  [7:0] rx_data,
    output reg        rx_valid,

    input  wire       rx_ready,

    output reg framing_error,
    output reg break_detect,
    output reg rx_overrun
);

    // ------------------------------------------------------------
    // Local synchronous reset (1-cycle latency)
    // ------------------------------------------------------------
    reg reset_n_sync;
    always @(posedge clk)
        reset_n_sync <= reset_n;

    // ------------------------------------------------------------
    // Register sample_ce (BREAKS LONG ENABLE ROUTE)
    // ------------------------------------------------------------
    reg sample_ce_r;
    always @(posedge clk)
        sample_ce_r <= sample_ce;

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
        .reset_n   (reset_n_sync),
        .sample_en (sample_ce_r),
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
        .reset_n   (reset_n_sync),
        .sample_en (sample_ce_r),
        .din       (rx_filt),
        .active    (start_level)
    );

    reg start_level_d;
    always @(posedge clk) begin
        start_level_d <=
            !reset_n_sync ? 1'b0 :
            sample_ce_r   ? start_level :
                            start_level_d;
    end

    wire start_pulse_ce = sample_ce_r && start_level && !start_level_d;

    // ------------------------------------------------------------
    // TRUE BREAK detection (RX LOW ≥ 10 bits)
    // ------------------------------------------------------------
    wire break_level;

    level_duration_detect #(
        .COUNT_MAX    (80),
        .ACTIVE_LEVEL (1'b0)
    ) u_break_detect (
        .clk       (clk),
        .reset_n   (reset_n_sync),
        .sample_en (sample_ce_r),
        .din       (rx_filt),
        .active    (break_level)
    );

    // ------------------------------------------------------------
    // RX active state
    // ------------------------------------------------------------
    reg active, active_next;

    localparam integer STOP_SAMPLE = 7'd77;
    reg [6:0] sample_cnt;

    wire stop_sample_ce =
        sample_ce_r && active && (sample_cnt == STOP_SAMPLE);

    always @* begin
        active_next = active;

        if (break_level)
            active_next = 1'b0;
        else if (sample_ce_r) begin
            if (start_pulse_ce && !active)
                active_next = 1'b1;
            else if (stop_sample_ce)
                active_next = 1'b0;
        end
    end

    always @(posedge clk) begin
        if (!reset_n_sync)
            active <= 1'b0;
        else
            active <= active_next;
    end

    // ------------------------------------------------------------
    // Sample counter
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n_sync)
            sample_cnt <= 7'd0;
        else if (sample_ce_r) begin
            if (!active)
                sample_cnt <= 7'd0;
            else
                sample_cnt <= sample_cnt + 1'b1;
        end
    end

    // ------------------------------------------------------------
    // Data sampling
    // ------------------------------------------------------------
    reg [7:0] rx_data_work;

    always @(posedge clk) begin
        if (!reset_n_sync)
            rx_data_work <= 8'd0;
        else if (sample_ce_r) begin
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
        end
    end

    // ------------------------------------------------------------
    // Framing error
    // ------------------------------------------------------------
    reg framing_error_next;

    always @* begin
        framing_error_next = framing_error;

        if (break_level)
            framing_error_next = 1'b0;
        else if (sample_ce_r) begin
            if (start_pulse_ce && !active)
                framing_error_next = 1'b0;
            else if (stop_sample_ce && !rx_filt)
                framing_error_next = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (!reset_n_sync)
            framing_error <= 1'b0;
        else
            framing_error <= framing_error_next;
    end

    // ------------------------------------------------------------
    // Break detect (level)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n_sync)
            break_detect <= 1'b0;
        else
            break_detect <= break_level;
    end

    // ------------------------------------------------------------
    // Phase reset export
    // ------------------------------------------------------------
    assign rx_phase_reset =
        start_pulse_ce && !active && !break_level;

    // ------------------------------------------------------------
    // RX commit pulse
    // ------------------------------------------------------------
    reg rx_commit;
    always @(posedge clk) begin
        if (!reset_n_sync)
            rx_commit <= 1'b0;
        else
            rx_commit <=
                stop_sample_ce &&
                rx_filt &&
                !framing_error &&
                !break_level;
    end

    // ------------------------------------------------------------
    // rx_valid / rx_data / overrun
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n_sync) begin
            rx_valid   <= 1'b0;
            rx_data    <= 8'd0;
            rx_overrun <= 1'b0;
        end else begin
            if (rx_valid && rx_ready)
                rx_valid <= 1'b0;

            if (rx_commit) begin
                if (rx_valid && !rx_ready)
                    rx_overrun <= 1'b1;

                rx_data  <= rx_data_work;
                rx_valid <= 1'b1;
            end

            if (rx_overrun && rx_ready)
                rx_overrun <= 1'b0;
        end
    end

endmodule
