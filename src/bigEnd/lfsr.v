`timescale 1ns / 1ps

// The range of numbers accessible by the lfsr is 2^N - 1 with optimal tap placement

module lfsr #(parameter N = 3, parameter [N-1:0] TAPS = 3'b011, parameter I = 1)(
    input clk,
    input reset,
    output [N-1:0] q
);

reg [N-1:0] q_reg, q_next;
wire feedback;

// State transion logic
always @(posedge clk) begin
    if (reset) // Reset to inital state of 1
        q_reg <= I;
    else // Push the next state
        q_reg <= q_next;
end

// Set next state
always @(*)
    q_next = {feedback, q_reg[N-1:1]};

// Output logic
assign q = q_reg;

// Assign feedback bit based on user defined taps
assign feedback = ^(q_reg & TAPS);

endmodule
