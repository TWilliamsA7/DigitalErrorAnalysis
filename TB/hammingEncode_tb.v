`timescale 1ns/1ps
module hammingEncode_tb ();
    localparam N = 7;
    localparam R = 4;
    reg [1:N] stream;
    wire [1:(N+R)] enStream;

    hammingEncode #(.N(N), .R(R)) uut (.stream(stream), .enStream(enStream));

    initial begin
        $dumpfile("output/hammingEncode_tb.vcd"); // Specify dump file name
        $dumpvars(0, hammingEncode_tb); // Dump all signals in the testbench
    end

    initial begin
        // End the rest cycle
        stream = 12;
        #10
        stream = 5;
        #10
        stream = 37;
        #10
        stream = 43;
        #10
        stream = 72;
        #10
        stream = 14;
        $finish;
    end


endmodule