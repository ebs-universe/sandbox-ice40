module reset #(
    parameter integer RESET_ASSERT_CYCLES = 48_000  // 1 ms @ 48 MHz
)(
    input  wire clk,
    input  wire pll_lock,
    input  wire ext_reset_n,
    output wire reset_n
);

    // ------------------------------------------------------------
    // Synchronize external reset (async assert, sync deassert)
    // ------------------------------------------------------------

    reg [1:0] ext_rst_sync;

    always @(posedge clk or negedge ext_reset_n) begin
        if (!ext_reset_n)
            ext_rst_sync <= 2'b00;
        else
            ext_rst_sync <= {ext_rst_sync[0], 1'b1};
    end

    wire ext_reset_sync_n = ext_rst_sync[1];

    // ------------------------------------------------------------
    // Synchronize PLL lock
    // ------------------------------------------------------------

    reg [1:0] pll_lock_sync;

    always @(posedge clk) begin
        pll_lock_sync <= {pll_lock_sync[0], pll_lock};
    end

    wire pll_lock_syncd = pll_lock_sync[1];

    // ------------------------------------------------------------
    // Qualify reset assertion width (counter)
    // ------------------------------------------------------------

    localparam integer RST_CNT_W = $clog2(RESET_ASSERT_CYCLES + 1);
    reg [RST_CNT_W-1:0] rst_cnt;
    reg                reset_req;   // latched request

    always @(posedge clk) begin
        if (!ext_reset_sync_n) begin
            // reset held low → count
            if (rst_cnt != RESET_ASSERT_CYCLES[RST_CNT_W-1:0])
                rst_cnt <= rst_cnt + 1'b1;
        end else begin
            // reset released → clear counter
            rst_cnt <= {RST_CNT_W{1'b0}};
        end

        // Latch a valid reset request
        if (rst_cnt == RESET_ASSERT_CYCLES[RST_CNT_W-1:0])
            reset_req <= 1'b1;
        else if (ext_reset_sync_n && pll_lock_syncd)
            reset_req <= 1'b0;
    end

    // ------------------------------------------------------------
    // Generate reset_n (active-low reset)
    // ------------------------------------------------------------

    assign reset_n = ~reset_req;

endmodule
