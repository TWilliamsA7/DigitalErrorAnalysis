`timescale 1ns / 1ps

// The range of numbers accessible by the lfsr is 2^N - 1 with optimal tap placement

module lfsr #(parameter N = 3, parameter [1:N] TAPS = 3'b011, parameter I = 1)(
    input clk,
    input reset,
    output [1:N] q
);

reg [1:N] q_reg, q_next;
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
    q_next = {feedback, q_reg[1:N-1]};

// Output logic
assign q = q_reg;

// Assign feedback bit based on user defined taps
assign feedback = ^(q_reg & TAPS);

endmodule
