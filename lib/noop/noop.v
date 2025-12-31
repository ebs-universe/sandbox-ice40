// noop.v
// Trivial library module that does nothing

module noop (
    input  wire in,
    output wire out
);
    assign out = in;
endmodule