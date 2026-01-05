module prescaler #(
    parameter integer N = 22
)(
    input clk_in, 
    output clk_out
);

    // Register for implementing the N bit counter
    // This is a synchronous binary counter; all bits update on clk_in.
    reg [N-1:0] count = 0;
    
    // The most significant bit goes through the output
    // Note that clk_out is : 
    //  - a derived clock, forming a separate clock domain from clk_in
    //  - probably not driven by a global clock buffer
    //  - a free-running divided clock with ~50% duty cycle, unlike 1-cycle timebase ticks
    //
    // WARNING: clk_out should not be used as a general-purpose clock
    //          inside FPGA fabric due to clock routing and skew issues
    assign clk_out = count[N-1];
    
    // Counter increments on each rising edge of clk_in
    always @(posedge(clk_in)) begin
        count <= count + 1;
    end

endmodule
