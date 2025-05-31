`timescale  1ns/1ps
module crcEncode #(
    parameter N = 16,
    parameter R = 7,
    parameter [R-1:0] DIV = 7'b1111011
)(
    input  [N-1:0] stream,
    output [N+R-2:0] outStream
);

    integer i;
    reg [N+R-2:0] mes;
    reg [R-1:0] crc;

    // Helper function to extract R bits starting at index 'idx'
    function [R-1:0] get_slice;
        input [N+R-2:0] in;
        input integer idx;
        integer j;
        begin
            for (j = R; j > 0; j = j - 1)
                get_slice[j-1] = in[idx + (j-R)];
        end
    endfunction

    always @(*) begin
        crc = 0;
        // Append zeros onto the end of the message
        mes = {stream, {(R-1){1'b0}}};

        crc = get_slice(mes, N+R-2);

        // Polynomial division with XOR
        for (i = N-1; i >= 0; i = i - 1) begin
            if (crc[R-1])
                crc = crc ^ DIV;
            else
                crc = crc;
            if (i != 0) // Protection against negative indexing
                crc = {crc[R-2:0], mes[i-1]};
            //$display("Remainder: %b\n", crc);
        end

        mes = {stream, crc[R-2:0]};
    end

    assign outStream = mes;
    
endmodule

// I have to use polynomial g(x) = p(x)(1+x), where p(x)
// is a primitive polynomial of degree r - 1
// I have chosen p(x) = x^5 + x^3 + 1 in this case
// Thus g(x) = x^6 + x^5 + x^4 + x^3 + x + 1 or 1111011


// The output vector should be the sum of the number of data bits plus the length
// of the divisor minus one

// Using a primitive generator polynomial of the form g(x) = p(x)(1+x) where
// The degree of p(x) is T, the maximal block length of coverage is 2^T-1