`timescale 1ns/1ps

// Testbench for syndromeCalc and BMDecoder with individual syndrome wires
module tb_bch;

  // Parameters
  localparam N = 31;
  localparam m = 5;
  localparam T = 3;

  // Input to syndromeCalc
  reg [N-1:0] r;

  // Individual syndrome signals
  wire [m-1:0] syndrome1, syndrome2, syndrome3, syndrome4, syndrome5, syndrome6;

  // Instantiate syndromeCalc
  syndromeCalc #(.N(N), .T(T), .m(m)) uut_syndrome (
    .r(r),
    .syndrome1(syndrome1),
    .syndrome2(syndrome2),
    .syndrome3(syndrome3),
    .syndrome4(syndrome4),
    .syndrome5(syndrome5),
    .syndrome6(syndrome6)
  );

  // Clock and reset for BMDecoder
  reg clk, reset;
  wire done;


  // Outputs from BMDecoder
  wire [m-1:0] sigma0, sigma1, sigma2, sigma3;
  wire [3:0] L_out;

  // Instantiate BMDecoder
  /*
  BerlMassV2 #(.N(N), .m(m), .T(T)) uut_bm (
    .clk(clk),
    .reset(reset),
    .syndrome0(syndrome1),
    .syndrome1(syndrome2),
    .syndrome2(syndrome3),
    .syndrome3(syndrome4),
    .syndrome4(syndrome5),
    .syndrome5(syndrome6),
    .done(done),
    .sigma0(sigma0),
    .sigma1(sigma1),
    .sigma2(sigma2),
    .sigma3(sigma3),
    .L(L_out)
  );*/

  BerlMassV2 #(.N(N), .m(m), .T(T)) uut_bm (
    .clk(clk),
    .reset(reset),
    .S0(syndrome1),
    .S1(syndrome2),
    .S2(syndrome3),
    .S3(syndrome4),
    .S4(syndrome5),
    .S5(syndrome6),
    .done(done),
    .sigma0(sigma0),
    .sigma1(sigma1),
    .sigma2(sigma2),
    .sigma3(sigma3),
    .L(L_out)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period
  end

  // Test stimulus
  initial begin
    // Initialize
    reset = 1;
    r = 0;
    #20;
    reset = 0;

    // Test 1: no errors -> syndromes should be zero
    r = {N{1'b0}};
    #100;
    $display("Test 1: No error");
    $display("Syndromes: %0d %0d %0d %0d %0d %0d", syndrome1, syndrome2, syndrome3, syndrome4, syndrome5, syndrome6);

    // Test 2: single-bit error at position 5
    reset = 2;
    r = 0;
    r[5] = 1;
    #20
    reset = 0;
    #100;
    $display("Test 2: Single error at pos 5");
    $display("Syndromes: %0d %0d %0d %0d %0d %0d", syndrome1, syndrome2, syndrome3, syndrome4, syndrome5, syndrome6);

    // Wait for BMDecoder to finish
    wait(done);
    $display("BMDecoder done. L = %d", L_out);
    $display("Sigma coefficients: %b %b %b %b", sigma0, sigma1, sigma2, sigma3);

    $finish;
  end

endmodule
