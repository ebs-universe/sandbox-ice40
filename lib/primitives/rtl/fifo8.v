module fifo8 #(
    parameter integer DEPTH = 1024,
    parameter integer AFULL_LEVEL  = DEPTH - 8,
    parameter integer AEMPTY_LEVEL = 8
)(
    input  wire clk,
    input  wire reset_n,

    // write interface
    input  wire [7:0] wdata,
    input  wire       wvalid,
    output wire       wready,

    // read interface
    output reg  [7:0] rdata,
    output wire       rvalid,
    input  wire       rready,

    input  wire flush,

    output reg [$clog2(DEPTH+1)-1:0] level,
    output wire almost_full,
    output wire almost_empty
);

    localparam ADDR_W = $clog2(DEPTH);

    reg [7:0] mem [0:DEPTH-1];
    reg [ADDR_W-1:0] rd_ptr;
    reg [ADDR_W-1:0] wr_ptr;

    reg fifo_not_full;
    reg fifo_not_empty;

    always @(posedge clk) begin
        if (!reset_n || flush) begin
            fifo_not_full  <= 1'b1;
            fifo_not_empty <= 1'b0;
        end else begin
            fifo_not_full  <= (level != DEPTH);
            fifo_not_empty <= (level != 0);
        end
    end

    // ------------------------------------------------------------
    // Status / handshake
    // ------------------------------------------------------------
    wire do_write = wvalid && fifo_not_full;
    wire do_read  = rready && fifo_not_empty;

    assign wready = fifo_not_full;
    assign rvalid = fifo_not_empty;

    assign almost_full  = (level >= AFULL_LEVEL);
    assign almost_empty = (level <= AEMPTY_LEVEL);

    // ------------------------------------------------------------
    // Pointers and level (NO clock enables)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n || flush) begin
            rd_ptr <= {ADDR_W{1'b0}};
            wr_ptr <= {ADDR_W{1'b0}};
            level  <= {($clog2(DEPTH+1)){1'b0}};
        end else begin
            // write pointer
            wr_ptr <= wr_ptr + {{(ADDR_W-1){1'b0}}, do_write};

            // read pointer
            rd_ptr <= do_read  ? (rd_ptr + 1'b1) : rd_ptr;

            // level update
            level <= level
               + {{($clog2(DEPTH+1)-1){1'b0}}, do_write}
               - {{($clog2(DEPTH+1)-1){1'b0}}, do_read};
        end
    end

    // ------------------------------------------------------------
    // Memory write (local enable only)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        mem[wr_ptr] <= do_write ? wdata : mem[wr_ptr];
    end

    // ------------------------------------------------------------
    // Unconditional read (unchanged)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        rdata <= mem[rd_ptr];
    end

endmodule
