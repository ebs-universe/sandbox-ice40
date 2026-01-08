// ------------------------------------------------------------
// fifo8.v — 512-byte synchronous FIFO (control-optimized)
// ------------------------------------------------------------
// - Fixed depth: 512
// - Pointer-based full/empty detection
// - No clock enables
// - No level / almost_*
// - Same-cycle backpressure preserved
// ------------------------------------------------------------

module fifo8 (
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

    input  wire flush
);

    // ------------------------------------------------------------
    // Constants
    // ------------------------------------------------------------
    localparam DEPTH  = 512;
    localparam ADDR_W = 8;   // log2(512)

    // ------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------
    reg [7:0] mem [0:DEPTH-1];

    // 9-bit pointers: [8] = wrap bit, [7:0] = address
    reg [ADDR_W:0] wr_ptr;
    reg [ADDR_W:0] rd_ptr;

    // ------------------------------------------------------------
    // Full / Empty detection (combinational)
    // ------------------------------------------------------------
    wire fifo_empty = (wr_ptr == rd_ptr);

    wire fifo_full  =
        (wr_ptr[ADDR_W]     != rd_ptr[ADDR_W]) &&
        (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]);

    assign wready = !fifo_full;
    assign rvalid = !fifo_empty;

    // ------------------------------------------------------------
    // Handshakes
    // ------------------------------------------------------------
    wire do_write = wvalid && wready;
    wire do_read  = rvalid && rready;

    // ------------------------------------------------------------
    // Write pointer (unconditional register)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n || flush)
            wr_ptr <= { (ADDR_W+1){1'b0} };
        else
            wr_ptr <= wr_ptr + {{ADDR_W{1'b0}}, do_write};
    end

    // ------------------------------------------------------------
    // Read pointer (unconditional register)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n || flush)
            rd_ptr <= { (ADDR_W+1){1'b0} };
        else
            rd_ptr <= rd_ptr + {{ADDR_W{1'b0}}, do_read};
    end

    // ------------------------------------------------------------
    // Memory write
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (do_write)
            mem[wr_ptr[ADDR_W-1:0]] <= wdata;
    end

    // ------------------------------------------------------------
    // Memory read (unconditional)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        rdata <= mem[rd_ptr[ADDR_W-1:0]];
    end

endmodule
