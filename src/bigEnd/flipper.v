`timescale 1ns / 1ps
module flipper #(parameter N = 3)(
    input clk,
    input reset,
    input [N-1:0] stream,
    output [N-1:0] out
);

/* Module Goal:
    Take in a stream of data in N bit sized chunks
    Output the stream after flipping some number of bits in random places

    Determine how many bits to flip:
        Should be between 0 to 33% of the data chunk
        Randomly decided based on an lfsr

    Determine which bits to flip:
        Should be determined by a separate lfsr, with range size of N

    How to flip the bits:
        XOR the determined bits with 1 to flip them

    Possibly could xor two numbers together to reduce number of 1s, Could and them together
    
*/

reg [N-1:0] q_out;
wire [N-1:0] flips;
wire [N-1:0] imd1, imd2, imd3;

// LFSR to generate random numbers
lfsr #(.N(N), .TAPS('d7), .I('d3)) v1 (.clk(clk), .reset(reset), .q(imd1));
//lfsr #(.N(N), .TAPS('d5), .I('d1)) v2 (.clk(clk), .reset(reset), .q(imd2));
lfsr #(.N(N), .TAPS('d3), .I('d7)) v3 (.clk(clk), .reset(reset), .q(imd3));

// AND the numbers together to reduce the number of ones in flip vector
assign flips = imd1 ^ imd3;

// XOR the flip vector with the data stream
always @(*)
    q_out = flips ^ stream;

// Assign the out vector to output
assign out = q_out;


endmodule
