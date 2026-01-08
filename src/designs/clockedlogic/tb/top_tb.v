`timescale 1ns/1ps   // MUCH faster, still accurate for this design

module top_tb;

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------
    reg CLK = 0;

    // Simulate a slower clock to speed things up
    localparam integer SIM_CLK_HZ = 12_000_000; // 12 MHz

    // 12 MHz => 83.33 ns period
    always #41.666 CLK = ~CLK;

    // ------------------------------------------------------------
    // DIP switches
    // ------------------------------------------------------------
    reg DIP_S4 = 0;
    reg DIP_S3 = 0;
    reg DIP_S2 = 0;
    reg DIP_S1 = 1;   // step = 1 initially

    // ------------------------------------------------------------
    // LEDs
    // ------------------------------------------------------------
    wire LED_L1, LED_L2, LED_L3, LED_L4;
    wire LED_L5, LED_L6, LED_L7, LED_L8;
    wire LED_R, LED_G, LED_B;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    top #(
        .CLK_HZ(SIM_CLK_HZ)
    ) dut (
        .CLK    (CLK),

        .DIP_S4 (DIP_S4),
        .DIP_S3 (DIP_S3),
        .DIP_S2 (DIP_S2),
        .DIP_S1 (DIP_S1),

        .LED_L1 (LED_L1),
        .LED_L2 (LED_L2),
        .LED_L3 (LED_L3),
        .LED_L4 (LED_L4),
        .LED_L5 (LED_L5),
        .LED_L6 (LED_L6),
        .LED_L7 (LED_L7),
        .LED_L8 (LED_L8),

        .LED_R  (LED_R),
        .LED_G  (LED_G),
        .LED_B  (LED_B)
    );

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------
    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);

        // Run for ~3 seconds simulated time
        #1_000_000;

        // // Change step to 3
        // DIP_S2 = 1; // step = 3
        // #2_000_000;

        $finish;
    end

endmodule
