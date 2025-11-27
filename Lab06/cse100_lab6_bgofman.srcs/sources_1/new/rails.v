`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/25/2025 03:19:47 PM
// Design Name: 
// Module Name: rails
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

`include "constants.vh"

module rails(
  input  wire [9:0]  x,           // Current pixel X position (0..799)
  input  wire [9:0]  y,           // Current pixel Y position (0..524) - not used in this module
  output wire        rails_o      // High when (x,y) lies inside any rail region
);

 // Geometry constants for the rails
  wire [9:0] RAIL_WIDTH = 10'd1;   // Width of each rail in pixels (1 pixel wide)
  wire [9:0] RAIL_GAP   = 10'd8;   // Distance from track center to each rail
  wire [9:0] TIE_WIDTH  = 10'd4;   // Width of each tie (crossbeam)
  wire [9:0] TIE_GAP    = 10'd15;  // Vertical spacing between ties;

  // Track geometry
  wire [9:0] HALF_TRAIN = `TRACK_H >> 1;         // Half of the track width; e.g., 60 >> 1 = 30
  wire [9:0] margin     = HALF_TRAIN - RAIL_GAP; // Horizontal offset from the track center to each rail line:

  // Compute X positions for left-side rails (one for each lane)
  wire [9:0] x0 = `LEFT_LINE   - margin; // X of the left rail in the left lane  (center minus margin)
  wire [9:0] x1 = `MIDDLE_LINE - margin; // X of the left rail in the middle lane
  wire [9:0] x2 = `RIGHT_LINE  - margin; // X of the left rail in the right lane

  // Compute X positions for right-side rails (one for each lane)
  wire [9:0] x3 = `LEFT_LINE   + margin; // X of the right rail in the left lane (center plus margin)
  wire [9:0] x4 = `MIDDLE_LINE + margin; // X of the right rail in the middle lane
  wire [9:0] x5 = `RIGHT_LINE  + margin; // X of the right rail in the right lane
  
  // ---------------- Rails (vertical) ----------------
  wire rails_only =
         (x >= x0 && x <= x0 + RAIL_WIDTH) || // left lane, left rail
         (x >= x1 && x <= x1 + RAIL_WIDTH) || // middle lane, left rail
         (x >= x2 && x <= x2 + RAIL_WIDTH) || // right lane, left rail
         (x >= x3 - RAIL_WIDTH && x <= x3) || // left lane, right rail
         (x >= x4 - RAIL_WIDTH && x <= x4) || // middle lane, right rail
         (x >= x5 - RAIL_WIDTH && x <= x5);   // right lane, right rail

  // ---------------- Ties (horizontal) ----------------
  // Horizontal span of each track (between the two vertical rails)
  wire left   = (x >= x0 - RAIL_GAP) && (x <= x3 + RAIL_GAP);       // Inside left track horizontal region
  wire middle = (x >= x1 - RAIL_GAP) && (x <= x4 + RAIL_GAP);       // Inside middle track horizontal region
  wire right  = (x >= x2 - RAIL_GAP) && (x <= x5 + RAIL_GAP);       // Inside right track horizontal region

  // Ties appear whenever: y modulo TIE_GAP is less than TIE_WIDTH (creates repeating horizontal bars)
  wire ties_on = (left | middle | right) &&   // Inside any track horizontally
                 (y % TIE_GAP < TIE_WIDTH);   // Inside the TIE_WIDTH-tall repeating sleeper

  assign rails_o = rails_only | ties_on;      // Combine rails + ties
  
endmodule
