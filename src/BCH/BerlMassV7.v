`timescale 1ns/1ps
module BerlMassV2 #(
  parameter N = 31,      // Codeword length
  parameter m = 5,       // GF(2^m)
  parameter T = 3        // Error‑correcting capability
) (
  input           clk,
  input           reset,
  input   [m-1:0] S0,
  input   [m-1:0] S1,
  input   [m-1:0] S2,
  input   [m-1:0] S3,
  input   [m-1:0] S4,
  input   [m-1:0] S5,
  output          done,
  output  [m-1:0] sigma0,
  output  [m-1:0] sigma1,
  output  [m-1:0] sigma2,
  output  [m-1:0] sigma3,
  output  [3:0]   L
);

  // State machine: CALC_UPDATE → INCR → DONE
  localparam    CALC_UPDATE             = 2'd0,
               INCR   = 2'd1,
               DONE = 2'd2;

  reg [1:0] state, next_state;

  // Registers & next‑state
  logic [m-1:0] sigma0_r, sigma1_r, sigma2_r, sigma3_r;
  logic [m-1:0] B0_r,      B1_r,      B2_r,      B3_r;
  logic [3:0]   L_r,       m_cnt_r,   n_r;
  logic done_reg;

  logic [m-1:0] next_sigma0, next_sigma1, next_sigma2, next_sigma3;
  logic [m-1:0] next_B0,      next_B1,      next_B2,      next_B3;
  logic [3:0]   next_L,       next_m_cnt,   next_n;
  logic         next_done;

  // Expose outputs
  assign sigma0 = sigma0_r;
  assign sigma1 = sigma1_r;
  assign sigma2 = sigma2_r;
  assign sigma3 = sigma3_r;
  assign L      = L_r;
  assign done   = next_done;

    logic [m-1:0] si;
    logic [m-1:0] sni;

  // --------------------------------------------------------------------------
  // 1) Compute discrepancy combinationally
  // --------------------------------------------------------------------------
  logic [m-1:0] d_comb;
  integer       i;
  always @(*) begin
    // pick S[n]
    case (n_r)
      0: d_comb = S0;
      1: d_comb = S1;
      2: d_comb = S2;
      3: d_comb = S3;
      4: d_comb = S4;
      5: d_comb = S5;
      default: d_comb = 0;
    endcase
    // Σ σ[i]*S[n-i]
    for (i = 1; i <= L_r; i = i+1) begin
      si = (i==1) ? sigma1_r :
                         (i==2) ? sigma2_r :
                         (i==3) ? sigma3_r : 0;
      sni = (n_r-i==0) ? S0 :
                          (n_r-i==1) ? S1 :
                          (n_r-i==2) ? S2 :
                          (n_r-i==3) ? S3 :
                          (n_r-i==4) ? S4 :
                          (n_r-i==5) ? S5 : 0;
      d_comb ^= gfMul(si, sni);
    end
  end

  // --------------------------------------------------------------------------
  // 2) Next‑state & data‑path logic
  // --------------------------------------------------------------------------
  always @(*) begin
    // Defaults: hold everything
    next_state     = state;
    next_sigma0    = sigma0_r; next_sigma1 = sigma1_r;
    next_sigma2    = sigma2_r; next_sigma3 = sigma3_r;
    next_B0        = B0_r;     next_B1     = B1_r;
    next_B2        = B2_r;     next_B3     = B3_r;
    next_L         = L_r;
    next_m_cnt     = m_cnt_r;
    next_n         = n_r;
    next_done      = done;

    case (state)

      // ---- Compute & update in one step ----
      CALC_UPDATE: begin
        if (d_comb != 0) begin
          // 1) update locator σ(x) = σ(x) ⊕ d·x^m_cnt·B(x)
          if (0 >= m_cnt_r) next_sigma0 = sigma0_r ^ gfMul(d_comb, B0_r);
          if (1 >= m_cnt_r) next_sigma1 = sigma1_r ^ gfMul(d_comb, B1_r);
          if (2 >= m_cnt_r) next_sigma2 = sigma2_r ^ gfMul(d_comb, B2_r);
          if (3 >= m_cnt_r) next_sigma3 = sigma3_r ^ gfMul(d_comb, B3_r);
          // 2) maybe bump degree & regenerate B(x)
          if (2*L_r <= n_r) begin
            next_L     = (n_r + 1) - L_r;
            next_m_cnt = 1;
            next_B0    = gfMul(sigma0_r, gfInv(d_comb));
            next_B1    = gfMul(sigma1_r, gfInv(d_comb));
            next_B2    = gfMul(sigma2_r, gfInv(d_comb));
            next_B3    = gfMul(sigma3_r, gfInv(d_comb));
          end else begin
            next_m_cnt = m_cnt_r + 1;
          end
        end else begin
          // no error: just advance the gap
          next_m_cnt = m_cnt_r + 1;
        end
        next_state = INCR;
      end

      // ---- Advance syndrome index / finish ----
      INCR: begin
        if (n_r < 2*T - 1) begin
          next_n     = n_r + 1;
          next_state = CALC_UPDATE;
        end else begin
          next_state = DONE;
          next_done  = 1;
        end
      end

      DONE: begin
        next_state = DONE;
        next_done  = 1;
      end
    endcase
  end

  // --------------------------------------------------------------------------
  // 3) Sequential update
  // --------------------------------------------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state     <= CALC_UPDATE;
      sigma0_r  <= 5'b00001; sigma1_r <= 0; sigma2_r <= 0; sigma3_r <= 0;
      B0_r      <= 5'b00001; B1_r     <= 0; B2_r     <= 0; B3_r     <= 0;
      L_r       <= 0;
      m_cnt_r   <= 1;
      n_r       <= 0;
      done_reg  <= 0;
    end else begin
      state     <= next_state;
      sigma0_r  <= next_sigma0;
      sigma1_r  <= next_sigma1;
      sigma2_r  <= next_sigma2;
      sigma3_r  <= next_sigma3;
      B0_r      <= next_B0;
      B1_r      <= next_B1;
      B2_r      <= next_B2;
      B3_r      <= next_B3;
      L_r       <= next_L;
      m_cnt_r   <= next_m_cnt;
      n_r       <= next_n;
      done_reg  <= next_done;
    end
  end

  //--------------------------------------------------------------------------
  // 4) GF(2^5) helpers (same as before)
  //--------------------------------------------------------------------------
  function automatic logic [m-1:0] gfExp(input logic [4:0] e);
    case(e)
      5'd0:  gfExp=5'b00001; 5'd1:  gfExp=5'b00010; 5'd2:  gfExp=5'b00100;
      5'd3:  gfExp=5'b01000; 5'd4:  gfExp=5'b10000; 5'd5:  gfExp=5'b00101;
      5'd6:  gfExp=5'b01010; 5'd7:  gfExp=5'b10100; 5'd8:  gfExp=5'b01101;
      5'd9:  gfExp=5'b11010; 5'd10: gfExp=5'b10001;5'd11: gfExp=5'b00111;
      5'd12: gfExp=5'b01110;5'd13: gfExp=5'b11100;5'd14: gfExp=5'b11101;
      5'd15: gfExp=5'b11111;5'd16: gfExp=5'b11011;5'd17: gfExp=5'b10011;
      5'd18: gfExp=5'b01011;5'd19: gfExp=5'b10110;5'd20: gfExp=5'b01001;
      5'd21: gfExp=5'b10010;5'd22: gfExp=5'b00011;5'd23: gfExp=5'b00110;
      5'd24: gfExp=5'b01100;5'd25: gfExp=5'b11000;5'd26: gfExp=5'b10101;
      5'd27: gfExp=5'b01111;5'd28: gfExp=5'b11110;5'd29: gfExp=5'b11001;
      5'd30: gfExp=5'b10111; default: gfExp=5'b00000;
    endcase
  endfunction

  function automatic logic [4:0] gfLog(input logic [m-1:0] a);
    case(a)
      5'b00001: gfLog=5'd0;  5'b00010: gfLog=5'd1;  5'b00100: gfLog=5'd2;
      5'b01000: gfLog=5'd3;  5'b10000: gfLog=5'd4;  5'b00101: gfLog=5'd5;
      5'b01010: gfLog=5'd6;  5'b10100: gfLog=5'd7;  5'b01101: gfLog=5'd8;
      5'b11010: gfLog=5'd9;  5'b10001: gfLog=5'd10; 5'b00111: gfLog=5'd11;
      5'b01110: gfLog=5'd12; 5'b11100: gfLog=5'd13; 5'b11101: gfLog=5'd14;
      5'b11111: gfLog=5'd15; 5'b11011: gfLog=5'd16; 5'b10011: gfLog=5'd17;
      5'b01011: gfLog=5'd18; 5'b10110: gfLog=5'd19; 5'b01001: gfLog=5'd20;
      5'b10010: gfLog=5'd21; 5'b00011: gfLog=5'd22; 5'b00110: gfLog=5'd23;
      5'b01100: gfLog=5'd24; 5'b11000: gfLog=5'd25; 5'b10101: gfLog=5'd26;
      5'b01111: gfLog=5'd27; 5'b11110: gfLog=5'd28; 5'b11001: gfLog=5'd29;
      5'b10111: gfLog=5'd30; default:    gfLog=5'd0;
    endcase
  endfunction

  function automatic logic [m-1:0] gfInv(input logic [m-1:0] a);
    logic [4:0] lg;
    if (a==0)     gfInv=0;
    else begin
      lg    = gfLog(a);
      gfInv = gfExp((31-lg)%31);
    end
  endfunction

  function automatic logic [m-1:0] gfMul(input logic [m-1:0] x, input logic [m-1:0] y);
    logic [4:0] lx, ly;
    if (x==0||y==0) gfMul=0;
    else begin
      lx    = gfLog(x);
      ly    = gfLog(y);
      gfMul = gfExp((lx+ly)%31);
    end
  endfunction

endmodule
