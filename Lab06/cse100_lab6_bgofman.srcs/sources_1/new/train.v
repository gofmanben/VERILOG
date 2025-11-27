`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/11/2025 09:52:20 AM
// Design Name: 
// Module Name: train
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

module train(
  input  wire        [1:0]  idx,        // current train index (0=left, 1=middle, 2=right)
  input  wire        [9:0]  random,     // pseudo-random value for height and position calculation
  input  wire        [9:0]  x,          // current pixel x from VGA pipeline
  input  wire        [9:0]  y,          // current pixel y from VGA pipeline
  input  wire signed [10:0] cursor_y,   // vertical baseline (moves 1 px/frame)
  output wire               train_o,    // 1 => current pixel is on any active train
  output wire               score_o     // 1 when top of this train reaches row below slug
);

  // Signed compare: y is 0..479; cast to signed to avoid unsigned wrap vs negative bounds.
  wire signed [10:0] y_s = $signed({1'b0, y});
  
  // Page 5: 23. When a train starts, it will pick a random length
  wire [5:0]  slice_0    = random[5 + idx -: 6];                // For idx=0 → [5:0], idx=1 → [6:1], idx=2 → [7:2].  Max value = 6'b111111 (=63)
  wire [5:0]  slice_1    = random[6 + idx -: 6];                // For idx=0 → [6:1], idx=1 → [7:2], idx=2 → [8:3].  Max value = 6'b111111 (=63)

  // ----------------------------- Train heights -----------------------------
  wire [9:0] height_0 = `MIN_TRAIN_V + slice_0;  // Height of row-0 train (range 60..123)
  wire [9:0] height_1 = `MIN_TRAIN_V + slice_1;  // Height of row-1 train (range 60..123)

  // Available vertical placement window for each row
  wire [5:0] avail_0 = `MAX_TRAIN_V - height_0;  // Remaining free space above row-0 (0..63)
  wire [5:0] avail_1 = `MAX_TRAIN_V - height_1;  // Remaining free space above row-1 (0..63)

  // Page 5: 23 ... wait a random amount of time
  //   random_x * (avail_x + 1) produces a 12-bit number,
  //   where the upper 6 bits implement   floor( random_x * (avail+1) / 64 )
  wire [11:0] prod0 = random[5:0] * (avail_0 + 6'd1);  // Random offset candidate for row-0 (0..63 scaled)
  wire [11:0] prod1 = random[7:2] * (avail_1 + 6'd1);  // Independent random offset candidate for row-1

  // Page 5: 29. The random amount of wait time before descending is T frames where T is a randomly selected number between 0 and 127.
  wire [5:0] off0 = prod0[11:6];  // Vertical offset for row-0 within its allowed range
  wire [5:0] off1 = prod1[11:6];  // Vertical offset for row-1 within its allowed range

  // Page 5: 23 ... and then descend at one pixel per frame until it is completely off the screen.
  wire signed [10:0] y0_0 = cursor_y - off0;                           // Page 3: But the trains that will descend along these tracks will be visible.
  wire signed [10:0] y0_1 = y0_0 - height_0;                           // Top of row-0 rectangle

  // Page 5: picking a random length and waiting a random time before descending.
  wire signed [10:0] y1_0 = cursor_y - `MAX_TRAIN_V - `ROW_GAP - off1; // Bottom of row-1 rectangle
  wire signed [10:0] y1_1 = y1_0 - height_1;                           // Top of row-1 rectangle

  // Page 5: 26. The two trains continually move down their track, restarting each other until the game ends.
  wire row0 = (y_s >= y0_1) && (y_s <= y0_0);                          // Current pixel is inside row-0 train band
  wire row1 = (y_s >= y1_1) && (y_s <= y1_0);                          // Current pixel is inside row-1 train band

  // -------------------- Horizontal lane geometry (right 2/3) ---------------------
  wire [9:0] HALF_TRAIN = `TRACK_H >> 1;                                          // Half of the track width (60 >> 1 = 30)
  wire [9:0] x0_0 = `LEFT_LINE   - HALF_TRAIN, x0_1 = `LEFT_LINE   + HALF_TRAIN;  // left lane edges
  wire [9:0] x1_0 = `MIDDLE_LINE - HALF_TRAIN, x1_1 = `MIDDLE_LINE + HALF_TRAIN;  // middle lane edges
  wire [9:0] x2_0 = `RIGHT_LINE  - HALF_TRAIN, x2_1 = `RIGHT_LINE  + HALF_TRAIN;  // right lane edges

  // -----------------------------------------------------------------------------
  // FSM 'psedo' pattern → 3-bit control used to decide which row each train uses
  // r[0] → controls train 0 (idx = 0)
  // r[1] → controls train 1 (idx = 1)
  // r[2] → controls train 2 (idx = 2)
  // -----------------------------------------------------------------------------
  wire [2:0] r = random[2:0]; // Extract 3 least-significant bits from random

  // Normalize edge-case patterns: all zeros (000) or all ones (111).
  wire [2:0] fix_r =
      (r == 3'b000) ? 3'b100 :  // 000 → 100 : No bits set; default to selecting the left train.
      (r == 3'b111) ? 3'b001 :  // 111 → 001 : All bits set; default to selecting the right train.
                       r;       // 110, 101, 011  → Page 4. 20. Each track will have two trains.
                                // or 100, 010, 001 → Page 4. 22. When a track is opened, its first train with start.

  // Determine whether this particular train instance uses row1
  wire use_row1 =
      (idx == 2'd0) ? fix_r[0] :  // fix_r[0] → train1 (idx = 0)
      (idx == 2'd1) ? fix_r[1] :  // fix_r[1] → train2 (idx = 1)
                      fix_r[2];   // fix_r[2] → train3 (idx = 2)

  // Select the active vertical band (row0 or row1) based on the flag above.
  wire row_mask = use_row1 ? row1 : row0;  // row_mask = 1 means the current pixel (x, y) is inside the visible band of whichever row this train occupies.

  // Select lane by idx: 0->left, 1->middle, else->right
  assign train_o =
        (idx == 2'd0) ? (row_mask && (x > x0_0) && (x < x0_1)) :  // the current pixesl inside sprite for left-lane train
        (idx == 2'd1) ? (row_mask && (x > x1_0) && (x < x1_1)) :  // the current pixesl inside sprite for middle-lane train
                        (row_mask && (x > x2_0) && (x < x2_1));   // the current pixesl inside sprite for right-lane train

                        
  // Page 5: 27. When the top of the train reaches the row below the slug, a point is scored.
  wire signed [10:0] train_top = use_row1 ? y1_1 : y0_1;
  assign score_o = (train_top == (`SLUG_TOP_ROW + `SLUG_SIZE));
          
endmodule
