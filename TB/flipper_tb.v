`timescale 1ns/1ps
module flipper_tb();
    localparam N = 5;
    reg clk, reset;
    wire [1:N] stream;
    wire [1:N] q;
    wire [1:N] bitError;
    wire error;


    lfsr #(.N(N), .TAPS(5'b00101), .I('d2)) str (.clk(clk), .reset(reset), .q(stream));

    // Instantiate unit under test
    flipper #(.N(N)) uut (.clk(clk), .reset(reset), .stream(stream), .out(q));

    checker #(.N(N)) chk (.errStream(q), .inpStream(stream), .error(error), .bitError(bitError));

    // Dumpfile and dumpvars for waveform generation
    initial begin
        $dumpfile("output/flipper_tb.vcd"); // Specify dump file name
        $dumpvars(0, flipper_tb); // Dump all signals in the testbench
    end

    initial begin
        // Initialize the clock to 0
        clk = 0; 
        // Keep the register in resting state
        reset = 1;
    end

    // Toggle the clock every 10ns
    always #10 clk = ~clk;

    initial begin
        // End the rest cycle
        #20 reset = 0;
        // End the simulation after 500ns
        #1000 $finish;
    end

endmodule