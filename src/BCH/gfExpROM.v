module gfExpROM (
    input [3:0] addr,   // Address: exponent, 0 to 14
    output reg [3:0] data  // Data: corresponding field element in GF(2^4)
);
  always @(*) begin
    case(addr)
      4'd0: data = 4'd1;    // α^0 = 1
      4'd1: data = 4'd2;    // α^1 = 2 (0010)
      4'd2: data = 4'd4;    // α^2 = 4 (0100)
      4'd3: data = 4'd8;    // α^3 = 8 (1000)
      4'd4: data = 4'd3;    // α^4 = 3 (0011) i.e. x+1
      4'd5: data = 4'd6;    // α^5 = 6 (0110)
      4'd6: data = 4'd12;   // α^6 = 12 (1100)
      4'd7: data = 4'd11;   // α^7 = 11 (1011)
      4'd8: data = 4'd5;    // α^8 = 5 (0101)
      4'd9: data = 4'd10;   // α^9 = 10 (1010)
      4'd10: data = 4'd7;   // α^10 = 7 (0111)
      4'd11: data = 4'd14;  // α^11 = 14 (1110)
      4'd12: data = 4'd15;  // α^12 = 15 (1111)
      4'd13: data = 4'd13;  // α^13 = 13 (1101)
      4'd14: data = 4'd9;   // α^14 = 9 (1001)
      default: data = 4'd0;
    endcase
  end
endmodule
