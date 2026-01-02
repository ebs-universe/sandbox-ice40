
// nand_gate
module ic_7400 (
    input a,
    input b,
    output y 
);
    assign y=~(a & b);
endmodule

// 7401, nand_gate with open collector output, see 7400

// nor_gate
module ic_7402 (
    input a,
    input b,
    output y
);
    assign y=~(a | b);
endmodule

// 7403, nand_gate with open collector output, see 7400

// inverter
module ic_7404 (
    input a,
    output y 
);
    assign y=~a;
endmodule

// 7405, inverter with open collector output, see 7404
// 7406, inverter with 40mA open collector output, see 7404
// 7407, buffer with open collector output, see 74125

// and_gate 
module ic_7408 (
    input a,
    input b,
    output y 
);
    assign y=a & b;
endmodule

// 7409, and_gate with open collector output, see 7408

// 7410, 3-input nand_gate
// TODO

//7411, 3-input and_gate
// TODO

// 7412, 3-input nand_gate with open collector output, see 7410
// 7413, 4-input nand_gate with schmitt trigger inputs, see 7420
// 7414, inverter with schmitt trigger input, see 7404
// 7415, 3-input and_gate with open collector inputs, see 7411
// 7416, inverter with open collector inputs, see 7404
// 7417, buffer with open collector inputs, see 74125
// 7418, 4-input nand_gate with schmitt trigger inputs, see 7420
// 7419, inverter with schmitt trigger inputs, see 7404

// 7420, 4-input nand_gate
// TODO

// 7421, 4-input and_gate
// TODO

// 7422, 4-input nand_gate with open collector output, see 7420
// 7424, 2-input nand_gate with schmitt trigger inputs, see 7400

// 7425, 4-input nor_gate with enable input
// TODO

// 7426, 2-input nand_gate with open collector output, see 7400

// 7427, 3-input nor_gate
// TODO

// 7428, 2-input nor_gate with buffered output, see 7402

// 7431, delay element, 27.5ns, 46.5ns, 6ns
// TODO

// or_gate
module ic_7432 (
    input a,
    input b,
    output y 
);
    assign y=a | b;
endmodule

// 7433, nor_gate with open collector output, see 7402
// 7437, nand_gate with buffered output, see 7400
// 7438, nand_gate with open collector output, see 7400
// 7440, 4-input nand_gate with buffered output, see 7420

// 7442, bcd to decimal decoder
// TODO

// 7447, bcd to 7-segment decoder, common anode
// TODO

// 7448, bcd to 7-segment decoder, common cathode
// TODO

// 7451_a, 2-wide 2-input AND/NOR gate
// TODO

// 7451_b, 2-wide 3-input AND/NOR gate
// TODO

// 7454, 4-wide 2/3-input AND/NOR gate
// TODO

// 7455, 2-wide 4-input AND/NOR gate
// TODO

// 7457, Frequency divider
// TODO

// 7458_a, 2-wide 2-input AND/OR gate
// TODO

// 7458_b, 2-wide 3-input AND/OR gate
// TODO

// 7474, D Flip Flop
// TODO

// 7475, 2-bit Bistable Latch
// TODO

// 7476, JK Flip Flop with S/R
// TODO, see all JK FF implementations

// 7478, JK Flip Flop, negative edge triggered
// TODO, see all JK FF implementations

// 7483, 4-bit binary full adder
// TODO

// 7485, 4-bit magnitude comparator
// TODO

// xor_gate
module ic_7486 (
    input a,
    input b,
    output y
);
    assign y=a ^ b;
endmodule

// 7490, decade counter
// TODO

// 7491, 8-bit shift register
// TODO

// 7492, divide-by-12 counter
// TODO

// 7493, divide-by-16 counter
// TODO

// 7495, 4-bit shift register
// TODO

// 7496, 5-bit shift register
// TODO

// 74107, JK Flip Flop, negative edge triggered
// TODO, see all JK FF implementations

// 74109, JK Flip Flop with S/R, negative edge triggered
// TODO, see all JK FF implementations

// 74112, JK Flip Flop, negative edge triggered
// TODO, see all JK FF implementations

// 74113, JK Flip Flop, negative edge triggered
// TODO, see all JK FF implementations

// 74114, JK Flip Flop, negative edge triggered
// TODO, see all JK FF implementations

// 74121, monostable multivibrator, Not Digital
// 74122, monostable multivibrator, Not Digital
// 74123, monostable multivibrator, Not Digital

// buffer
module ic_74125 (
    input a,
    output y 
);
    assign y=a;
endmodule

// 74126, buffer with tri-state output, see 74125
// 74132, 2-input nand_gate with schmitt trigger inputs, see 7400

// 74133, 13-input nand_gate
// TODO

// 74136, 2-input xor_gate with open collector output, see 7486

// 74138, 3-to-8 line decoder
// TODO

// 74139, 2-to-4 line decoder 
// TODO

// 74145, 4-to-10 line decoder
// TODO

// 74147, 10-to-4 line priority encoder
// TODO

// 74151, 8-to-1 line multiplexer
// TODO

// 74155, 2-to-4 line decoder/demultiplexer
// TODO

// 74157, 4-bit 2-to-1 line multiplexer
// TODO

// 74164, 8-bit serial-in parallel-out shift register
// TODO

// 74165, 8-bit parallel-in serial-out shift register
// TODO

// 74221, monostable multivibrator, Not Digital

// 74238, 3-to-8 line decoder
// TODO, see 74138

// 74239, 2-to-4 line decoder
// TODO, see 74139

// 74240, inverter, see 7404
// 74241, buffer, see 74125
// 74244, buffer, see 74125
// 74245, buffer, see 74125

// xnor_gate
module ic_74266(
    input a,
    input b,
    output y
);
    assign y=~(a ^ b);
endmodule

// 74595, 8-bit serial-in parallel-out shift register with latched output
// TODO, see 74165

