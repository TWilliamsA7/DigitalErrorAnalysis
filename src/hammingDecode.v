`timescale 1ns / 1ps
module hammingDecode #(parameter N = 7, parameter R = 4)(
    input [1:(N+R)] enStream,
    output [1:N] stream
);

    reg [1:N] q_stream;
    reg [1:R] power;
    reg [1:R] syndrome;
    reg [1:(N+R)] q_enStream;

    integer i, j, k, parSum;

    
    always @(*) begin
        q_enStream = enStream;
        syndrome = 0;
        // Recalculate and compare the parity bits
        for (i = 0; i < R; i = i + 1) begin
            power = 1 << i;
            parSum = 0;
            for (j = 1; j <= (N+R); j = j + 1) begin
                if (((j & power) != 0) && (power != j)) begin
                    parSum = parSum + q_enStream[j];
                end
            end
            // Generate Syndrome vector
            syndrome[R-i] = (parSum & 1'b1) ^ q_enStream[power];
        end

        // Correct the bit error (if it exists)
        if (syndrome) begin
            q_enStream[syndrome] = q_enStream[syndrome] ^ 1;
        end
    end

    // Reconstruct data stream from code word
    always @(*) begin
        k = 1;
        for (i = 1; i <= (N+R); i = i + 1) begin
            // Only append if it is a data bit
            if ((i & (i - 1)) != 0) begin
                q_stream[k] = q_enStream[i];
                k = k + 1;
            end
        end
    end

    assign stream = q_stream;

endmodule

/* Module Goal:
    I need to take in the hamming code word data chunk
    Recompute the parity bits of the data chunk
    Compare the parity bits with those sent in the code word
    Create a syndrome vector of the mismatches
        1 in the place of a mismatch, 0 otherwise
    The decimal value of this vector is the location of the error
        0 - There is no error present
        power of 2 - A parity bit is incorrect
        decimal - This bit position has been flipped
    Correct the error by XORing it with 1
    Reconstruct the original data chunk and output
*/