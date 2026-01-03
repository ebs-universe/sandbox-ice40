module tick_100ms #(
    parameter integer CLK_HZ = 12_000_000
)(
    input  clk,
    output reg tick
);
    // 100 ms period
    localparam integer PERIOD = CLK_HZ / 10;
    localparam integer W = $clog2(PERIOD);

    reg [W-1:0] cnt;

    always @(posedge clk) begin
        if (cnt == PERIOD-1) begin
            cnt  <= 0;
            tick <= 1;
        end else begin
            cnt  <= cnt + 1;
            tick <= 0;
        end
    end
endmodule
