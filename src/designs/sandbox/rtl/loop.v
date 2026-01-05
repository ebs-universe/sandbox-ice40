module stepped_loop #(
    parameter integer CLK_HZ,
    parameter integer PERIOD_MS,
    parameter integer NTAPS,
    parameter integer WIDTH,
    parameter integer MAX_DIV
)(
    input              clk,
    input              reset_n,
    input  [NTAPS-1:0] taps,
    input  [3:0]       step,
    output     [7:0]   data
);

    // ------------------------------------------------------------
    // Periodic tick (locally registered)
    // ------------------------------------------------------------
    wire tick_raw;
    reg  tick;

    periodic_tick #(
        .CLK_HZ    (CLK_HZ),
        .PERIOD_MS (PERIOD_MS),
        .WIDTH     (WIDTH),
        .NTAPS     (NTAPS),
        .MAX_DIV   (MAX_DIV)
    ) u_timer (
        .clk     (clk),
        .reset_n (reset_n),
        .taps    (taps),
        .tick    (tick_raw)
    );

    always @(posedge clk) begin
        if (!reset_n)
            tick <= 1'b0;
        else
            tick <= tick_raw;
    end

    // ------------------------------------------------------------
    // Step control (registered enable)
    // ------------------------------------------------------------
    reg [3:0] steps_left;
    reg       shift_en;

    always @(posedge clk) begin
        if (!reset_n) begin
            steps_left <= 4'd0;
            shift_en   <= 1'b0;
        end else begin
            // Idle → wait for tick
            if (steps_left == 0) begin
                shift_en <= 1'b0;
                if (tick && step != 0) begin
                    steps_left <= step;
                    shift_en   <= 1'b1;
                end
            end
            // Active → shift
            else begin
                steps_left <= steps_left - 4'd1;
                shift_en   <= (steps_left != 4'd1);
            end
        end
    end

    // ------------------------------------------------------------
    // Shift register (unchanged interface)
    // ------------------------------------------------------------
    shift8 #(
        .INITIAL(8'h01)
    ) u_shift (
        .clk     (clk),
        .reset_n (reset_n),
        .enable  (shift_en),
        .d_in    (data[7]),
        .data    (data),
        .d_out   ()
    );

endmodule
