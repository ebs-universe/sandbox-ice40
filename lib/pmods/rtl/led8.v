module led8 (
    input  [7:0] val,
    output LED_L1,
    output LED_L2,
    output LED_L3,
    output LED_L4,
    output LED_L5,
    output LED_L6,
    output LED_L7,
    output LED_L8
);
    // MSB on LED_L8, LSB on LED_L1
    assign {
        LED_L8,
        LED_L7,
        LED_L6,
        LED_L5,
        LED_L4,
        LED_L3,
        LED_L2,
        LED_L1
    } = val;
endmodule
