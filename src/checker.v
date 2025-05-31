`timescale 1ns / 1ps
module checker #(parameter N = 3)(
    input [1:N] errStream,
    input [1:N] inpStream,
    output [1:N] bitError,
    output error
);

assign error = ((errStream ^ inpStream) == 0) ? 0 : 1;

genvar i;
generate
    for (i = 1; i <= N; i = i + 1) begin
        assign bitError[i] = (errStream[i] != inpStream[i]);
    end
endgenerate

endmodule