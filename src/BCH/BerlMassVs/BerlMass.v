`timescale 1ns/1ps
module BerlMass #(
    parameter N = 31,
    parameter m = 5,
    parameter T = 3
) (
    input clk,
    input reset,
    input [m-1:0] syndrome0,
    input  [m-1:0] syndrome1,
    input  [m-1:0] syndrome2,
    input [m-1:0] syndrome3,
    input [m-1:0] syndrome4,
    input [m-1:0] syndrome5, 
    //input [m-1:0] syndrome [0:2*T-1],
    output reg done, // Indicate BM algorithm completion
    //output reg [m-1:0] sigma [0:3], // Error locator polynomial sigma coefficients
    output reg [m-1:0] sigma0,
    output reg [m-1:0] sigma1,
    output reg [m-1:0] sigma2,
    output reg [m-1:0] sigma3,
    output reg [3:0] L // Degree of sigma(x)
);

    // Internal registers for BM algorithm
    // B(x), sigma_old to store temporary polynomial, iteration index n, and m counter
    //reg [m-1:0] B [0:3];           // Helper polynomial B(x)
    reg [m-1:0] B0;
    reg [m-1:0] B1;
    reg [m-1:0] B2;
    reg [m-1:0] B3; 
    //reg [m-1:0] sigma_old [0:3];   // To hold previous sigma(x)
    reg [m-1:0] sigma_old0;
    reg [m-1:0] sigma_old1;
    reg [m-1:0] sigma_old2;
    reg [m-1:0] sigma_old3;
    reg [3:0] n;                 // iteration index (0 to 5)
    reg [3:0] m_counter;         // m, gap since last update

    integer i;
    integer j;

    // Discrepancy d (GF element, 5 bits)
    reg [m-1:0] d;
    
    // FSM state encoding
    //typedef enum reg [2:0] { IDLE, CALC_D, UPDATE, NEXT, DONE } state_t;
    //state_t state, next_state;
 
    // 0: IDLE, 1: CALC_D, 2: UPDATE, 3: NEXT, 4: DONE
    reg [2:0] state;
    reg [2:0] next_state;


    function automatic [4:0] gfExp;  // returns a 5-bit element
        input [4:0] exponent;  // exponent, assume it is in 0..30
        begin
            case (exponent)
                5'd0:  gfExp = 5'b00001; // 1
                5'd1:  gfExp = 5'b00010; // 2
                5'd2:  gfExp = 5'b00100; // 4
                5'd3:  gfExp = 5'b01000; // 8
                5'd4:  gfExp = 5'b10000; // 16
                5'd5:  gfExp = 5'b00101; // 5
                5'd6:  gfExp = 5'b01010; // 10
                5'd7:  gfExp = 5'b10100; // 20
                5'd8:  gfExp = 5'b01101; // 13
                5'd9:  gfExp = 5'b11010; // 26
                5'd10: gfExp = 5'b10001; // 17
                5'd11: gfExp = 5'b00111; // 7
                5'd12: gfExp = 5'b01110; // 14
                5'd13: gfExp = 5'b11100; // 28
                5'd14: gfExp = 5'b11101; // 29
                5'd15: gfExp = 5'b11111; // 31
                5'd16: gfExp = 5'b11011; // 27
                5'd17: gfExp = 5'b10011; // 19
                5'd18: gfExp = 5'b01011; // 11
                5'd19: gfExp = 5'b10110; // 22
                5'd20: gfExp = 5'b01001; // 9
                5'd21: gfExp = 5'b10010; // 18
                5'd22: gfExp = 5'b00011; // 3
                5'd23: gfExp = 5'b00110; // 6
                5'd24: gfExp = 5'b01100; // 12
                5'd25: gfExp = 5'b11000; // 24
                5'd26: gfExp = 5'b10101; // 21
                5'd27: gfExp = 5'b01111; // 15
                5'd28: gfExp = 5'b11110; // 30
                5'd29: gfExp = 5'b11001; // 25
                5'd30: gfExp = 5'b10111; // 23
                default: gfExp = 5'b00000;
            endcase
        end
    endfunction


    function automatic [4:0] gfLog;  // returns the exponent as 5-bit number
        input [4:0] a;  // field element (nonzero)
        begin
            // Note: if a is zero, you should handle that case separately.
            case (a)
                5'b00001: gfLog = 5'd0;
                5'b00010: gfLog = 5'd1;
                5'b00100: gfLog = 5'd2;
                5'b01000: gfLog = 5'd3;
                5'b10000: gfLog = 5'd4;
                5'b00101: gfLog = 5'd5;
                5'b01010: gfLog = 5'd6;
                5'b10100: gfLog = 5'd7;
                5'b01101: gfLog = 5'd8;
                5'b11010: gfLog = 5'd9;
                5'b10001: gfLog = 5'd10;
                5'b00111: gfLog = 5'd11;
                5'b01110: gfLog = 5'd12;
                5'b11100: gfLog = 5'd13;
                5'b11101: gfLog = 5'd14;
                5'b11111: gfLog = 5'd15;
                5'b11011: gfLog = 5'd16;
                5'b10011: gfLog = 5'd17;
                5'b01011: gfLog = 5'd18;
                5'b10110: gfLog = 5'd19;
                5'b01001: gfLog = 5'd20;
                5'b10010: gfLog = 5'd21;
                5'b00011: gfLog = 5'd22;
                5'b00110: gfLog = 5'd23;
                5'b01100: gfLog = 5'd24;
                5'b11000: gfLog = 5'd25;
                5'b10101: gfLog = 5'd26;
                5'b01111: gfLog = 5'd27;
                5'b11110: gfLog = 5'd28;
                5'b11001: gfLog = 5'd29;
                5'b10111: gfLog = 5'd30;
                default: gfLog = 5'd31; // a flag value; normally a is nonzero.
            endcase
        end
    endfunction

    // Compute multiplicative inverse in GF(2^5) (primitive poly x^5 + x^2 + 1)
    function automatic[4: 0] gfInv;
        input logic[4: 0] a; // field element
        logic[4: 0] loga;
        logic[4: 0] exp;
        begin
        if (a == 5 'b00000) begin
            // convention: inverse of 0 is defined as 0 (or you could flag an error)
            gfInv = 5 'b00000;
            end
            else begin
                // 1) find exponent x = log(a)
                loga = gfLog(a);
                // 2) compute exponent for the inverse: (31 - x) mod 31
                exp = (5 'd31 - loga) % 5'd31;
                // 3) look up α^exp
                gfInv = gfExp(exp); 
                end 
            end 
    endfunction

    // Multiply the stuff, under GF(2^5)
    function automatic [4:0] gfMul;
        input [4:0] a;
        input [4:0] b;
        reg [4:0] x;
        reg [4:0] y;
        if (a == 0 || b == 0)
            gfMul = 0;
        else begin
            x = gfLog(a);
            y = gfLog(b);
            // add exponents, then wrap mod 31
            gfMul = gfExp( (x + y) % 31 );
        end
    endfunction


    // FSM sequential block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 0;
            n <= 0;
            m_counter <= 1;
            L <= 0;
            // Initialize sigma(x)=1, other coefficients 0.
            sigma0 <= 5'b00001;
            sigma1 <= 0;
            sigma2 <= 0;
            sigma3 <= 0;
            // B(x) = 1
            B0 <= 5'b00001;
            B1 <= 0;
            B2 <= 0;
            B3 <= 0;
            done <= 0;
        end else begin
            state <= next_state;
            // State-dependent updates are done in the combinational block below.
        end
    end

     // FSM combinational block for BM algorithm
    always @(*) begin
        // Default next state is current state.
        next_state = state;
        
        case (state)
            0: begin
                // Begin iterations
                next_state = 1;
            end
            
            1: begin
                // Compute discrepancy d = S[n] ^ sum_{i=1}^{L} sigma[i] * S[n-i]
                // For the first iteration (n == 0), L=0, so d = S1.
                case (n)
                    4'd0: d = syndrome0;
                    4'd1: d = syndrome1;
                    4'd2: d = syndrome2;
                    4'd3: d = syndrome3;
                    4'd4: d = syndrome4;
                    4'd5: d = syndrome5;
                endcase
                //d = syndrome[n];  // start with S[n]
                // Accumulate contributions for i=1 to L.
                // (A loop is used here for clarity; unroll or implement in hardware as needed.)
                
                for (i = 1; i <= L; i = i + 1) begin
                    // GF multiplication: sigma[i] * syndrome[n-i]
                    // XOR the result with d.
                    //d = d ^ gfMul(sigma[i], syndrome[n - i]);
                    case (i)
                        4'd1: case (n-i)
                                4'd0: d = d ^ gfMul(sigma1, syndrome0);
                                4'd1: d = d ^ gfMul(sigma1, syndrome1);
                                4'd2: d = d ^ gfMul(sigma1, syndrome2);
                                4'd3: d = d ^ gfMul(sigma1, syndrome3);
                                4'd4: d = d ^ gfMul(sigma1, syndrome4);
                                4'd5: d = d ^ gfMul(sigma1, syndrome5);
                            endcase
                        4'd2: case (n-i)
                                4'd0: d = d ^ gfMul(sigma2, syndrome0);
                                4'd1: d = d ^ gfMul(sigma2, syndrome1);
                                4'd2: d = d ^ gfMul(sigma2, syndrome2);
                                4'd3: d = d ^ gfMul(sigma2, syndrome3);
                                4'd4: d = d ^ gfMul(sigma2, syndrome4);
                                4'd5: d = d ^ gfMul(sigma2, syndrome5);
                            endcase
                        4'd3: case (n-i)
                                4'd0: d = d ^ gfMul(sigma3, syndrome0);
                                4'd1: d = d ^ gfMul(sigma3, syndrome1);
                                4'd2: d = d ^ gfMul(sigma3, syndrome2);
                                4'd3: d = d ^ gfMul(sigma3, syndrome3);
                                4'd4: d = d ^ gfMul(sigma3, syndrome4);
                                4'd5: d = d ^ gfMul(sigma3, syndrome5);
                            endcase
                    endcase
                end
                
                // Next state depends on discrepancy:
                next_state = 2;
            end
            
            2: begin
                if (d == 0) begin
                    // If discrepancy is zero, no update required.
                    // Just increment m_counter.
                    m_counter = m_counter + 1;
                end else begin
                    // Save current sigma polynomial in sigma_old.
                    sigma_old0 = sigma0;
                    sigma_old1 = sigma1;
                    sigma_old2 = sigma2;
                    sigma_old3 = sigma3;
                    
                    // For j = 0 to degree max, update: sigma(x) = sigma(x) XOR (d * x^(m_counter) * B(x))
                    // The multiplication d * B(x) is performed coefficient–wise using gfMul.
                    // Shifting by m_counter is equivalent to delaying the indices.
                    //integer j;
                    for (j = 3; j >= 0; j = j - 1) begin
                        // If j >= m_counter, then combine B[j-m_counter] multiplied by d.
                        if (j >= m_counter)
                            case (j)
                                3: case (j - m_counter)
                                    0: sigma3 = sigma3 ^ gfMul(d, B0);
                                    1: sigma3 = sigma3 ^ gfMul(d, B1);
                                    2: sigma3 = sigma3 ^ gfMul(d, B2);
                                    3: sigma3 = sigma3 ^ gfMul(d, B3);
                                   endcase
                                2:case (j - m_counter)
                                    0: sigma2 = sigma2 ^ gfMul(d, B0);
                                    1: sigma2 = sigma2 ^ gfMul(d, B1);
                                    2: sigma2 = sigma2 ^ gfMul(d, B2);
                                    3: sigma2 = sigma2 ^ gfMul(d, B3);
                                   endcase
                                1:case (j - m_counter)
                                    0: sigma1 = sigma1 ^ gfMul(d, B0);
                                    1: sigma1 = sigma1 ^ gfMul(d, B1);
                                    2: sigma1 = sigma1 ^ gfMul(d, B2);
                                    3: sigma1 = sigma1 ^ gfMul(d, B3);
                                   endcase
                                0:case (j - m_counter)
                                    0: sigma0 = sigma0 ^ gfMul(d, B0);
                                    1: sigma0 = sigma0 ^ gfMul(d, B1);
                                    2: sigma0 = sigma0 ^ gfMul(d, B2);
                                    3: sigma0 = sigma0 ^ gfMul(d, B3);
                                   endcase
                            endcase
                            //sigma[j] = sigma[j] ^ gfMul(d, B[j - m_counter]);
                        // Otherwise, sigma remains unchanged.
                    end
                    
                    // Check if (2 * L <= n):
                    if ((2 * L) <= n) begin
                        // Update L: L = n + 1 - L.
                        L = n + 1 - L;
                        // Set B(x) to old sigma polynomial.
                        B0 = gfMul(sigma_old0, gfInv(d));
                        B1 = gfMul(sigma_old1, gfInv(d));
                        B2 = gfMul(sigma_old2, gfInv(d));
                        B3 = gfMul(sigma_old3, gfInv(d));
                        m_counter = 1;
                    end else begin
                        m_counter = m_counter + 1;
                    end
                end
                // Inside your UPDATE state, right after you compute d:
                next_state = 3;
            end
            
            3: begin
                if (n < 6 - 1) begin  // 6 syndromes in total
                    n = n + 1;
                    next_state = 1;
                end else begin
                    next_state = 4;
                end
            end
            
            4: begin
                done = 1;
                next_state = 4;
            end
            
            default: begin
                next_state = 0;
            end
        endcase
    end

    
endmodule