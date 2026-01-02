`timescale 1ns/1ps

module ic_7400_tb;
    reg a, b;
    wire y;

    ic_7400 dut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        // Optional waveform dumping
        if ($test$plusargs("WAVES")) begin
            $dumpfile("ic_7400_tb.vcd");
            $dumpvars(0, ic_7400_tb);
        end

        $display("TEST ic_7400 (NAND)");

        a = 0; b = 0; #1;
        if (y !== 1) $fatal(1, "FAIL: 00");

        a = 0; b = 1; #1;
        if (y !== 1) $fatal(1, "FAIL: 01");

        a = 1; b = 0; #1;
        if (y !== 1) $fatal(1, "FAIL: 10");

        a = 1; b = 1; #1;
        if (y !== 0) $fatal(1, "FAIL: 11");

        $display("PASS ic_7400");
        $finish;
    end
endmodule
