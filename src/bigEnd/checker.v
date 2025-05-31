`timescale 1ns / 1ps
module checker #(parameter N = 3)(
    input [N-1:0] errStream,
    input [N-1:0] inpStream,
    output [N-1:0] bitError,
    output error
);

assign error = ((errStream ^ inpStream) == 0) ? 0 : 1;

genvar i;
generate
    for (i = N-1; i >= 0; i = i - 1) begin
        assign bitError[i] = (errStream[i] != inpStream[i]);
    end
endgenerate

endmodule