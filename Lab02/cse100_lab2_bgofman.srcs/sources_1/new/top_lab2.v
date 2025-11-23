`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/09/2025 06:53:35 PM
// Design Name: 
// Module Name: top_lab2
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

// A V 1 = 1     A V 0 = A      A V ~A = 1  (+)
// A ^ 0 = 0     A ^ 1 = A      A ^ ~A = 0  (*)


module top_lab2(
    input [7:0] sw,     // Input: 8 switches (from SW bus on the board)
    input btnU,         // Input: "Up" button - command to change sign
    input btnR,         // Input: "Right" button - used to display only the first display (an[0])
    input clkin,        // Input: system clock signal (typically 100 MHz on Basys3)
    output [6:0] seg,   // Output: 7 segment lines of the display (usually active-low)
    output dp,          // Output: decimal point of the display
    output [3:0] an,    // Output: anodes (or cathodes) of the display digits (active lines select current digit)
    output [7:0] led    // Output: 8 LEDs on the board
    );

  // 1) LED mirror
  assign led = sw;      // Display the state of the switches directly on the LEDs

  // 2) Sign changer
  wire [7:0] D;         // Intermediate data bus: result (sw[7:0] or -sw[7:0])
  wire ovfl;            // Overflow flag (active level depends on SignChanger implementation)

  SignChanger u_signchanger (
    .A_i(sw),                   // Provide 8-bit number from switches
    .sign_i(btnU),              // Port sign_i: 0 -> sw[7:0]; 1 -> output -sw[7:0]
    .D_i(D),                    // Semantically it should be OUTPUT (usually D or -D)
    .ovfl_o(ovfl)               // Get overflow flag from SignChanger
  );

  // 3) Split into hi/lo nibble
  wire [3:0] lo_nibble = D[3:0];    // Lower nibble of the result for the right (or least significant) digit of the display
  wire [3:0] hi_nibble = D[7:4];    // Upper nibble of the result for the left (or most significant) digit of the display

  // 4) Hex to 7-seg encoders
  wire [6:0] seg_lo, seg_hi;        // Wires for segment patterns of each nibble (lower/higher)

  hex7seg u_hex_lo (.n(lo_nibble), .seg(seg_lo));   // Instance of nibble-to-7-segment encoder for lower nibble
  hex7seg u_hex_hi (.n(hi_nibble), .seg(seg_hi));   // Instance of nibble-to-7-segment encoder for upper nibble


  // 5) Digit selector (clock divider)
  wire dig_sel;                     // Signal to select active digit (display multiplexer)

  lab2_digsel u_digsel (
    .clkin(clkin),                  // Input clock (divided internally to get multiplexing frequency)
    .greset(btnR),                  // Connected to btnR
    .digsel(dig_sel)                // Output: current digit selection (0 -> lower, 1 -> upper)
  );

  // 6) Multiplex and drive seg & anodes (active-low anodes)
  assign seg = (dig_sel) ? seg_hi : seg_lo;   // Multiplex segment lines: when dig_sel=1 show upper nibble, otherwise lower
  assign an = dig_sel ?                       // dig_sel decides whether you're showing the upper or lower nibble.
    {ovfl ? 1'b0 : 1'b1, 1'b1, 1'b0, 1'b1} :  // For upper nibble (dig_sel == 1): If ovfl is 1, an[3] will be 0 (turning off digit 3), and an[2] will remain 1 (keeping digit 2 off).
    {1'b1, ovfl ? 1'b0 : 1'b1, 1'b1, 1'b0};   // For lower nibble (dig_sel == 0): If ovfl is 0, an[3] and an[2] will be 0 (enabling digits 3 and 2); otherwise, an[2] and an[3] will be 1 (turning them off).

  // 7) Decimal point: overflow indicator (active-low)
  assign dp = ~ovfl;                          // Decimal point: invert ovfl if the point is active-low (on Basys3 dp is active low)

endmodule
