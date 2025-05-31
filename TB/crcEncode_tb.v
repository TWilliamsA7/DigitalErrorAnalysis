`timescale  1ns/1ps
module crcEncode_tb();

    localparam N = 16;
    localparam R = 7;

    reg [N-1:0] stream;
    wire [N+R-2:0] outStream;

    crcEncode #(.N(N), .R(R), .DIV(7'b1111011)) uut (.stream(stream), .outStream(outStream));

    initial begin
        $dumpfile("output/crcEncode_tb.vcd");
        $dumpvars(0, crcEncode_tb);
    end

    initial begin
        stream = 16'b1110010100111101;
        #10
        $finish;
    end

endmodule