module fifo_byte #(
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

    // control
    input  wire       flush,

    // status
    output reg [$clog2(DEPTH+1)-1:0] level,
    output wire                      almost_full,
    output wire                      almost_empty
);

    localparam ADDR_W = $clog2(DEPTH);

    reg [7:0] mem [0:DEPTH-1];
    reg [ADDR_W-1:0] rd_ptr;
    reg [ADDR_W-1:0] wr_ptr;

    wire do_write = wvalid && wready;
    wire do_read  = rvalid && rready;

    // ready / valid
    assign wready = (level < DEPTH);
    assign rvalid = (level > 0);

    assign almost_full  = (level >= AFULL_LEVEL);
    assign almost_empty = (level <= AEMPTY_LEVEL);

    always @(posedge clk) begin
        if (!reset_n || flush) begin
            rd_ptr <= 0;
            wr_ptr <= 0;
            level  <= 0;
        end else begin
            case ({do_write, do_read})
                2'b10: begin
                    mem[wr_ptr] <= wdata;
                    wr_ptr <= wr_ptr + 1'b1;
                    level  <= level + 1'b1;
                end
                2'b01: begin
                    rd_ptr <= rd_ptr + 1'b1;
                    level  <= level - 1'b1;
                end
                2'b11: begin
                    mem[wr_ptr] <= wdata;
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= rd_ptr + 1'b1;
                    // level unchanged
                end
                default: ;
            endcase
        end
    end

    // registered read data (safe for timing)
    always @(posedge clk) begin
        if (rvalid) begin
            rdata <= mem[rd_ptr];
        end
    end

endmodule
