module shift8 #(
    parameter [7:0] INITIAL = 8'h00
)(
    input               clk,
    input               reset_n,
    input               enable,
    input               d_in,
    output  reg [7:0]   data = INITIAL,  
    output  reg         d_out = 1'b0    
);

    reg init_done;

    always @(posedge clk) begin
        if (!reset_n) begin
            data      <= INITIAL;
            d_out     <= 1'b0;
            init_done <= 1'b0;
        end else if (!init_done) begin
            data      <= INITIAL;
            d_out     <= 1'b0;
            init_done <= 1'b1;
        end else if (enable) begin
            d_out <= data[7];
            data  <= {data[6:0], d_in};
        end
    end
endmodule
