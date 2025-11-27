`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Benjamin Gofman
//
// Create Date: 11/08/2025 08:27:00 PM
// Design Name:
// Module Name: track
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

module track (
  input  wire        clk,         // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
  input  wire        frame_tick,  // Frame clock: 1 pulse per frame (from frame_tick)
  input  wire        freeze,      // Page 4: 7. The slug cannot move or change until the game starts (btnC is pressed).
  input  wire        next_live,   // Page 9: You may decide if the game coninues when a life is lost or if the game pauses when a life is lost
  input  wire [9:0]  x,           // current pixel x from VGA pipeline
  input  wire [9:0]  y,           // current pixel y from VGA pipeline
  output wire        trains_o,    // 1 => current pixel is on any active train,
  output wire        end_train_o  // 1 => when the current pixel is the bottom-right corner of the any train sprite
);

  // Page 5: 21. Pressing btnC opens the three tracks in the following order: the left track is first, 
  // followed by the right track 2 seconds later, and finally the middle track 6 seconds after the right track.
  wire [9:0] DELAY_1 = 10'd2;                         // the left track is first, followed by the right track 2 seconds later
  wire [9:0] DELAY_2 = DELAY_1 + 10'd6;               // the middle track 6 seconds after the right track.
  wire [9:0] DELAY_3 = DELAY_2 + 10'd7;               // disable start delay count after 15 seconds (2 + 6 + 7 = 15)
  
  // ----------------------- start-after-delay (in frames) -----------------------
  wire [15:0] start_delay;                            // Page 7: You'll need a timer for the staggered track opening and to make things flash.
  countUD16L _start_delay (.clk_i (clk),
    .up_i  (frame_tick & ~freeze & (start_delay < (DELAY_3 * `FREQ_HZ))), // start increment after btnC pressed and stop incrementing after 15 seconds (cap)
    .dw_i  (1'b0), .ld_i  (next_live), .Din_i (16'd0), .Q_o   (start_delay), .utc_o (), .dtc_o ()
  );

  // ----------------------- Motion generators for two rows ----------------------
  wire [15:0] count_0, count_1;                        // free-running (with occasional load) frame counters
  
  // Use 11 signed bits because vertical math (R*_Y*) can go slightly negative (≈ -286) when trains are offscreen at the top, 
  // and positive up to ≈ +879. 11 bits (-1024..+1023) safely covers this full range; signed compare prevents wrap.
  wire signed [10:0] cursor_y0 = $signed(count_0[10:0]); // visible 0..~900 range, signed for geometry arithmetic
  wire signed [10:0] cursor_y1 = $signed(count_1[10:0]); // identical reasoning for the second baseline
  
  // Page 5: 26. The two trains continually move down their track, restarting each other until the game ends.
  wire reset_0 = frame_tick & cursor_y1 == `ROW_HEIGHT;   // reset first cursor y position after the first section reaches 400 px
  wire reset_1 = frame_tick & cursor_y0 == `ROW_HEIGHT &  // reset second cursor y position after the first section reaches 400 px
                 start_delay >=  DELAY_3 * `FREQ_HZ;      // enable after first rotation ("only after 15 s")
  
  // Page 5: the right track 2 seconds later
  countUD16L _count_0 (.clk_i (clk),
    .up_i  (frame_tick & ~freeze & start_delay >= DELAY_1 * `FREQ_HZ), // Page 5: the left track is first, followed by the right track 2 seconds later
    .dw_i  (1'b0), .ld_i  (next_live | reset_0), .Din_i (16'd0), .Q_o (count_0), .utc_o (), .dtc_o ()
  );
  
  // Page 5: and finally the middle track 6 seconds after the right track.
  countUD16L _count_1 (.clk_i (clk),
    .up_i  (frame_tick & ~freeze & start_delay >= DELAY_2 * `FREQ_HZ), // Page 5: the middle track 6 seconds after the right track
    .dw_i  (1'b0), .ld_i  (next_live | reset_1), .Din_i (16'd0), .Q_o (count_1), .utc_o (), .dtc_o ()
  );
  
  // ------------------------ Random lane selection (static) ------------------------
  // Page 5: 23. When a train starts, it will pick a random length, wait a random amount of time, 
  // and then descend at one pixel per frame until it is completely off the screen.
  wire [7:0] random0_n, random1_n;            // LFSR outputs: continuously running pseudo-random byte streams
  lfsr _lfsr0 (.clk_i(clk), .q_o(random0_n)); // Random source for section 1 (train heights/positions)
  lfsr _lfsr1 (.clk_i(clk), .q_o(random1_n)); // Random source for section 2 (train heights/positions)
  
  wire [9:0] random0_c, random1_c;            // Page 5: 25... will start in the same manner: picking a random length and waiting a random time before descending.
  // Latch a 10-bit random value for lane group 0 (trains 0-2).
  FDRE #(.INIT(1'b0)) _rnd0 [9:0] (
    .C  (clk),                                            // Clock: updates on rising edge
    .CE (reset_0 | (start_delay == DELAY_1 * `FREQ_HZ)),  // Page 3: There is also some time between rows and between frames
    .R  (1'b0),                                           // No asynchronous reset used
    .D  ({2'b00, random0_n}),                             // Input: zero-extend 8-bit random value to 10 bits
    .Q  (random0_c)                                       // Output: latched random bits for train group 0
  );

  // Latch a 10-bit random value for lane group 1 (trains 3-5).
  FDRE #(.INIT(1'b0)) _rnd1 [9:0] (
    .C  (clk),                                            // Clock: updates on rising edge
    .CE (reset_1 | (start_delay == DELAY_2 * `FREQ_HZ)),  // Page 3: There is also some time between rows and between frames
    .R  (1'b0),                                           // No asynchronous reset used
    .D  ({2'b00, random1_n}),                             // Input: zero-extend 8-bit random value to 10 bits
    .Q  (random1_c)                                       // Output: latched random bits for train group 1
  );
  
  // ------------------------------ Drawing logic ---------------------------------
  wire train0, train1, train2, train3, train4, train5; // Declare individual train signal wires (one per active train)
  
  wire score0, score1, score2, score3, score4, score5; // 1 if any train triggers its score pulse

  // Page 4:  They are not visible unless you choose to display them.

  // Trains 0-2 belong to the first section (row0_*), 
  train _train0 (.idx(2'd0), .random(random0_c), .x(x), .y(y), .cursor_y(cursor_y0), .train_o(train0), .score_o(score0));  // section 1, train 1
  train _train1 (.idx(2'd1), .random(random0_c), .x(x), .y(y), .cursor_y(cursor_y0), .train_o(train1), .score_o(score1));  // section 1, train 2
  train _train2 (.idx(2'd2), .random(random0_c), .x(x), .y(y), .cursor_y(cursor_y0), .train_o(train2), .score_o(score2));  // section 1, train 3
   
  // Trains 3-5 to the second section (row1_*).
  train _train3 (.idx(2'd0), .random(random1_c), .x(x), .y(y), .cursor_y(cursor_y1), .train_o(train3), .score_o(score3));  // section 2, train 4
  train _train4 (.idx(2'd1), .random(random1_c), .x(x), .y(y), .cursor_y(cursor_y1), .train_o(train4), .score_o(score4));  // section 2, train 5
  train _train5 (.idx(2'd2), .random(random1_c), .x(x), .y(y), .cursor_y(cursor_y1), .train_o(train5), .score_o(score5));  // section 2, train 6

  // ------------------------------- Final Output ---------------------------------
  // Combine all trains: if any is active at this pixel, output logic high (1)
  assign trains_o = train0 | train1 | train2 | train3 | train4 | train5;
  
  // Page 5: 27. When the top of the train reaches the row below the slug, a point is scored.
  assign end_train_o = score0 | score1 | score2 | score3 | score4 | score5; // High on any frame where at least one train's top is at the scoring row

endmodule
