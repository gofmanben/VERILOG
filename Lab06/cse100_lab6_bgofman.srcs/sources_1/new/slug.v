`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/08/2025 09:03:37 PM
// Design Name: 
// Module Name: slug
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

// Page 4: 6. The slug is a 16 by 16 pixel yellow square (or a shape that fits in this square and touches all 4
// sides of the square). The top edge of the slug is in row 360 and the slug is initially in the middle of the middle track.

module slug(
  input  wire        clk,             // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
  input  wire        frame_tick,      // Frame clock: 1 pulse per frame (from frame_tick)
  input  wire        freeze,          // Page 4: 7. The slug cannot move or change until the game starts (btnC is pressed).
  input  wire [9:0]  x,               // current pixel x from VGA pipeline
  input  wire [9:0]  y,               // current pixel y from VGA pipeline
  input  wire signed [1:0] position,  // expects -1 (left), 0 (middle), +1 (right) - two's complement
  output wire        busy_o,          // high while the slug is animating toward the target lane center
  output wire        slug_o           // 1 when (x,y) is inside the slug's 16x16 box
);

  // Constants
  wire signed [10:0] STEP_PX = 11'd2;    // Page 4: 12. The slug will move horizontally at 2 pixels per frame while it is transitioning.

  // Page 3: In this game, a slug must avoid trains traveling down tracks by jumping between the three tracks or hovering above the middle track.
  wire signed [1:0] pos_s = position;    // alias as signed value for clarity
  wire [9:0] target_x =
       // Page 4: 9. During the game, the slug is either at rest, centered on one of the three tracks, or transitioning between two adjacent tracks.
      (pos_s == 0) ? `MIDDLE_LINE :      // 0 → middle
      // Page 4: 11. Pressing btnL starts the transition to the adjacent track on the left (unless the slug is on the leftmost track).
      (pos_s <  0) ? `LEFT_LINE   :      // -1 → left
      // Page 4: 10. Pressing btnR starts the transition to the adjacent track on the right (unless the slug is on the rightmost track).
                     `RIGHT_LINE;        // +1 → right

  // ---------------- Animation control ----------------
  wire [9:0] cur_x;                      // current animated x-center of the slug
  
  // We cast both 10-bit unsigned coordinates to signed because the result may be negative (moving left).
  // The difference can range from -639 to +639 (H_RES = 0...639), which requires 11 bits to represent safely:
  //   10-bit signed range  = -512 .. +511  (too small)
  //   11-bit signed range  = -1024 .. +1023 (fits)
  // This ensures the subtraction works correctly and doesn't overflow when cur_x > target_x.
  wire signed [10:0] diff = $signed({1'b0, target_x}) - $signed({1'b0, cur_x});  // Compute signed difference between target and current X positions.
  wire signed [10:0] step =               // Page 3: slides the slug one track to the left/right.
       (diff >  STEP_PX) ?  STEP_PX :     // move right by STEP_PX
       (diff < -STEP_PX) ? -STEP_PX :     // move left  by STEP_PX
                           diff;          // final small step
                           
  wire signed [10:0] moved = $signed({1'b0, cur_x}) + step;     // cur_x ± step toward target_x
  wire [9:0] next_x = (freeze && cur_x == 0)  ? `MIDDLE_LINE :  // Page 4: and the slug is initially in the middle of the middle track
                       freeze                 ? cur_x        :  // stay frozen
                       frame_tick             ? moved[9:0]   :  // move toward target
                                                cur_x;
  FDRE #(.INIT(1'b0)) _cur_x [9:0] (.C (clk), .CE(1'b1), .R (1'b0), .D (next_x), .Q (cur_x));

  // ---------------- Bounding box & pixel flag ----------------
  wire [9:0] slug_x0 = cur_x - (`SLUG_SIZE >> 1);               // left edge of slug box
  wire [9:0] slug_x1 = slug_x0 + `SLUG_SIZE;                    // right edge (exclusive)
  wire [9:0] slug_y0 = `SLUG_TOP_ROW;                           // top edge (fixed)
  wire [9:0] slug_y1 = (`SLUG_TOP_ROW + `SLUG_SIZE);            // bottom edge (exclusive)
  
  assign busy_o = (cur_x != target_x);                          // Page 5: 13. Once a transition has started it will continue

  // Page 4: this square and touches all 4 sides of the square
  assign slug_o = (x >= slug_x0) && (x < slug_x1) &&            // inside horizontal span
                  (y >= slug_y0) && (y < slug_y1);              // inside vertical span

endmodule
