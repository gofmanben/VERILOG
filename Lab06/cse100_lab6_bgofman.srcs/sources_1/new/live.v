`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/25/2025 11:25:49 AM
// Design Name: 
// Module Name: live
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

module live(
  input  wire        clk,             // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
  input  wire        up,              // Page 9: set of lives for the player, loadable with btnL
  input  wire        dw,              // Page 9: They lose a life when colliding with a train.

  input  wire [9:0]  x,               // current pixel x from VGA pipeline
  input  wire [9:0]  y,               // current pixel y from VGA pipeline
  output wire        has_lives,       // High when lives > 0
  output wire        lives_o          // High when (x,y) lies inside any life icon
);
  
  // Maximum lives we care about in logic/drawing (0..3)
  wire [2:0] MAX_LIVES = 3;

  // Padding and spacing
  wire [4:0] PAD   = 10;   // gap from border to first life
  wire [4:0] SPACE = 10;   // gap between icons
        
  wire [15:0] lives;
  countUD16L _lives (.clk_i (clk),
    .up_i  (up && lives < MAX_LIVES),
    .dw_i  (dw && lives > 0),
    .ld_i  (1'd0), .Din_i (16'd0), .Q_o (lives), .utc_o (), .dtc_o ()
  );
  
  // ---------------- Geometry for life icons ----------------

  // Vertical placement (bottom row of icons)
  wire [9:0] y0 = `V_RES - `BORDER - PAD;             // bottom edge of icons
  wire [9:0] y1 = y0 - `SLUG_SIZE;                    // top edge of icons (height = SLUG_SIZE)

  // X ranges for three life icons
  wire [9:0] x0_0 = `BORDER + PAD;                    // left of life 1
  wire [9:0] x0_1 = x0_0 + `SLUG_SIZE;                // right of life 1

  wire [9:0] x1_0 = x0_1 + SPACE;                     // left of life 2
  wire [9:0] x1_1 = x1_0 + `SLUG_SIZE;                // right of life 2

  wire [9:0] x2_0 = x1_1 + SPACE;                     // left of life 3
  wire [9:0] x2_1 = x2_0 + `SLUG_SIZE;                // right of life 3

  // ---------------- Drawing: which pixels belong to life icons ----------------
  wire life1 = (lives >= 1) & (x >= x0_0) & (x < x0_1);      // First icon shown when lives >= 1
  wire life2 = (lives >= 2) & (x >= x1_0) & (x < x1_1);      // Second icon shown when lives >= 2
  wire life3 = (lives >= 3) & (x >= x2_0) & (x < x2_1);      // Third icon shown when lives >= 3

  assign lives_o = ((y >= y1) & (y < y0)) &                  // Check if current pixel is inside vertical band for life icons
                    (life1 | life2 | life3);                 // lives is high if we're in the vertical band and in any icon
        
  assign has_lives = (lives > 0);                            // True when lives (0..3) is not zero
    
endmodule
