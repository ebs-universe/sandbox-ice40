module filter_majority #(
    parameter integer TAPS = 3,
    parameter         RESET_VAL = 1'b1
)(
    input  wire clk,
    input  wire reset_n,

    input  wire sample_en,
    input  wire din,

    output reg  dout
);

    initial begin
        if ((TAPS % 2) == 0)
            $error("filter_majority: TAPS must be odd");
    end

    reg [TAPS-1:0] hist;

    integer i;
    integer sum;

    always @(posedge clk) begin
        if (!reset_n) begin
            hist <= {TAPS{RESET_VAL}};
            dout <= RESET_VAL;
        end else if (sample_en) begin
            hist <= {hist[TAPS-2:0], din};

            // majority vote
            sum = 0;
            for (i = 0; i < TAPS; i = i + 1)
                sum = sum + hist[i];

            dout <= (sum > (TAPS / 2));
        end
    end

endmodule
