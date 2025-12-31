module top(input clk, output LED_R, output LED_G, output LED_B);
    reg [25:0] counter = 0;
    
    assign LED_B = ~counter[22];
    assign LED_R = ~counter[21];
    assign LED_G = ~counter[23];
    
    always @(posedge clk)
    begin
        counter <= counter + 1;
    end
endmodule //top