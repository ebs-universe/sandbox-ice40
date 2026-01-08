module uart_tx #(
    parameter integer CLK_HZ = 48_000_000,
    parameter integer BAUD   = 1_000_000
)(
    input  wire clk,
    input  wire reset_n,

    input  wire [7:0] data,
    input  wire       valid,
    output reg        ready,

    output reg        tx
);

    // ------------------------------------------------------------
    // Baud generator (free running)
    // ------------------------------------------------------------
    localparam integer DIV   = CLK_HZ / BAUD;
    localparam integer DIV_W = $clog2(DIV);

    reg [DIV_W-1:0] div_cnt;
    reg             bit_ce;

    always @(posedge clk) begin
        if (!reset_n) begin
            div_cnt <= 0;
            bit_ce  <= 1'b0;
        end else begin
            if (div_cnt == DIV-1) begin
                div_cnt <= 0;
                bit_ce  <= 1'b1;   // one-cycle enable
            end else begin
                div_cnt <= div_cnt + 1'b1;
                bit_ce  <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // TX state machine
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
            tx      <= 1'b1;   // idle line high
            ready   <= 1'b1;
            bit_cnt <= 3'd0;
            shreg   <= 8'd0;
        end else begin
            case (state)

                // ------------------------------------------------
                // IDLE: wait for valid
                // ------------------------------------------------
                ST_IDLE: begin
                    tx    <= 1'b1;
                    ready <= 1'b1;

                    if (valid) begin
                        shreg <= data;
                        state <= ST_START;
                        ready <= 1'b0;
                    end
                end

                // ------------------------------------------------
                // START bit (on next bit_ce)
                // ------------------------------------------------
                ST_START: begin
                    if (bit_ce) begin
                        tx      <= 1'b0;   // start bit
                        bit_cnt <= 3'd0;
                        state   <= ST_DATA;
                    end
                end

                // ------------------------------------------------
                // DATA bits
                // ------------------------------------------------
                ST_DATA: begin
                    if (bit_ce) begin
                        tx    <= shreg[0];
                        shreg <= {1'b0, shreg[7:1]};
                        bit_cnt <= bit_cnt + 1'b1;

                        if (bit_cnt == 3'd7)
                            state <= ST_STOP;
                    end
                end

                // ------------------------------------------------
                // STOP bit
                // ------------------------------------------------
                ST_STOP: begin
                    if (bit_ce) begin
                        tx    <= 1'b1;   // stop bit
                        state <= ST_IDLE;
                        ready <= 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
