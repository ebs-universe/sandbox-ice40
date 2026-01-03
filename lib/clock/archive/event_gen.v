module event_gen #(
    parameter integer PERIOD_US = 1000
)(
    input        clk,
    input  [31:0] us,
    output reg   event = 0
);
    reg [31:0] last_us = 0;

    always @(posedge clk) begin
        if ((us - last_us) >= PERIOD_US) begin
            last_us <= us;
            event   <= 1;
        end else begin
            event   <= 0;
        end
    end
endmodule
