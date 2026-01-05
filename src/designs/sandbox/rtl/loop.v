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
    output reg [7:0]   data
);

    // ------------------------------------------------------------------
    // Periodic tick generator (1-cycle pulse, synchronous to clk)
    // ------------------------------------------------------------------
    wire tick;

    periodic_tick #(
        .CLK_HZ(CLK_HZ),
        .PERIOD_MS(PERIOD_MS),
        .WIDTH(WIDTH),
        .NTAPS(NTAPS),
        .MAX_DIV(MAX_DIV)
    ) u_timer (
        .clk     (clk),
        .reset_n (reset_n),
        .taps    (taps),
        .tick    (tick)
    );

    // ------------------------------------------------------------------
    // Step control
    // ------------------------------------------------------------------
    reg  [3:0] steps_left;
    wire       shift_en;

    assign shift_en = (steps_left != 0);

    always @(posedge clk) begin
        if (!reset_n) begin
            steps_left <= 4'd0;
        end else begin
            // Load a new burst on tick if idle
            if (tick && steps_left == 0) begin
                steps_left <= step;
            end
            // Consume one step per cycle while active
            else if (steps_left != 0) begin
                steps_left <= steps_left - 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Rotating shift register
    // ------------------------------------------------------------------
    wire loop;
    assign loop = data[7];

    shift8 #(
        .INITIAL(8'h01)
    ) shift_reg (
        .clk        (clk),
        .reset_n    (reset_n),
        .enable     (shift_en),
        .d_in       (loop),
        .data       (data),
        .d_out      ()
    );

endmodule
