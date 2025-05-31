`timescale 1ns/1ps
module crcDecode #(
    parameter N = 16,
    parameter R = 7,
    parameter [R-1:0] DIV = 7'b1111011
)(
    input [N+R-2:0] stream,
    output [N-1:0] outStream,
    output error
);

    integer i;
    reg [R-1:0] rem;

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
        rem = get_slice(stream, N+R-2);
        for (i = N-1; i >=0; i = i - 1) begin
            if (rem[R-1])
                rem = rem ^ DIV;
            else
                rem = rem;
            if (i != 0)
                rem = {rem[R-2:0], stream[i-1]};
        end
    end

    assign outStream = stream[N+R-2:R-1];
    assign error = (rem) ? 1 : 0;

endmodule