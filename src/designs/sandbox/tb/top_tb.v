`timescale 1ns/1ps

module top_tb;

    reg CLK = 0;
    wire LED_R, LED_G, LED_B;

    // Instantiate DUT
    top dut (
        .CLK(CLK),
        .LED_R(LED_R),
        .LED_G(LED_G),
        .LED_B(LED_B)
    );

    // Clock: 12 MHz equivalent (approx)
    always #41.666 CLK = ~CLK;

    initial begin
        // Dump waveforms
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);

        // Run long enough to see LED toggles
        #5_000_000;
        $finish;
    end

endmodule
