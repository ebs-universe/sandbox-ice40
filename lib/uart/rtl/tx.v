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
    // TX state machine
    // ------------------------------------------------------------
    localparam ST_BREAK     = 3'd0;
    localparam ST_SYNC_CHAR = 3'd1;
    localparam ST_IDLE      = 3'd2;
    localparam ST_START     = 3'd3;
    localparam ST_DATA      = 3'd4;
    localparam ST_STOP      = 3'd5;

    reg [2:0] state;
    reg [3:0] break_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shreg;

    // ------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------
    localparam integer BREAK_BITS = 16;      // > 1 char time
    localparam [7:0]   SYNC_CHAR  = "*";     // sacrificial byte

    // ------------------------------------------------------------
    // UART TX FSM
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            // Force BREAK on startup
            state     <= ST_BREAK;
            break_cnt <= 4'd0;

            tx        <= 1'b0;   // BREAK = line held low
            ready     <= 1'b0;

            bit_cnt   <= 3'd0;
            shreg     <= 8'd0;

        end else begin
            case (state)

                // --------------------------------------------
                // BREAK: hold TX low for BREAK_BITS
                // --------------------------------------------
                ST_BREAK: begin
                    tx    <= 1'b0;
                    ready <= 1'b0;

                    if (bit_ce) begin
                        if (break_cnt == BREAK_BITS-1) begin
                            break_cnt <= 4'd0;
                            shreg     <= SYNC_CHAR;   // preload '*'
                            state     <= ST_SYNC_CHAR;
                        end else begin
                            break_cnt <= break_cnt + 1'b1;
                        end
                    end
                end

                // --------------------------------------------
                // Transmit sacrificial sync character ('*')
                // --------------------------------------------
                ST_SYNC_CHAR: begin
                    if (bit_ce) begin
                        tx      <= 1'b0;     // start bit
                        bit_cnt <= 3'd0;
                        state   <= ST_DATA;
                    end
                end

                // --------------------------------------------
                // IDLE (normal operation)
                // --------------------------------------------
                ST_IDLE: begin
                    tx    <= 1'b1;
                    ready <= 1'b1;

                    if (valid) begin
                        shreg <= data;
                        state <= ST_START;
                        ready <= 1'b0;
                    end
                end

                // --------------------------------------------
                // START BIT (normal data)
                // --------------------------------------------
                ST_START: begin
                    if (bit_ce) begin
                        tx      <= 1'b0;
                        bit_cnt <= 3'd0;
                        state   <= ST_DATA;
                    end
                end

                // --------------------------------------------
                // DATA BITS
                // --------------------------------------------
                ST_DATA: begin
                    if (bit_ce) begin
                        tx      <= shreg[0];
                        shreg   <= {1'b0, shreg[7:1]};
                        bit_cnt <= bit_cnt + 1'b1;

                        if (bit_cnt == 3'd7)
                            state <= ST_STOP;
                    end
                end

                // --------------------------------------------
                // STOP BIT
                // --------------------------------------------
                ST_STOP: begin
                    if (bit_ce) begin
                        tx <= 1'b1;

                        // If we just sent the sync char, go idle
                        if (state == ST_STOP && shreg == 8'h00)
                            state <= ST_IDLE;
                        else
                            state <= ST_IDLE;

                        ready <= 1'b1;
                    end
                end

                default: state <= ST_BREAK;
            endcase
        end
    end

endmodule
