module top(input CLK, output LED_R, output LED_G, output LED_B);
    localparam N = 23;
    reg [N:0] counter = 0;
    
    assign LED_B = ~counter[N];
    assign LED_R = ~counter[N-1];
    assign LED_G = ~counter[N-2];
    
    always @(posedge CLK)
    begin
        counter <= counter + 1;
    end
endmodule //top