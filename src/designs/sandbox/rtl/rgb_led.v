// module rgb_led (
//     input r,
//     input g,
//     input b,
//     output LED_R,
//     output LED_G,
//     output LED_B
// );
//     // iCESugar RGB LEDs are active-low
//     assign LED_R = ~r;
//     assign LED_G = ~g;
//     assign LED_B = ~b;
// endmodule

module rgb_led (
    input  r,
    input  g,
    input  b,
    output LED_R,
    output LED_G,
    output LED_B
);

    // On-chip RGB LED driver
    // iCE40UP5K has exactly ONE of these blocks
    SB_RGBA_DRV #(
        .CURRENT_MODE("0b1"),      // Enable programmable current
        .RGB0_CURRENT("0b000001"), // ~2 mA (R)
        .RGB1_CURRENT("0b000001"), // ~2 mA (G)
        .RGB2_CURRENT("0b000001")  // ~2 mA (B)
    ) rgb_drv (
        .CURREN   (1'b1),  // Enable current source
        .RGBLEDEN (1'b1),  // Enable LED driver

        // PWM / enable inputs (active-high)
        .RGB0PWM  (r),
        .RGB1PWM  (g),
        .RGB2PWM  (b),

        // Physical LED pins (active-low sinks)
        .RGB0     (LED_R),
        .RGB1     (LED_G),
        .RGB2     (LED_B)
    );

endmodule
