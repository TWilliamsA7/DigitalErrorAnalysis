`timescale 1ns/1ps
module lfsr_tb();
    localparam N = 4;
    reg clk, reset;
    wire [1:N] q1;
    wire [1:N] q2;
    wire [1:N] q3;

    // Instantiate unit under test
    lfsr #(.N(N), .TAPS(4'b0011), .I('d11)) uut (.clk(clk), .reset(reset), .q(q1));
    lfsr #(.N(N), .TAPS(4'b0011), .I('d1)) uut1 (.clk(clk), .reset(reset), .q(q2));
    
    assign q3 = q1 & q2;



    // Dumpfile and dumpvars for waveform generation
    initial begin
        $dumpfile("output/lfsrTest.vcd"); // Specify dump file name
        $dumpvars(0, lfsr_tb); // Dump all signals in the testbench
    end

    initial begin
        // Initialize the clock to 0
        clk = 0; 
        // Keep the register in resting state
        reset = 1;
    end

    // Toggle the clock every 10ns
    always #10 clk = ~clk;

    initial begin
        // End the rest cycle
        #20 reset = 0;
        // End the simulation after 500ns
        #1000 $finish;
    end

endmodule