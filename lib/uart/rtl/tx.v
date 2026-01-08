module uart_tx (
    input  wire clk,
    input  wire reset_n,

    input  wire [7:0] data,
    input  wire       valid,
    output reg        ready,

    input  wire       bit_ce,
    output reg        tx
);

    // ------------------------------------------------------------
    // TX state machine (unchanged)
    // ------------------------------------------------------------
    localparam ST_IDLE  = 2'd0;
    localparam ST_START = 2'd1;
    localparam ST_DATA  = 2'd2;
    localparam ST_STOP  = 2'd3;

    reg [1:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shreg;

    always @(posedge clk) begin
        if (!reset_n) begin
            state   <= ST_IDLE;
            tx      <= 1'b1;
            ready   <= 1'b1;
            bit_cnt <= 3'd0;
            shreg   <= 8'd0;
        end else begin
            case (state)

                ST_IDLE: begin
                    tx    <= 1'b1;
                    ready <= 1'b1;

                    if (valid) begin
                        shreg <= data;
                        state <= ST_START;
                        ready <= 1'b0;
                    end
                end

                ST_START: begin
                    if (bit_ce) begin
                        tx      <= 1'b0;
                        bit_cnt <= 3'd0;
                        state   <= ST_DATA;
                    end
                end

                ST_DATA: begin
                    if (bit_ce) begin
                        tx      <= shreg[0];
                        shreg   <= {1'b0, shreg[7:1]};
                        bit_cnt <= bit_cnt + 1'b1;

                        if (bit_cnt == 3'd7)
                            state <= ST_STOP;
                    end
                end

                ST_STOP: begin
                    if (bit_ce) begin
                        tx    <= 1'b1;
                        state <= ST_IDLE;
                        ready <= 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
