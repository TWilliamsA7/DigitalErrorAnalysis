`timescale  1ns/1ps
module crc_tb();

    localparam N = 16;
    localparam R = 7;

    reg clk, reset;

    wire [N-1:0] stream;
    wire [N+R-2:0] enStream;
    wire [N+R-2:0] errStream;
    wire [N-1:0] outStream;
    wire crcError;

    wire [N-1:0] bitError;
    wire error;

    lfsr #(.N(N), .TAPS(5), .I('d2)) str (.clk(clk), .reset(reset), .q(stream));
    crcEncode #(.N(N), .R(R), .DIV(7'b1111011)) uut1 (.stream(stream), .outStream(enStream));
    flipper #(.N(N+R-1)) flip (.clk(clk), .reset(reset), .stream(enStream), .out(errStream));

    crcDecode #(.N(N), .R(R), .DIV(7'b1111011)) uut2 (.stream(errStream), .outStream(outStream), .error(crcError));
    checker #(.N(N)) chk (.errStream(outStream), .inpStream(stream), .error(error), .bitError(bitError));

    initial begin
        $dumpfile("output/crc_tb.vcd");
        $dumpvars(0, crc_tb);
    end

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

// iverilog -o output/crc_tb.vcd TB/crc_tb.v src/crcEncode.v src/bigEnd/checker.v src/bigEnd/flipper.v src/bigEnd/lfsr.v src/crcDecode.v