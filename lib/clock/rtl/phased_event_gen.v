module phased_event_gen #(
    parameter integer PERIOD_US = 1000,
    parameter integer PHASE_US  = 0
)(
    input        clk,
    input  [31:0] us,
    output reg   event = 0
);
    always @(posedge clk) begin
        if ((us % PERIOD_US) == PHASE_US)
            event <= 1;
        else
            event <= 0;
    end
endmodule
