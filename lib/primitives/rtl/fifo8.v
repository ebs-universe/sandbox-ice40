// ------------------------------------------------------------
// fifo8.v — 512-byte FIFO, CE-free, registered empty
// ------------------------------------------------------------
// - Fixed depth: 512
// - Pipelined write (write_pending)
// - Internal 1-entry read buffer
// - Unconditional RAM access (no CEN)
// - fifo_empty registered to break ptr feedback loop
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
    output reg        rvalid,
    input  wire       rready,

    input  wire flush
);

    localparam DEPTH  = 512;
    localparam ADDR_W = 8;

    // ------------------------------------------------------------
    // Memory
    // ------------------------------------------------------------
    reg [7:0] mem [0:DEPTH-1];

    // ------------------------------------------------------------
    // Pointers
    // ------------------------------------------------------------
    reg [ADDR_W:0] wr_ptr;
    reg [ADDR_W:0] rd_ptr;

    // ------------------------------------------------------------
    // Write pipeline
    // ------------------------------------------------------------
    reg              write_pending;
    reg [7:0]        wdata_d;
    reg [ADDR_W-1:0] wr_addr_d;

    wire fifo_full =
        (wr_ptr[ADDR_W]     != rd_ptr[ADDR_W]) &&
        (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]);

    assign wready = !fifo_full && !write_pending;
    wire do_write = wvalid && wready;

    // Write decision stage
    always @(posedge clk) begin
        if (!reset_n || flush) begin
            write_pending <= 1'b0;
            wdata_d       <= 8'd0;
            wr_addr_d     <= {ADDR_W{1'b0}};
        end else begin
            write_pending <= do_write;
            wdata_d       <= wdata;
            wr_addr_d     <= wr_ptr[ADDR_W-1:0];
        end
    end

    // Write commit (no CEN)
    always @(posedge clk) begin
        if (!reset_n || flush)
            wr_ptr <= { (ADDR_W+1){1'b0} };
        else
            wr_ptr <= wr_ptr + {{ADDR_W{1'b0}}, write_pending};
    end

    always @(posedge clk) begin
        mem[wr_addr_d] <= wdata_d;
    end

    // ------------------------------------------------------------
    // Registered empty detection
    // ------------------------------------------------------------
    reg fifo_empty_r;

    always @(posedge clk) begin
        if (!reset_n || flush)
            fifo_empty_r <= 1'b1;
        else
            fifo_empty_r <= (wr_ptr == rd_ptr);
    end

    // ------------------------------------------------------------
    // Read side with internal buffer
    // ------------------------------------------------------------
    wire fill_buf = !rvalid && !fifo_empty_r;
    wire consume  = rvalid && rready;

    // Unconditional RAM read
    wire [7:0] mem_rdata = mem[rd_ptr[ADDR_W-1:0]];

    always @(posedge clk) begin
        if (!reset_n || flush) begin
            rdata  <= 8'd0;
            rvalid <= 1'b0;
        end else begin
            if (consume)
                rvalid <= 1'b0;

            if (fill_buf) begin
                rdata  <= mem_rdata;
                rvalid <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------
    // Read pointer advance (no CEN)
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n || flush)
            rd_ptr <= { (ADDR_W+1){1'b0} };
        else
            rd_ptr <= rd_ptr + {{ADDR_W{1'b0}}, fill_buf};
    end

endmodule
