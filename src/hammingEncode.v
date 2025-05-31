`timescale 1ns / 1ps
module hammingEncode #(parameter N = 7, parameter R = 4)(
    input [1:N] stream,
    output [1:(N+R)] enStream
);

    // These are counter variables
    integer i, j, k, parSum;

    // Register to hold intermed. value of encoded Stream
    reg [1:(N+R)] q_enStream;
    reg [1:R] power;

    always @(*) begin
        k = N;
        // Assign the data bits into new stream
        for (i = (N+R); i > 0; i = i -1) begin
            // If i is a power of two, plug 0
            if ((i & (i-1)) == 0)
                q_enStream[i] = 0;
            else begin
                q_enStream[i] = stream[k];
                k = k - 1;
            end
        end

        for (i = 0; i < R; i = i + 1) begin
            power = 1 << i;
            parSum = 0;
            for (j = 1; j <= (N+R); j = j + 1) begin
                if ((j & power) != 0) begin
                    parSum = parSum + q_enStream[j];
                end
            end
            if ((parSum & 1) == 0)
                q_enStream[power] = 0;
            else
                q_enStream[power] = 1;
        end
    end

    assign enStream = q_enStream;

endmodule

/*  Module Goal:
        This module needs to encode a data chunk with parity bits
        These will be even parity bits

        There should be a parameter for the size of the input data
        There should also be a parameter for the number of parity bits
            This could also be calculated based on:
                2^r >= m + r +1
                r is the number of parity bits
                m is the number of data bits

        The parity bits are located in the positions 2^r, counting up inclusively to r from 0
        To calculate exponents of two, we can shift left (whichever is up)


        The size of the ouput vector is based on the above formula (m + r)

        The data is stored in any bit position except those of power two
    */