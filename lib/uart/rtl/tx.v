module uart_tx #(
    parameter integer CLK_HZ,
    parameter integer BAUD    = 1_000_000
)(
    input  wire clk,
    input  wire reset_n,

    input  wire [7:0] data,
    input  wire       valid,
    output reg        ready,

    output reg        tx
);

    localparam integer DIV = CLK_HZ / BAUD;
    localparam integer DIV_W = $clog2(DIV);

    reg [DIV_W-1:0] div_cnt;
    reg [3:0]       bit_cnt;
    reg [9:0]       shreg;
    reg             busy;

    always @(posedge clk) begin
        if (!reset_n) begin
            tx      <= 1'b1;
            busy    <= 1'b0;
            ready   <= 1'b1;
            div_cnt <= 0;
            bit_cnt <= 0;
        end else begin
            if (!busy) begin
                tx    <= 1'b1;
                ready <= 1'b1;
                if (valid) begin
                    // start + data + stop
                    shreg   <= {1'b1, data, 1'b0};
                    busy    <= 1'b1;
                    ready   <= 1'b0;
                    div_cnt <= 0;
                    bit_cnt <= 0;
                end
            end else begin
                if (div_cnt == DIV-1) begin
                    div_cnt <= 0;
                    tx      <= shreg[0];
                    shreg   <= {1'b1, shreg[9:1]};
                    bit_cnt <= bit_cnt + 1'b1;
                    if (bit_cnt == 9) begin
                        busy  <= 1'b0;
                        ready <= 1'b1;
                    end
                end else begin
                    div_cnt <= div_cnt + 1'b1;
                end
            end
        end
    end

endmodule
