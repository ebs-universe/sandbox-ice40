module reset (
    input  wire clk,
    input  wire pll_lock,
    input  wire ext_reset_n,
    output wire reset_n
);

    wire reset_req_n;
    wire reset_sync_n;

    // Reset policy
    assign reset_req_n = pll_lock & ext_reset_n;

    // CDC primitive
    sync1 #(
        .STAGES(2)
    ) u_sync (
        .clk  (clk),
        .din  (reset_req_n),
        .dout (reset_sync_n)
    );

    assign reset_n = reset_sync_n;

endmodule
