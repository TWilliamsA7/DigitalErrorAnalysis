`timescale 1ns/1ps
module BerlMassV2 #(
  parameter N = 31,       // codeword length
  parameter m = 5,        // GF(2^m)
  parameter T = 3         // error‐correcting capability
) (
  input           clk,
  input           reset,
  input   [m-1:0] syndrome0,
  input   [m-1:0] syndrome1,
  input   [m-1:0] syndrome2,
  input   [m-1:0] syndrome3,
  input   [m-1:0] syndrome4,
  input   [m-1:0] syndrome5,
  output logic         done,
  output logic [m-1:0] sigma0,
  output logic [m-1:0] sigma1,
  output logic [m-1:0] sigma2,
  output logic [m-1:0] sigma3,
  output logic [3:0]   L
);

  //--------------------------------------------------------------------------
  // 1) FSM State Declaration
  //--------------------------------------------------------------------------
  localparam    IDLE              = 3'd0,
               UPDATE_CAPTURE   = 3'd1,
               UPDATE_NORMALIZE = 3'd2,
               INCREMENT              = 3'd3,
               DONE              = 3'd4;

  reg [3:0] state, next_state;

  //--------------------------------------------------------------------------
  // 2) Internal Registers + Next‑State Versions
  //--------------------------------------------------------------------------

  // Locator & helper polynomials
  logic [m-1:0] sigma_old0, sigma_old1, sigma_old2, sigma_old3;
  logic [m-1:0] B0, B1, B2, B3;

  logic [m-1:0] next_sigma0, next_sigma1, next_sigma2, next_sigma3;
  logic [m-1:0] next_sigma_old0, next_sigma_old1, next_sigma_old2, next_sigma_old3;
  logic [m-1:0] next_B0, next_B1, next_B2, next_B3;

  // Degree, gap counter, syndrome‐index
  logic [3:0] L_reg, m_counter, n_reg;
  logic [3:0] next_L, next_m_counter, next_n;

  // Done flag
  logic      done_reg, next_done;

    logic [m-1:0] si;

  /*
  assign sigma0 = next_sigma0;
  assign sigma1 = next_sigma1;
  assign sigma2 = next_sigma2;
  assign sigma3 = next_sigma3;
  assign L      = next_L;
  assign done   = next_done;
  */
  //--------------------------------------------------------------------------
  // 3) Combinational Discrepancy Calculation
  //--------------------------------------------------------------------------
  logic [m-1:0] d_comb;
  integer       i;
  always @(*) begin
    // Start with the “current” syndrome S[n]
    case (n_reg)
      0: d_comb = syndrome0;
      1: d_comb = syndrome1;
      2: d_comb = syndrome2;
      3: d_comb = syndrome3;
      4: d_comb = syndrome4;
      5: d_comb = syndrome5;
      default: d_comb = 0;
    endcase

    // Accumulate sigma[i] * S[n-i]
    for (i = 1; i <= L_reg; i = i + 1) begin
      case (i)
        1: si = sigma1;
        2: si = sigma2;
        3: si = sigma3;
        default: si = 0;
      endcase
      case (n_reg - i)
        0: d_comb ^= gfMul(si, syndrome0);
        1: d_comb ^= gfMul(si, syndrome1);
        2: d_comb ^= gfMul(si, syndrome2);
        3: d_comb ^= gfMul(si, syndrome3);
        4: d_comb ^= gfMul(si, syndrome4);
        5: d_comb ^= gfMul(si, syndrome5);
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // 4) Next‐State / Next‐Value Logic
  //--------------------------------------------------------------------------
  always @(*) begin
    // Defaults (hold current values)
    next_state            = state;
    next_sigma0           = sigma0;
    next_sigma1           = sigma1;
    next_sigma2           = sigma2;
    next_sigma3           = sigma3;
    next_sigma_old0       = sigma_old0;
    next_sigma_old1       = sigma_old1;
    next_sigma_old2       = sigma_old2;
    next_sigma_old3       = sigma_old3;
    next_B0               = B0;
    next_B1               = B1;
    next_B2               = B2;
    next_B3               = B3;
    next_L                = L_reg;
    next_m_counter        = m_counter;
    next_n                = n_reg;
    next_done             = done_reg;

    case (state)

      // -----------------------
      IDLE: begin
        next_state = UPDATE_CAPTURE;
      end

      // -----------------------
      // Phase A: capture old sigma[] & update sigma[] if error
      UPDATE_CAPTURE: begin
        if (d_comb == 0) begin
          // no discrepancy → gap grows
          next_m_counter = m_counter + 1;
          next_state     = INCREMENT;
        end else begin
          // 1) Capture the pre‑update locator
          next_sigma_old0 = sigma0;
          next_sigma_old1 = sigma1;
          next_sigma_old2 = sigma2;
          next_sigma_old3 = sigma3;
          // 2) Update the locator polynomial:
          if (0 >= m_counter) next_sigma0 = sigma0 ^ gfMul(d_comb, B0);
          if (1 >= m_counter) next_sigma1 = sigma1 ^ gfMul(d_comb, B1);
          if (2 >= m_counter) next_sigma2 = sigma2 ^ gfMul(d_comb, B2);
          if (3 >= m_counter) next_sigma3 = sigma3 ^ gfMul(d_comb, B3);
          // move on to normalization
          next_state = UPDATE_NORMALIZE;
        end
      end

      // -----------------------
      // Phase B: normalize B[] and update L if needed
      UPDATE_NORMALIZE: begin
        if (2*L_reg <= n_reg) begin
          // time to bump the degree
          next_L         = (n_reg + 1) - L_reg;
          next_m_counter = 1;
          // regenerate the helper polynomial
          next_B0        = gfMul(sigma_old0, gfInv(d_comb));
          next_B1        = gfMul(sigma_old1, gfInv(d_comb));
          next_B2        = gfMul(sigma_old2, gfInv(d_comb));
          next_B3        = gfMul(sigma_old3, gfInv(d_comb));
        end else begin
          // gap grows instead
          next_m_counter = m_counter + 1;
        end
        next_state = INCREMENT;
      end

      // -----------------------
      // Advance to next syndrome index, or finish
      INCREMENT: begin
        if (n_reg < 2*T - 1) begin
          next_n     = n_reg + 1;
          next_state = UPDATE_CAPTURE;
        end else begin
          next_state = DONE;
        end
      end

      // -----------------------
      DONE: begin
        next_done  = 1;
        next_state = DONE;
      end

    endcase
  end

  //--------------------------------------------------------------------------
  // 5) Sequential State & Register Update
  //--------------------------------------------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state        <= IDLE;
      sigma0       <= 0; sigma0[0] <= 1;
      sigma1       <= 0;
      sigma2       <= 0;
      sigma3       <= 0;
      sigma_old0   <= 0; sigma_old0[0] <= 1;
      sigma_old1   <= 0;
      sigma_old2   <= 0;
      sigma_old3   <= 0;
      B0           <= 0; B0[0] <= 1;
      B1           <= 0;
      B2           <= 0;
      B3           <= 0;
      L_reg        <= 0;
      m_counter    <= 1;
      n_reg        <= 0;
      done_reg     <= 0;
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
      L_reg        <= next_L;
      m_counter    <= next_m_counter;
      n_reg        <= next_n;
      done_reg     <= next_done;
    end
  end

  //--------------------------------------------------------------------------
  // 6) Finite‐Field Helpers (GF(2^5), p(x)=x^5+x^2+1)
  //--------------------------------------------------------------------------
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
    if (a == 0)     gfInv = 0;
    else begin
      lg    = gfLog(a);
      gfInv = gfExp((31 - lg) % 31);
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
