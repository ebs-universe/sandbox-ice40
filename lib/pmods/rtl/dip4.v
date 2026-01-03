module dip4 (
    input DIP_S4,
    input DIP_S3,
    input DIP_S2,
    input DIP_S1,
    output [3:0] val
);
    // DIP_S4 = MSB, DIP_S1 = LSB
    assign val = {
        DIP_S4,
        DIP_S3,
        DIP_S2,
        DIP_S1
    };
endmodule
