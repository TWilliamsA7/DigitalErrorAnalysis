`timescale 1ns/1ps
module syndromeCalc #(
    parameter N = 31,        // Codeword length
    parameter T = 3,         // t-error correcting capability, so we compute 2*T syndromes
    parameter m = 5          // Finite field GF(2^m)
)(
    input  [N-1:0] r,        // Received codeword
    // Array of syndrome values: S1 to S(2T)
    output reg [m-1:0] syndrome1,
    output reg  [m-1:0] syndrome2,
    output reg  [m-1:0] syndrome3,
    output reg [m-1:0] syndrome4,
    output reg [m-1:0] syndrome5,
    output reg [m-1:0] syndrome6 
);

    integer i, j;
    
    function automatic [m-1:0] gfPow;
        input integer i;
        input integer j;
        reg [m-1:0] result;
        reg [m-1:0] addr;
        begin
            // Compute (i * j) modulo (2^m - 1) = modulo 15 for m=4
            addr = ((i * j) % 31);
            case (addr)
                0:  result = 5'b00001; // 1
                1:  result = 5'b00010; // 2
                2:  result = 5'b00100; // 4
                3:  result = 5'b01000; // 8
                4:  result = 5'b10000; // 16
                5:  result = 5'b00101; // 5
                6:  result = 5'b01010; // 10
                7:  result = 5'b10100; // 20
                8:  result = 5'b01101; // 13
                9:  result = 5'b11010; // 26
                10: result = 5'b10001; // 17
                11: result = 5'b00111; // 7
                12: result = 5'b01110; // 14
                13: result = 5'b11100; // 28
                14: result = 5'b11101; // 29
                15: result = 5'b11111; // 31
                16: result = 5'b11011; // 27
                17: result = 5'b10011; // 19
                18: result = 5'b01011; // 11
                19: result = 5'b10110; // 22
                20: result = 5'b01001; // 9
                21: result = 5'b10010; // 18
                22: result = 5'b00011; // 3
                23: result = 5'b00110; // 6
                24: result = 5'b01100; // 12
                25: result = 5'b11000; // 24
                26: result = 5'b10101; // 21
                27: result = 5'b01111; // 15
                28: result = 5'b11110; // 30
                29: result = 5'b11001; // 25
                30: result = 5'b10111; // 23
                default: result = 5'b00000;
            endcase
            gfPow = result;
        end
    endfunction



    always @(*) begin
        // Initialize syndrome value to 0
        syndrome1 = 0;
        syndrome2 = 0;
        syndrome3 = 0;
        syndrome4 = 0;
        syndrome5 = 0;
        syndrome6 = 0;
        // Evaluate S_i = Σ r[j] * α^(i*j) for j=0 to N-1 (over GF(2^m))
        for (j = 0; j < N; j = j + 1) begin
            if (r[j]) begin
                syndrome1 = syndrome1 ^ gfPow(1, j);
                syndrome2 = syndrome2 ^ gfPow(2, j);
                syndrome3 = syndrome3 ^ gfPow(3, j);
                syndrome4 = syndrome4 ^ gfPow(4, j);
                syndrome5 = syndrome5 ^ gfPow(5, j);
                syndrome6 = syndrome6 ^ gfPow(6, j);
            end
        end
    end

endmodule


// GF(2^5): polynomial is x^5 + x^2 + 1
// T must be chosen such that 2t <= N - k