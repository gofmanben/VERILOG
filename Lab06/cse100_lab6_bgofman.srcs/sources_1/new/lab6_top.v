`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/07/2025 07:01:42 PM
// Design Name: 
// Module Name: lab6Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  Page 3: You will design and implement a version of the game "Subway Slugging" using the BASYS3 board and the VGA monitor connected to it.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "constants.vh"

/*
test_lab6_sync.v

   lab6Top UUT (
      .btnU(btnU),      //jumpinh
      .btnC(btnC),      //start
      .btnR(greset),    // btnC is greset
      .btnL(btnL),      //extra credit - comment this for baseline functionality
      .clkin(clkin), 
      .seg(seg), 
      .dp(dp), 
      .an(an),
      .vgaBlue(vgaBlue),
      .vgaRed(vgaRed),
      .vgaGreen(vgaGreen),        
      .Vsync(VS), 
      .Hsync(HS), 
      .sw(sw), 
      .led(led)
   );
*/
module lab6Top (
  input  wire btnU,           // Page 3: the slug is in the middle, then the slug will hover while btnU is pressed.
  input  wire btnC,           // Page 3: Pressing btnC starts the game.
                              // Page 4: 7. The slug cannot move or change until the game starts (btnC is pressed).
                              // Page 9: You may decide if the game coninues when a life is lost or if the game pauses when a life is lost, then pressing btnC resumes game.
  input  wire btnR,           // Page 3: When the game starts the trains will start traveling down the tracks and pressing btnL/btnR 
  input  wire btnL,           // slides the slug one track to the left/right.
  input  wire btnD,           // Page 3: No other pushbutton has an effect before the game starts (except the global reset, btnD, of course).
                              // Page 9: Once all lives are lost, the game enters the loss state until the game is reset with btnD.
  input  wire clkin,          // Page 2: Your designs must be synchronous with the system clock specified in the lab.
  output wire [6:0]  seg,     // Page 6: While only two 7-segment displays are required, you may find it useful to allow other
  output wire        dp,      // information from your design to be displayed on the remaining two.
  output wire [3:0]  an,      // Page 3: The score, initially 0, is displayed on AN1 and AN0.

  // Page 3: To control the monitor you must generate two control signals, Hsync and Vsync,
  output wire        Hsync,   // Page 4: The horizontal synchronization signal (Hsync) should be low exactly for the 96 pixels in each row starting with the 656th pixel and high for the rest.
  output wire        Vsync,   // Page 4: The vertical synchronization signal (Vsync) should be low exactly for all of the pixels in the 490th and 491st rows
                              // and high for all pixels in all other rows.

  // as well as the 12 RGB data signals (vgaRed[3:0], vgaBlue[3:0], and vgaGreen[3:0]) for each of the screen's 640 x 480 pixels.
  output wire [3:0] vgaBlue,  // 4-bit output signal for the blue color channel
  output wire [3:0] vgaRed,   // 4-bit output signal for the red color channel
  output wire [3:0] vgaGreen, // 4-bit output signal for the green color channel
 
  input  wire [15:0] sw,      // Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
  output wire [15:0] led      // You may find it useful to display certain signals on the leds
);

  // Page 6: 3. Add an instance of the module labVGA clks to your top level as follows:
  wire clk, digsel;
  labVGA_clks not_so_slow (  // Page 6: The module labVGA clks is provided.
    .clkin  (clkin),  // 100 MHz board clock input from Basys3
    .greset (btnD),   // Page 3: Only the global reset, btnD, will have an effect when the game is over.
    .clk    (clk),    // Page 6: When you simulate with labVGA clks, the clk signal will have the same timing as on the board: it is a 25MHz clock.
    .digsel (digsel)  // Only the signal digsel will be different.
  );

  // Page 7: (f) Next you can make the slug respond to btnL, btnR, and btnU. You will need a state machine to make it transition,
  // and hover only when it is on the middle track. You'll need to coordinate the hovering and the energy level bar.
  wire btnC_edge, btnL_edge, btnR_edge;
  edge_detector _start (.clk_i(clk), .button_i(btnC), .edge_o(btnC_edge));  // Page 4: 8. Pressing btnC will start the game.
  edge_detector _left  (.clk_i(clk), .button_i(btnL), .edge_o(btnL_edge));  // Page 4: Pressing btnL starts the transition to the adjacent track on the left
  edge_detector _right (.clk_i(clk), .button_i(btnR), .edge_o(btnR_edge));  // Page 4: Pressing btnR starts the transition to the adjacent track on the right

  wire pause_game;            // Page 9: if the game pauses when a life is lost, then pressing btnC resumes game.
  wire game_over;             // Page 5: 32. When the game is over, pressing btnD will start a new game.
  wire game_started;          // Page 4: 7. The slug cannot move or change until the game starts (btnC is pressed).

  // Page 6: A new module generates the V/H coordinates (i.e. pixel address) of the current pixel
  wire [9:0] x, y;            // Current scan position (x: column 0-799, y: row 0-524)
  wire active;                // High only when (x < 640 && y < 480)
  wire frame_tick;            // Frame clock: 1 pulse per frame (from frame_tick)

  // Page 6: (a) Implement a VGA controller that outputs the Hsync and Vsync signals, and provides the
  // pixel address and indicator for the active region while displaying a single color.
  vga_controller _vga (
    .greset(`ifdef SYNTHESIS btnD `else btnR_edge `endif),  // testbench reset
     //  40 ns → 25 MHz   (VGA pixel clock)
    .clk        (clk),        // Page 4: The value of the RGB data signals determine the color displayed for pixels in the Active Region, 
                              // with one cycle of the 25MHz clock corresponding to a pixel.
    .x          (x),          // Current horizontal pixel index (0-799)
    .y          (y),          // Current vertical line index (0-524)
    .Hsync      (Hsync),      // Horizontal sync output (active low)
    .Vsync      (Vsync),      // Vertical sync output (active low)
    .active     (active),     // Page 4: For a pixel outside the Active Region the 12 RGB data signals should be low.
    .frame_tick (frame_tick)
  );
  
  // Page 4: The border along all 4 edges of the screen
  wire border_o;
  area _area (
    .x        (x),        // current pixel column (0..799)
    .y        (y),        // current pixel row    (0..524)
    .border_o (border_o)  // 1 when current pixel is within border area
  );
 
  // ============================================================
  // Next-state logic (pure combinational, 2-bit signed FSM)
  // ============================================================
  // current & next positions (signed 2-bit: -1 = 2'b11, 0 = 2'b00, +1 = 2'b01)
  wire signed [1:0] slug_pos;
  wire signed [1:0] next_pos;

  // one-hot press detection (ignore simultaneous)
  wire slug_busy;
  wire single = (btnL_edge ^ btnR_edge) & ~slug_busy;     // Page 5: 14. Pressing btnL or btnR during a transition or while the slug is hovering has no effect.
  // Page 3: When the game starts the trains will start traveling down the tracks and pressing btnL/btnR 
  wire l_only = single & btnL_edge;
  wire r_only = single & btnR_edge;

  // next state: -1 ↔ 0 ↔ +1 with single-step moves
  // Page 2: you may not use any procedural blocks in your design (i.e. always@, always ff@, always comb).
  // Page 2: You may only use assign statements and FDREs in your design.
  assign next_pos =
      game_over ? slug_pos                              : // Page 5: 30. A crash occurs whenever the slug is not hovering and it overlaps any train by at least 1 pixel.
      (r_only & slug_pos <  2'sd1) ? (slug_pos + 2'sd1) : // Page 4: 10. Pressing btnR starts the transition to the adjacent track on the right (unless the slug is on the rightmost track).
      (l_only & slug_pos > -2'sd1) ? (slug_pos - 2'sd1) : // Page 4: 11. Pressing btnL starts the transition to the adjacent track on the left (unless the slug is on the leftmost track).
                                      slug_pos;           // no movement or invalid combination, stay where you are
   
   wire game_started_next = game_started | btnC_edge;     // Page 4: but once the game is started btnC has no further effect.
  // ============================================================
  // Two FDRE flip-flops store slug_pos[1:0] 
  // Page 2: use only positive edge-triggered flip-flops (FDRE)
  // ============================================================
  FDRE #(.INIT(1'b0)) _gs (.C(clk), .CE(1'b1), .R(1'b0), .D(game_started_next), .Q(game_started));
   
  // Page 3: Initially, the slug and the energy level bar are displayed, but no trains are present.
  wire  freeze = ~game_started | pause_game | game_over; // Freeze the game
  
  FDRE #(.INIT(1'b0)) _slug0 (
    .C(clk),                    // Page 2: connect only the system clock as input to the clock pins of any sequential components
    .R(1'b0),                   // Page 2: not use asynchronous clears or pre-sets of any sequential elements,
    .CE(~freeze),               // Page 2: not connect the system clock as the input to any other logic.
    .D(next_pos[0]), .Q(slug_pos[0]));
  FDRE #(.INIT(1'b0)) _slug1 (.C(clk), .R(1'b0), .CE(~freeze), .D(next_pos[1]), .Q(slug_pos[1]));

  // Page 7: (c) Display the player.
  // Page 9: The player looks like a slug
  wire slug_o;
  slug _slug (
    .clk        (clk),         // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
    .frame_tick (frame_tick),  // Frame clock: 1 pulse per frame (from frame_tick)
    .freeze     (freeze),      // Page 4: 7. The slug cannot move or change until the game starts (btnC is pressed).
    .x          (x),           // current pixel x from VGA pipeline
    .y          (y),           // current pixel y from VGA pipeline
    .position   (slug_pos),    // expects -1 (left), 0 (middle), +1 (right) - two's complement
    .busy_o     (slug_busy),   // high while the slug is animating toward the target lane center
    .slug_o     (slug_o)       // 1 when (x,y) is inside the slug's 16x16 box
  );

  // Page 5: 15. Holding btnU down while the slug is centered on the middle track
  wire at_middle = ~slug_pos[1] & ~slug_pos[0];
  
  wire hovering = btnU & at_middle;   // Page 3: If the energy level is not 0 and the slug is in the middle, then the slug will hover while btnU is pressed.
  wire hovering_o;                    // Page 7: You'll need to coordinate the hovering and the energy level bar.
  wire energy_o;                      // Page 4: 3. The green bar indicating the slug's energy level is near the left border.
  // Page 7: (d) Display the energy level bar.
  energy _energy (
    .clk        (clk),         // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
    .frame_tick (frame_tick),  // Frame clock: 1 pulse per frame (from frame_tick)
    .freeze     (freeze),      // Page 4: 8. Pressing btnC will start the game, but once the game is started btnC has no further effect.
    .x          (x),           // current pixel x from VGA pipeline
    .y          (y),           // current pixel y from VGA pipeline
    .hovering   (hovering),    // Page 7: (e) Make the energy level bar decrease/increase based on whether btnU is pressed.
    .hovering_o (hovering_o),  // Current energy level (0..192)
    .energy_o   (energy_o)     // High when (x,y) lies inside the green bar region
  );

  wire next_live = pause_game & btnC_edge & ~game_over; // Page 9: You may decide if the game coninues when a life is lost or if the game pauses when a life is lost
  // Page 7: (g) Next you should work on one track. Please make a separate module for a track.
  wire trains_o, end_train_o;
  track _track (
    .clk         (clk),           // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
    .frame_tick  (frame_tick),    // Frame clock: 1 pulse per frame (from frame_tick)
    .freeze      (freeze),        // Page 5: 31. If a crash occurs, the game is over: the trains stop moving
    .next_live   (next_live),     // You may decide if the game coninues when a life is lost or if the game pauses when a life is lost, then pressing btnC resumes game.
    .x           (x),             // current pixel x from VGA pipeline
    .y           (y),             // current pixel y from VGA pipeline
    .trains_o    (trains_o),      // 1 => current pixel is on any active train,
    .end_train_o (end_train_o)    // 1 => when the current pixel is the bottom-right corner of the any train sprite
  );
  
  // Page 9: In addition to satisfying all lab requirements described in the lab manual, add logic 
  // to your design that provides a set of lives for the player, loadable with btnL.
  wire lives_o, has_lives, life_down_pulse;
  live _live (
    .clk          (clk),                        // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
    .up           (~game_started & btnL_edge),  // Page 9: set of lives for the player, loadable with btnL
    .dw           (life_down_pulse),            // Page 9: They lose a life when colliding with a train.
    .x            (x),                          // current pixel x from VGA pipeline
    .y            (y),                          // current pixel y from VGA pipeline
    .has_lives    (has_lives),                  // High when lives > 0
    .lives_o      (lives_o)                     // High when (x,y) lies inside any live
  );
  
  // Page 5. train tracks are visible for each train  
  wire rails_o;
  rails _rails (
    .x          (x),                            // current pixel x from VGA pipeline
    .y          (y),                            // current pixel y from VGA pipeline
    .rails_o    (rails_o)                       // High when (x,y) lies inside any rail region
  );
  
  wire rails_on = rails_o & sw[2];  // Draw rails only when switch 2 active

  // Page 7: (h) The last piece is to instantiate the other two tracks, and provide a top level state machine 
  // to start the tracks, the slug, and end the game when there is a crash.
  wire crash_now = slug_o &                         // Page 9: They lose a life when colliding with a train.
                   trains_o &                       // Page 3: A collision with a train ends the game and the number of trains the slug has avoided is the score.
                   ~hovering_o &                    // Page 3: A crash occurs if the slug is not hovering and overlaps a train.
                   ~sw[3];                          // Page 3: Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
  
  // ============================================================
  // Page 6: This may contain multiple modules itself, and may have similar components to Lab 4/5. 
  // You can reuse code from prior labs, but it must be your code. (countUD4L/countUD16L/edge_detector/lfsr/ring_counter/selector/hex7seg)
  // ============================================================
  wire pause_game_next = pause_game | crash_now;          // Page 5: unless the game ends (a crash occurs).
  FDRE #(.INIT(1'b0)) _pause_game(.C(clk), .CE(1'b1), .R(btnC_edge), .D(pause_game_next), .Q(pause_game));

  wire pause_game_prev;
  FDRE #(.INIT(1'b0)) _pause_prev (.C (clk), .CE(1'b1), .R (1'b0), .D (pause_game), .Q (pause_game_prev));
  assign life_down_pulse = pause_game & ~pause_game_prev; // ONE CLOCK pulse when pause_game goes 0 -> 1
  
  // Page 9: Once all lives are lost, the game enters the loss state until the game is reset with btnD.
  wire game_over_next = ~has_lives & pause_game;
  // Page 5: 32. When the game is over, pressing btnD will start a new game.
  FDRE #(.INIT(1'b0)) _game_over(.C(clk), .CE(~game_over), .R(1'b0), .D(game_over_next), .Q(game_over)); // Page 4: unless the game ends (a crash occurs).

  // Page 3: Each time a train passes the slug, a point is scored.
  wire [15:0] score;                                      // Page 3: The score, initially 0
  countUD16L _score (.clk_i (clk), .Q_o (score), .up_i (frame_tick & end_train_o), 
        .dw_i (1'b0), .ld_i  (1'b0), .Din_i (16'd0), .utc_o (), .dtc_o ());
  
  // Page 6: The RingCounter/Selector/hex7seg logic may be reused from prior labs, but it must be your own code.
  wire [3:0] ring; // active-low pattern: 1110 -> 1101 -> 1011 -> 0111 -> ...
  ring_counter _ring (.clk_i(clk), .advance_i(digsel), .ring_o(ring));
  
  // Page 3. The score, initially 0, is displayed on AN1 and AN0.
  wire [15:0] nibbles = {8'h00, score[7:0]};                   // Upper two hex digits are 00, lower two show score[7:0]
  wire [3:0]  hex_sel;
  selector _sel (.N_i(nibbles), .Sel_i(~ring), .H_o(hex_sel)); // selector expects active-HIGH one-hot
  
  // Page 6: While only two 7-segment displays are required, you may find it useful to allow other information from your design to be displayed on the remaining two.
  wire [6:0] seg_q;
  hex7seg _hex (.n(hex_sel), .seg(seg_q));
  
  // Page 3: Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
  wire cheat = trains_o & sw[3];
  
  wire [4:0] flash_cnt;                                 // 5-bit modulo-30 counter driven by frame_tick (~60 Hz)
  wire flash_cnt_wrap       = (flash_cnt == 5'd18);     // Counts 0 → 18, then wraps to 0. One full cycle ~0.3 seconds.
  wire [4:0] flash_cnt_next = flash_cnt_wrap ?  5'd0 :  // restart count
         (~frame_tick ? flash_cnt : flash_cnt + 5'd1);  // otherwise increment
  FDRE #(.INIT(1'b0)) _flash_cnt [4:0] (.C (clk), .CE(1'b1), .R (1'b0), .D (flash_cnt_next), .Q (flash_cnt));
  
  wire flash;                                           
  wire flash_next = flash_cnt_wrap ? ~flash : flash;    // Flashing bit: toggle every ~0.3 seconds.
  FDRE #(.INIT(1'b0)) _flash (.C(clk), .CE(1'b1), .R(1'b0), .D (flash_next), .Q (flash));
  
  wire flashing = flash & (hovering_o |                 // Page 3. The slug should change color and flash while it is hovering.
                           game_over);                  // Page 3. A crash ends the game, and when the game is over, the slug and all trains stop moving, and the slug flashes.
                                                        // Page 5: the slug stops moving and flashes, and only btnD can have an effect.
  // Page 6: A new module is needed to produce the 16-bit RGB pixel data from the user input, the pushbuttons/switches, and the pixel address and manage gameplay
  wire [3:0] slug_Red   = flashing   ? 4'h0 :           // While slug NOT on a train, turn off (black background flash)
                          hovering_o ? 4'hF :           // Page 5. 16. The slug changes color while it is hovering.
                          cheat      ? 4'hF :           // Page 3. Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
                                       4'hF;            // slug → yellow  (R = 255)  Page 4: The slug is a 16 by 16 pixel yellow square
                                       
  wire [3:0] slug_Green = flashing   ? 4'h0 :           // While slug NOT on a train, turn off (black background flash)
                          hovering_o ? 4'h4 :           // Page 5. 16. The slug changes color while it is hovering.
                          cheat      ? 4'hF :           // Page 3. Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
                                       4'hF;            // slug → yellow  (G = 255)
                          
  wire [3:0] slug_Blue  = flashing & trains_o ? 4'hF :  // Flash blue when slug overlaps a train
                          flashing   ? 4'h0 :           // While slug NOT on a train, turn off (black background flash)
                          hovering_o ? 4'hF :           // Page 5. 16. The slug changes color while it is hovering.
                          cheat      ? 4'hF :           // Page 3. Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
                                       4'h0;            // slug → yellow  (B = 0)

  // Page 3: To control the monitor you must generate two control signals, Hsync and Vsync, as well as the 12
  // RGB data signals (vgaRed[3:0], vgaBlue[3:0], and vgaGreen[3:0]) for each of the screen's 640 x 480 pixels.
  // Priority drawing: border > energy > slug > lives > trains > background
  wire [3:0] Rgb  = border_o             ? 4'hF       :  // border → white (R = 255)  Page 4: The border along all 4 edges of the screen is white
                    energy_o             ? 4'h0       :  // energy → green (R = 0)    Page 4: 3. The green bar indicating the slug's energy level is near the left border
                    slug_o               ? slug_Red   :  // slug   → (see slug_Red)   Page 3. The slug should change color 
                    lives_o              ? 4'hF       :  // slug → yellow  (R = 255)  Page 4: The slug is a 16 by 16 pixel yellow square
                    rails_on             ? 4'h6       :  // rails → brown (R = 102)   Page 5. train tracks are visible for each train
                    trains_o             ? 4'h0       :  // train  → blue  (R = 0)
                    4'h0;                                // background → black (R = 0)

  wire [3:0] rGb  = border_o             ? 4'hF       :  // border → white (G = 255)
                    energy_o             ? 4'hF       :  // energy → green (G = 255)
                    slug_o               ? slug_Green :  // slug   → (see slug_Green)
                    lives_o              ? 4'hF       :  // slug → yellow  (G = 255)
                    rails_on             ? 4'h3       :  // rails → brown (G = 51)
                    trains_o             ? 4'h0       :  // train  → blue  (G = 0)
                    4'h0;                                // background → black (R = 0)

  wire [3:0] rgB  = border_o             ? 4'hF       :  // border → white (B = 255)
                    energy_o             ? 4'h0       :  // energy → green (B = 0)
                    slug_o               ? slug_Blue  :  // slug   → (see slug_Blue) 
                    lives_o              ? 4'h0       :  // slug → yellow  (B = 0)
                    rails_on& trains_o   ? 4'hF       :  // rails → brown (B = 255)
                    rails_on             ? 4'h1       :  // rails → brown (B = 17)
                    trains_o             ? 4'hF       :  // train  → green (B = 255)
                    4'h0;                                // background → black (B = 0)
  
  // Page 3: RGB data signals (vgaRed[3:0], vgaBlue[3:0], and vgaGreen[3:0])                  
  assign vgaRed   = active ? Rgb : 4'h0;
  assign vgaGreen = active ? rGb : 4'h0;
  assign vgaBlue  = active ? rgB : 4'h0;

  assign dp  = 1'b1;              // off
  assign an = {2'b11, ring[1:0]}; // Page 3: is displayed on AN1 and AN0.
  assign seg = seg_q;             // output the decoded segment pattern to the 7-segment display
  assign led = sw;                // display the state of switches on the board LEDs

endmodule