

module clkdiv #(
    parameter CLK_HZ = 12_000_000,  // input clock frequency
    parameter TICK_HZ = 1           // desired tick rate
)(
    input  clk,
    output tick
);
    localparam integer DIV = CLK_HZ / TICK_HZ;

    reg [$clog2(DIV)-1:0] cnt = 0;
    reg tick_r = 0;

    assign tick = tick_r;
 
    always @(posedge clk) begin
        if (cnt == DIV-1) begin
            cnt    <= 0;
            tick_r <= 1;
        end else begin
            cnt    <= cnt + 1;
            tick_r <= 0;
        end
    end
endmodule
