module startup_delay #(
    parameter integer DELAY_TICKS = 2
)(
    input  wire clk,
    input  wire reset_n,

    input  wire tick,           // 1-cycle pulse
    output reg  enable,         // LEVEL
    output wire enable_rise      // 1-cycle pulse
);

    localparam CNT_W = $clog2(DELAY_TICKS + 1);

    reg [CNT_W-1:0] cnt;
    reg enable_d;

    always @(posedge clk) begin
        if (!reset_n) begin
            cnt    <= {CNT_W{1'b0}};
            enable <= 1'b0;
        end else begin
            if (!enable) begin
                if (tick) begin
                    if (cnt == DELAY_TICKS-1) begin
                        enable <= 1'b1;
                    end else begin
                        cnt <= cnt + 1'b1;
                    end
                end
            end
        end
    end

    // Edge detect enable
    always @(posedge clk) begin
        if (!reset_n)
            enable_d <= 1'b0;
        else
            enable_d <= enable;
    end

    assign enable_rise = enable & ~enable_d;

endmodule
