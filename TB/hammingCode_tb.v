`timescale 1ns/1ps
module hammingCode_tb();

    // The value of N and R must satisfy the following equation:
    // 2^R >= N + R + 1 | minimize R as much as possible

    localparam N = 11;
    localparam R = 4;

    reg clk, reset;

    // Wires to hold the various data streams
    wire [1:N] stream;
    wire [1:(N+R)] errStream;
    wire [1:(N+R)] enStream;
    wire [1:N] outStream;

    // Wires to visualize correction and errors
    wire error;
    wire [1:N] bitError;

    // Produce data stream
    lfsr #(.N(N), .TAPS(5), .I('d2)) str (.clk(clk), .reset(reset), .q(stream));
    // Encode data stream with hamming
    hammingEncode #(.N(N), .R(R)) encoder (.stream(stream), .enStream(enStream));
    // Attack encoded data stream flipping random bits
    flipper #(.N(N+R)) flip (.clk(clk), .reset(reset), .stream(enStream), .out(errStream));
    // Decode attacked encoded data stream and correct errors
    hammingDecode #(.N(N), .R(R)) decoder (.enStream(errStream), .stream(outStream));
    // Check original data stream against decoded stream
    checker #(.N(N)) chk (.errStream(outStream), .inpStream(stream), .error(error), .bitError(bitError));

    // Save Waveform
    initial begin
        $dumpfile("output/hammingCode_tb.vcd");
        $dumpvars(0, hammingCode_tb);
    end

    // Initialize clock and reset
    initial begin
        clk = 0;
        reset = 1;
    end

    // Flip the clock every 10 ns
    always #10 clk = ~clk;

    initial begin
        #20 reset = 0;
        #2000 $finish;
    end
    
endmodule