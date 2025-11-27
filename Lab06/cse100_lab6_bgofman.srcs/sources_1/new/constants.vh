// ============================================================================
// constants.vh
// ---------------------------------------------------------------------------
// Global constants used across modules (shared by multiple source files).
// Include this file with:  `include "constants.vh"`
// ============================================================================

// Vivado reset command: reset_run synth_1; reset_run impl_1; launch_runs impl_1 -to_step write_bitstream

`ifndef CONSTANTS_VH
`define CONSTANTS_VH

// Page 4: 1. The playing area is the 640 x 480 screen.
`define H_RES 10'd640     // visible horizontal pixels - shown on screen
`define V_RES 10'd480     // Page 3: There is also some time between rows and between frames (after all 480 rows)
                          // Page 3: which allows the cathode ray to be re-positioned for the next row or frame.
                          // visible vertical lines - shown on screen

`define FREQ_HZ        6'd60        // Page 4: the monitor is being refreshed roughly 60 times per second: at 60Hz.
`define SLUG_SIZE      5'd16        // Page 4: 6. The slug is a 16 by 16 pixel yellow square (or a shape that fits in this square and touches all 4 sides of the square).
`define SLUG_TOP_ROW   9'd360       // Page 4: The top edge of the slug is in row 360

`define BORDER         10'd8        // Page 4: 2. The border along all 4 edges of the screen is white and 8 pixels wide.

`define TRACK_H        6'd60        // Page 4: 4. There are three vertical tracks that are each 60 pixels wide.
                                    // Page 5: Trains are 60 pixels wide.
`define TRACK_GAP      4'd10        // Page 4: with 10 pixels between adjacent tracks.

`define MIN_TRAIN_V    6'd60        // Page 5: 28. The length of the train is 60 + B pixels 
`define MAX_TRAIN_V    7'd123       // where B is a randomly selected number between 0 and 63.

  // Page 5: 25. When the bottom of either train reaches row 400 (440 for the middle track) the other train
  // will start in the same manner: picking a random length and waiting a random time before descending.
 `define ROW_HEIGHT    11'sd400                // total used vertical height for one section
 `define ROW_GAP      (11'sd440 - `ROW_HEIGHT) // using 40 px gap between trains/sctions for maneuvering slug (16 px)

// Page 4: 5. The tracks should be positioned in the right 2/3's of the screen
`define MIDDLE_LINE `H_RES - (`H_RES / 3)   // in the right 2/3's of the screen
`define LEFT_LINE   `MIDDLE_LINE - `TRACK_H - `TRACK_GAP  // center of left lane
`define RIGHT_LINE  `MIDDLE_LINE + `TRACK_H + `TRACK_GAP  // center of right lane

`endif // CONSTANTS_VH
