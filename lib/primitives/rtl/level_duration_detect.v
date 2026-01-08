module level_duration_detect #(
    parameter integer COUNT_MAX    = 16,
    parameter         ACTIVE_LEVEL = 1'b0
)(
    input  wire clk,
    input  wire reset_n,

    input  wire sample_en,
    input  wire din,

    output reg  active
);

    localparam CNT_W = $clog2(COUNT_MAX + 1);

    reg [CNT_W-1:0] cnt;

    always @(posedge clk) begin
        if (!reset_n) begin
            cnt    <= 0;
            active <= 1'b0;
        end else if (sample_en) begin
            if (din == ACTIVE_LEVEL) begin
                if (cnt < COUNT_MAX)
                    cnt <= cnt + 1'b1;
            end else begin
                cnt <= 0;
            end

            active <= (cnt >= COUNT_MAX);
        end
    end

endmodule
