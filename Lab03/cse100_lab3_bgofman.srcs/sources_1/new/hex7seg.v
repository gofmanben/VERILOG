`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/12/2025 02:08:50 PM
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
   output [6:0] seg // Output: segments {a, b, c, d, e, f, g}, where 0 = ON
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

endmodule
