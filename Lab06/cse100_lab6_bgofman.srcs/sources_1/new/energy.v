`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/08/2025 12:47:35 PM
// Design Name: 
// Module Name: energy_bar
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

// Page 4: 3. The green bar indicating the slug's energy level is near the left border. 
// It is 20 pixels wide and 192 pixels long at the maximum energy level.

module energy (
  input  wire        clk,          // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
  input  wire        frame_tick,   // Frame clock: 1 pulse per frame (from frame_tick)
  input  wire        freeze,       // Page 4: 8. Pressing btnC will start the game, but once the game is started btnC has no further effect.
  input  wire [9:0]  x,            // Current pixel X position (0..799)
  input  wire [9:0]  y,            // Current pixel Y position (0..524)
  input  wire        hovering,     // btnU: 1 (energy decreases), 0 (energy increases)
                                   // Page 5: Holding btnU down while the slug is centered on the middle track and its energy level is not 0 will cause the slug to hover.
  output wire        hovering_o,   // Page 4: 192 pixels long at the maximum energy level
  output wire        energy_o      // High when (x,y) lies inside the green bar region
);

  // ---------------- Constants ----------------
  wire [9:0] BAR_W     = 10'd20;   // Page 4: It is 20 pixels wide
  wire [9:0] MAX_LEVEL = 10'd192;  // and 192 pixels long at the maximum energy level.
  wire [9:0] PAD       = 10'd10;   // Gap between border and energy bar

  // Page 3: Once the slug's energy level, displayed on the left, reaches 0 the slug will drop.
  wire [9:0] level_c, level_n;

  // Page 3: But hovering will use up energy. The slug will drop as soon as btnU is released or the energy level is down to 0.
  // Page 3: While the slug is not hovering the energy level increases.
  assign level_n =
          freeze                            ? MAX_LEVEL   :       // Page 3: If the energy level is not 0 and the slug is in the middle, then the slug will hover while btnU is pressed.
           hovering & (frame_tick && level_c > 10'd0)     ?       // Page 5: and its energy level is not 0 will cause the slug to hover.
                                              (level_c - 10'd1) : // Page 5: 18. While the slug is hovering its energy decreases level by 1 every frame down to 0.    
          ~hovering & (frame_tick && level_c < MAX_LEVEL) ?       // Page 3: The slug can only hover for a limited time
                                              (level_c + 10'd1) : // Page 3: The slug will drop as soon as btnU is released or the energy level is down to 0. (increasing bar)
                                                                  // Page 5: 19. While the slug is not hovering its energy level increases by 1 every frame up to a maximum of 192.
                                               level_c;           // Page 5: 17. When btnU is released or the slug's energy level reaches 0, the slug stops hovering.
               
  // Level register (updated once per frame)
  FDRE #(.INIT(1'b0)) _level [9:0] (.C (clk), .CE(1'b1), .R (1'b0), .D (level_n), .Q (level_c));

  // Page 4: 3. The green bar indicating the slug's energy level is near the left border.
  wire [9:0] x0 = `BORDER + PAD;                    // left edge
  wire [9:0] x1 = x0 + BAR_W;                       // right edge (exclusive)
  wire [9:0] y_bottom = `BORDER + PAD + MAX_LEVEL;  // fixed bottom
  wire [9:0] y_top    = y_bottom - level_c;         // dynamic top moves upward

  // Assert energy_o if the pixel is within the bar region
  assign energy_o = (x >= x0) && (x < x1) &&         // inside horizontal span
                    (y >= y_top) && (y < y_bottom);  // inside vertical span

 // Page 3: Once the slug's energy level, displayed on the left, reaches 0 the slug will drop.
 assign hovering_o = ~freeze & hovering & (level_c > 10'd0); // expose energy level to other modules
 
endmodule