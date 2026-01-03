module rgb_led (
    input r,
    input g,
    input b,
    output LED_R,
    output LED_G,
    output LED_B
);
    // iCESugar RGB LEDs are active-low
    assign LED_R = ~r;
    assign LED_G = ~g;
    assign LED_B = ~b;
endmodule
