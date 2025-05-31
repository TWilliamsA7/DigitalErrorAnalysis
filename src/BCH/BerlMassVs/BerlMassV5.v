`timescale 1ns/1ps
module BerlMassV2 #(
    parameter N = 31,
    parameter m = 5,
    parameter T = 3
) (
    input               clk,
    input            reset,
    input   [m-1:0]     syndrome0,
    input   [m-1:0]     syndrome1,
    input   [m-1:0]     syndrome2,
    input   [m-1:0]     syndrome3,
    input   [m-1:0]     syndrome4,
    input   [m-1:0]     syndrome5,
    output reg             done,
    output reg [m-1:0]     sigma0,
    output reg [m-1:0]     sigma1,
    output reg [m-1:0]     sigma2,
    output reg [m-1:0]     sigma3,
    output reg [3:0]       L
);

    // FSM states
    localparam IDLE              = 3'd0,
               UPDATE_CAPTURE   = 3'd1,
               UPDATE_NORMALIZE = 3'd2,
               NEXT              = 3'd3,
               DONE              = 3'd4;

    // State registers
    logic [2:0] state, next_state;

    logic [m-1:0] si;

    // Internal registers and their next-state versions
    logic [m-1:0] B0, B1, B2, B3;
    logic [m-1:0] sigma_old0, sigma_old1, sigma_old2, sigma_old3;
    logic [3:0]   n, m_counter;

    logic [m-1:0] next_B0,    next_B1,    next_B2,    next_B3;
    logic [m-1:0] next_sigma0, next_sigma1, next_sigma2, next_sigma3;
    logic [m-1:0] next_sigma_old0, next_sigma_old1, next_sigma_old2, next_sigma_old3;
    logic [3:0]   next_L,     next_m_counter, next_n;
    logic         next_done;

    // Purely combinational discrepancy
    logic [m-1:0] d_comb;
    integer i;
    always @(*) begin
        // Start with S[n]
        case (n)
            0: d_comb = syndrome0;
            1: d_comb = syndrome1;
            2: d_comb = syndrome2;
            3: d_comb = syndrome3;
            4: d_comb = syndrome4;
            5: d_comb = syndrome5;
            default: d_comb = 0;
        endcase
        // Accumulate sigma[i]*S[n-i]
        for (i = 1; i <= L; i = i + 1) begin
            case (i)
                1: si = sigma1;
                2: si = sigma2;
                3: si = sigma3;
                default: si = 0;
            endcase
            case (n - i)
                0: d_comb ^= gfMul(si, syndrome0);
                1: d_comb ^= gfMul(si, syndrome1);
                2: d_comb ^= gfMul(si, syndrome2);
                3: d_comb ^= gfMul(si, syndrome3);
                4: d_comb ^= gfMul(si, syndrome4);
                5: d_comb ^= gfMul(si, syndrome5);
            endcase
        end
    end

    // Next-state logic
    always @(*) begin
        // Defaults
        next_state       = state;
        next_sigma0      = sigma0;
        next_sigma1      = sigma1;
        next_sigma2      = sigma2;
        next_sigma3      = sigma3;
        next_sigma_old0  = sigma_old0;
        next_sigma_old1  = sigma_old1;
        next_sigma_old2  = sigma_old2;
        next_sigma_old3  = sigma_old3;
        next_B0          = B0;
        next_B1          = B1;
        next_B2          = B2;
        next_B3          = B3;
        next_L           = L;
        next_m_counter   = m_counter;
        next_n           = n;
        next_done        = done;

        case (state)
            IDLE: begin
                next_state = UPDATE_CAPTURE;
            end

            // Phase A: capture and update sigma
            UPDATE_CAPTURE: begin
                if (d_comb == 0) begin
                    // no error
                    next_m_counter = m_counter + 1;
                    next_state     = NEXT;
                end else begin
                    // capture old sigma
                    next_sigma_old0 = sigma0;
                    next_sigma_old1 = sigma1;
                    next_sigma_old2 = sigma2;
                    next_sigma_old3 = sigma3;
                    // update sigma(x)
                    if (0 >= m_counter) next_sigma0 = sigma0 ^ gfMul(d_comb, B0);
                    if (1 >= m_counter) next_sigma1 = sigma1 ^ gfMul(d_comb, B1);
                    if (2 >= m_counter) next_sigma2 = sigma2 ^ gfMul(d_comb, B2);
                    if (3 >= m_counter) next_sigma3 = sigma3 ^ gfMul(d_comb, B3);
                    next_state = UPDATE_NORMALIZE;
                end
            end

            // Phase B: normalize B and update L
            UPDATE_NORMALIZE: begin
                if (2*L <= n) begin
                    next_L         = (n + 1) - L;
                    next_m_counter = 1;
                    next_B0        = gfMul(sigma_old0, gfInv(d_comb));
                    next_B1        = gfMul(sigma_old1, gfInv(d_comb));
                    next_B2        = gfMul(sigma_old2, gfInv(d_comb));
                    next_B3        = gfMul(sigma_old3, gfInv(d_comb));
                end else begin
                    next_m_counter = m_counter + 1;
                end
                next_state = NEXT;
            end

            NEXT: begin
                if (n < 2*T - 1) begin
                    next_n     = n + 1;
                    next_state = UPDATE_CAPTURE;
                end else begin
                    next_state = DONE;
                end
            end

            DONE: begin
                next_done  = 1;
                next_state = DONE;
            end
        endcase
    end

    // Sequential update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            sigma0       <= 1;
            sigma1       <= 0;
            sigma2       <= 0;
            sigma3       <= 0;
            sigma_old0   <= sigma0;
            sigma_old1   <= sigma1;
            sigma_old2   <= sigma2;
            sigma_old3   <= sigma3;
            B0           <= 1;
            B1           <= 0;
            B2           <= 0;
            B3           <= 0;
            L            <= 0;
            m_counter    <= 1;
            n            <= 0;
            done         <= 0;
        end else begin
            state        <= next_state;
            sigma0       <= next_sigma0;
            sigma1       <= next_sigma1;
            sigma2       <= next_sigma2;
            sigma3       <= next_sigma3;
            sigma_old0   <= next_sigma_old0;
            sigma_old1   <= next_sigma_old1;
            sigma_old2   <= next_sigma_old2;
            sigma_old3   <= next_sigma_old3;
            B0           <= next_B0;
            B1           <= next_B1;
            B2           <= next_B2;
            B3           <= next_B3;
            L            <= next_L;
            m_counter    <= next_m_counter;
            n            <= next_n;
            done         <= next_done;
        end
    end

    //-----------------------------------------------------------------------------  
    // Finite-field helper functions (GF(2^5), p(x)=x^5+x^2+1)
    //-----------------------------------------------------------------------------
    function automatic logic [m-1:0] gfExp(input logic [4:0] e);
        case(e)
            5'd0:  gfExp=5'b00001; 5'd1:  gfExp=5'b00010; 5'd2:  gfExp=5'b00100;
            5'd3:  gfExp=5'b01000; 5'd4:  gfExp=5'b10000; 5'd5:  gfExp=5'b00101;
            5'd6:  gfExp=5'b01010; 5'd7:  gfExp=5'b10100; 5'd8:  gfExp=5'b01101;
            5'd9:  gfExp=5'b11010; 5'd10: gfExp=5'b10001; 5'd11: gfExp=5'b00111;
            5'd12: gfExp=5'b01110; 5'd13: gfExp=5'b11100; 5'd14: gfExp=5'b11101;
            5'd15: gfExp=5'b11111; 5'd16: gfExp=5'b11011; 5'd17: gfExp=5'b10011;
            5'd18: gfExp=5'b01011; 5'd19: gfExp=5'b10110; 5'd20: gfExp=5'b01001;
            5'd21: gfExp=5'b10010; 5'd22: gfExp=5'b00011; 5'd23: gfExp=5'b00110;
            5'd24: gfExp=5'b01100; 5'd25: gfExp=5'b11000; 5'd26: gfExp=5'b10101;
            5'd27: gfExp=5'b01111; 5'd28: gfExp=5'b11110; 5'd29: gfExp=5'b11001;
            5'd30: gfExp=5'b10111; default: gfExp=5'b00000;
        endcase
    endfunction

    function automatic logic [4:0] gfLog(input logic [m-1:0] a);
        case(a)
            5'b00001: gfLog=5; 5'b00010: gfLog=1; 5'b00100: gfLog=2;
            5'b01000: gfLog=3; 5'b10000: gfLog=4; 5'b00101: gfLog=5;
            5'b01010: gfLog=6; 5'b10100: gfLog=7; 5'b01101: gfLog=8;
            5'b11010: gfLog=9; 5'b10001: gfLog=10;5'b00111: gfLog=11;
            5'b01110: gfLog=12;5'b11100: gfLog=13;5'b11101: gfLog=14;
            5'b11111: gfLog=15;5'b11011: gfLog=16;5'b10011: gfLog=17;
            5'b01011: gfLog=18;5'b10110: gfLog=19;5'b01001: gfLog=20;
            5'b10010: gfLog=21;5'b00011: gfLog=22;5'b00110: gfLog=23;
            5'b01100: gfLog=24;5'b11000: gfLog=25;5'b10101: gfLog=26;
            5'b01111: gfLog=27;5'b11110: gfLog=28;5'b11001: gfLog=29;
            5'b10111: gfLog=30; default: gfLog=0;
        endcase
    endfunction

    function automatic logic [m-1:0] gfInv(input logic [m-1:0] a);
        logic [4:0] lg;
        if (a == 0) gfInv = 0;
        else begin
            lg     = gfLog(a);
            gfInv  = gfExp((31 - lg) % 31);
        end
    endfunction

    function automatic logic [m-1:0] gfMul(input logic [m-1:0] x, input logic [m-1:0] y);
        logic [4:0] lx, ly;
        if (x == 0 || y == 0) gfMul = 0;
        else begin
            lx    = gfLog(x);
            ly    = gfLog(y);
            gfMul = gfExp((lx + ly) % 31);
        end
    endfunction

endmodule
