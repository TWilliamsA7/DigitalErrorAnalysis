`timescale  1ns/1ps
module bchTest_tb();

    localparam N = 16;
    localparam R = 7;

    reg clk, reset;

    reg [N-1:0] stream;
    reg [30:0] enStream;
    reg [30:0] errStream;
    reg [N-1:0] outStream;
    reg crcError;

    reg [N-1:0] bitError;
    reg error;

    initial begin
        $dumpfile("output/bchTest_tb.vcd");
        $dumpvars(0, bchTest_tb);
    end


    initial begin
        stream = 16'b1011001101101101;
        enStream = 31'b10110011011011011101001010011;
        errStream = 31'b10110011011011010101001010011;
        outStream = 16'b1011001101101101;
        error = 0;
        #10
        stream = 16'b0001111010010110;
        enStream = 31'b00011110100101100010111101100;
        errStream = 31'b00011110100101100010111100100;
        outStream = 16'b0001111010010110;
        error = 0;
        #10
        stream = 16'b1111000000001111;
        enStream = 31'b11110000000011111011100011001;
        errStream = 31'b11110000000011111011101011001;
        outStream = 16'b1111000000001111;
        error = 0;
        #10
        stream = 16'b0101010110101010;
        enStream = 31'b01010101101010100110011100110;
        errStream = 31'b01010101101010100110011100100;
        outStream = 16'b0101010110101010;
        error = 0;
        #10
        stream = 16'b1100110000110011;
        enStream = 31'b11001100001100111001110111010;
        errStream = 31'b11001100001100110001110111010;
        outStream = 16'b1100110000110011;
        error = 0;
        #10
        $finish;
    end

endmodule

// iverilog -o output/crc_tb.vcd TB/crc_tb.v src/crcEncode.v src/bigEnd/checker.v src/bigEnd/flipper.v src/bigEnd/lfsr.v src/crcDecode.v