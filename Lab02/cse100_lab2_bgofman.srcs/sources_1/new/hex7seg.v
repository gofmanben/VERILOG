`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/09/2025 06:53:35 PM
// Design Name: 
// Module Name: hex7seg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module hex7seg(
   input [3:0] n,       // Input: 4-bit binary number (0-15), usually the lower nibble of a byte
   // 'n' is the number to be displayed in hexadecimal format (0-F).
   output reg [6:0] seg // Output: segments {a, b, c, d, e, f, g}, where 0 = ON
  );
  
/*
  -a-
|     |
f     b
|     |
  -g-
|     |
e     c
|     |
  -d-    •dp
 */
 
 always @(*) begin
    /*
     <width>'<base><value>
     <width> - how many bits the number occupies
    ' - mandatory separator
    <base> - the number base (b - Binary, d - Decimal, h - Hexadecimal, o - Octal)
    <value> - the actual numeric value
    */
      case(n)
        4'd0: seg = 7'b1000000; // 0
        4'd1: seg = 7'b1111001; // 1
        4'd2: seg = 7'b0100100; // 2
        4'd3: seg = 7'b0110000; // 3
        4'd4: seg = 7'b0011001; // 4
        4'd5: seg = 7'b0010010; // 5
        4'd6: seg = 7'b0000010; // 6
        4'd7: seg = 7'b1111000; // 7
        4'd8: seg = 7'b0000000; // 8
        4'd9: seg = 7'b0010000; // 9
        4'd10: seg = 7'b0001000; // A
        4'd11: seg = 7'b0000011; // b
        4'd12: seg = 7'b1000110; // C
        4'd13: seg = 7'b0100001; // d
        4'd14: seg = 7'b0000110; // E
        4'd15: seg = 7'b0001110; // F
        default: seg = 7'b1111111;
      endcase
  end
  
  /* OR
  // seg[0] = 1. Segment A should be off for digits: 1, 4, b, d.
  assign seg[0] = 
      (~n[3]&~n[2]&~n[1]&n[0]) |   // 0001 → 1
      (~n[3]&n[2]&~n[1]&~n[0]) |   // 0100 → 4
      ( n[3]&~n[2]&n[1]&n[0])  |   // 1011 → b
      ( n[3]&n[2]&~n[1]&n[0]);     // 1101 → d
      
  // Segment B is off for 5, 6, b, C, E, F
  assign seg[1] = 
      (~n[3]&n[2]&~n[1]&n[0])   |  // 0101 → 5
      (~n[3]&n[2]&n[1]&~n[0])   |  // 0110 → 6
      ( n[3]&~n[2]&n[1]&n[0])   |  // 1011 → b
      ( n[3]&n[2]&~n[1]&~n[0])  |  // 1100 → C
      ( n[3]&n[2]&n[1]&~n[0])   |  // 1110 → E
      ( n[3]&n[2]&n[1]&n[0]);      // 1111 → F
   
   // Segment C is off for 2, C, E, F
   assign seg[2] = 
      (~n[3]&~n[2]&n[1]&~n[0])  |  // 0010 → 2
      ( n[3]&n[2]&~n[1]&~n[0])  |  // 1100 → C
      ( n[3]&n[2]&n[1]&~n[0])   |  // 1110 → E
      ( n[3]&n[2]&n[1]&n[0]);      // 1111 → F
     
    // Segment D is off for1, 4, 7, 9, A, F
    assign seg[3] = 
      (~n[3]&~n[2]&~n[1]&n[0])  |  // 0001 → 1
      (~n[3]&n[2]&~n[1]&~n[0])  |  // 0100 → 4
      (~n[3]&n[2]&n[1]&n[0])    |  // 0111 → 7
      ( n[3]&~n[2]&~n[1]&n[0])  |  // 1001 → 9
      ( n[3]&~n[2]&n[1]&~n[0])  |  // 1010 → A
      ( n[3]&n[2]&n[1]&n[0]);      // 1111 → F
      
     // Segment E is off for 1, 3, 4, 5, 7, 9
     assign seg[4] =
      (~n[3]&~n[2]&~n[1]&n[0]) |    // 0001 → 1
      (~n[3]&~n[2]& n[1]&n[0]) |    // 0011 → 3
      (~n[3]& n[2]&~n[1]&~n[0]) |   // 0100 → 4
      (~n[3]& n[2]&~n[1]&n[0]) |    // 0101 → 5
      (~n[3]& n[2]& n[1]&n[0]) |    // 0111 → 7
      ( n[3]&~n[2]&~n[1]&n[0]);     // 1001 → 9
      
      // Segment F is off for 1, 2, 3, 7, d
      assign seg[5] =
          (~n[3]&~n[2]&~n[1]&n[0]) |    // 0001 → 1
          (~n[3]&~n[2]& n[1]&~n[0]) |   // 0010 → 2
          (~n[3]&~n[2]& n[1]&n[0]) |    // 0011 → 3
          (~n[3]& n[2]& n[1]&n[0]) |    // 0111 → 7
          ( n[3]& n[2]&~n[1]&n[0]);     // 1101 → d
          
      // Segment G is off for 0, 1, 7, C
      assign seg[6] =
          (~n[3]&~n[2]&~n[1]&~n[0]) |   // 0000 → 0
          (~n[3]&~n[2]&~n[1]&n[0])  |   // 0001 → 1
          (~n[3]& n[2]& n[1]&n[0])  |   // 0111 → 7
          ( n[3]& n[2]&~n[1]&~n[0]);    // 1100 → C
  */

endmodule