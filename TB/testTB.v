`timescale 1ns/1ps
module tb_full_adder;
    // Declare testbench signals
    reg a, b, c_in;
    wire sum, carry_out;

    // Instantiate the full adder module
    full_adder dut (a, b, c_in, sum, carry_out);

    // Dumpfile and dumpvars for waveform generation
    initial begin
        $dumpfile("test.vcd"); // Specify dump file name
        $dumpvars(0, tb_full_adder); // Dump all signals in the testbench
    end

    // Apply test stimulus
    initial begin
        $display("Testing Full Adder");
        $monitor("a = %b, b = %b, c_in = %b, sum = %b, carry_out = %b", a, b, c_in, sum, carry_out);

        // Apply various test cases
        a = 0; b = 0; c_in = 0; #10 // Expect sum = 0, carry_out = 0
        a = 1; b = 0; c_in = 0; #10 // Expect sum = 1, carry_out = 0
        a = 0; b = 1; c_in = 0; #10 // Expect sum = 1, carry_out = 0
        a = 1; b = 1; c_in = 0; #10 // Expect sum = 0, carry_out = 1
        $finish;
    end
endmodule