// ------------------------------------------------------------
// fifo8.v — 512-byte synchronous FIFO with pipelined write
// ------------------------------------------------------------
// - Fixed depth: 512 (power of two)
// - Pointer-based full/empty detection
// - 1-cycle pipelined write using write_pending flag
// - No adders in ready path
// - No clock enables
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

    // Pointers: [8] = wrap bit, [7:0] = address
    reg [ADDR_W:0] wr_ptr;
    reg [ADDR_W:0] rd_ptr;

    // ------------------------------------------------------------
    // Write pipeline state
    // ------------------------------------------------------------
    reg             write_pending;
    reg [7:0]       wdata_d;
    reg [ADDR_W-1:0] wr_addr_d;

    // ------------------------------------------------------------
    // Empty detection (unchanged)
    // ------------------------------------------------------------
    wire fifo_empty = (wr_ptr == rd_ptr);

    // ------------------------------------------------------------
    // Full detection (NO ADDERS)
    // ------------------------------------------------------------
    wire fifo_full_now =
        (wr_ptr[ADDR_W]     != rd_ptr[ADDR_W]) &&
        (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]);

    // FIFO is not ready if:
    //  - it is full now, OR
    //  - a write is already pending commit
    assign wready = !fifo_full_now && !write_pending;
    assign rvalid = !fifo_empty;

    // ------------------------------------------------------------
    // Handshakes
    // ------------------------------------------------------------
    wire do_write = wvalid && wready;
    wire do_read  = rvalid && rready;

    // ------------------------------------------------------------
    // Write decision pipeline (cycle N)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n || flush) begin
            write_pending <= 1'b0;
            wdata_d       <= 8'd0;
            wr_addr_d     <= {ADDR_W{1'b0}};
        end else begin
            // latch a new write request
            if (do_write) begin
                write_pending <= 1'b1;
                wdata_d       <= wdata;
                wr_addr_d     <= wr_ptr[ADDR_W-1:0];
            end else begin
                write_pending <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // Write commit (cycle N+1)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n || flush)
            wr_ptr <= { (ADDR_W+1){1'b0} };
        else
            wr_ptr <= wr_ptr + {{ADDR_W{1'b0}}, write_pending};
    end

    always @(posedge clk) begin
        if (write_pending)
            mem[wr_addr_d] <= wdata_d;
    end

    // ------------------------------------------------------------
    // Read pointer (unchanged)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n || flush)
            rd_ptr <= { (ADDR_W+1){1'b0} };
        else
            rd_ptr <= rd_ptr + {{ADDR_W{1'b0}}, do_read};
    end

    // ------------------------------------------------------------
    // Memory read (unchanged)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        rdata <= mem[rd_ptr[ADDR_W-1:0]];
    end

endmodule
