// uart_baudgen.v
module uart_baudgen #(
    parameter integer CLK_HZ = 48_000_000,
    parameter integer BAUD   = 1_000_000
)(
    input  wire clk,
    input  wire reset_n,

    output reg  bit_ce   // 1-cycle pulse @ baud rate
);

    localparam integer DIV   = CLK_HZ / BAUD;
    localparam integer DIV_W = $clog2(DIV);

    reg [DIV_W-1:0] div_cnt;

    always @(posedge clk) begin
        if (!reset_n) begin
            div_cnt <= {DIV_W{1'b0}};
            bit_ce  <= 1'b0;
        end else begin
            if (div_cnt == DIV-1) begin
                div_cnt <= {DIV_W{1'b0}};
                bit_ce  <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 1'b1;
                bit_ce  <= 1'b0;
            end
        end
    end

endmodule
