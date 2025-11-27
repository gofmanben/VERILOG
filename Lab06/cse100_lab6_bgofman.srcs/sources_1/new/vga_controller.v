`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/07/2025 07:01:42 PM
// Design Name: 
// Module Name: vga_controller
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

//
// vga_controller.v  -  VGA 640×480 @ 60 Hz Timing Generator
// ----------------------------------------------------------------------------
//  - Generates horizontal and vertical sync signals (Hsync, Vsync)
//  - Produces pixel coordinates (x, y)
//  - "active" region signal (1 when pixel is visible on screen)

// https://youtu.be/5exFKr-JJtg?t=262

// Page 3: for each of the screen's 640 x 480 pixels. The value of these 12 signals are sent one at a time for each pixel, 
// row by row from left to right and top to bottom using one cycle of the 25MHz clock (provided to you) for each pixel.
module vga_controller (
  input  wire      greset,      // Global reset from testbench: resets hcnt/vcnt and error counters
  input  wire        clk,       // Page 3: using one cycle of the 25MHz clock (provided to you) for each pixel
  // Page 3: This grid is traversed starting at the top left, location row 0, column 0. 
  output wire [9:0]  x,         // Current pixel X position (0-639 when active)
  output wire [9:0]  y,         // Current pixel Y position (0-479 when active)
  // Page 3: The Hsync and Vsync signals are used by the monitor to "synchronize" the start of each row and frame; they are low at fixed times between rows and frames.
  // Page 6: A new module is needed to generate the V/Hsync signals.
  output wire        Hsync,     // Horizontal sync pulse (active low)
  output wire        Vsync,     // Vertical sync pulse (active low)
  // Page 3: The region of dimension 640 x 480 at the top left is the Active Region: the pixels in this region corresponds to pixels on the screen.
  output wire        active,    // High only in visible area (640x480)
  output wire        frame_tick // 1-cycle pulse on Vsync rising edge (happens in blanking, not active)
);


  // ---------------- Horizontal timing (pixels per line) ----------------
  // Adjusted to match test_lab6_sync timing: 640 active, 15 front, 96 sync, 49 back (total 800) 
  wire [9:0] H_FRONT   = 10'd15;   // testbench: #(15*40); → front porch.
  wire [9:0] H_SYNC    = 10'd96;   // testbench: #(96*40); → sync
  wire [9:0] H_BACK    = 10'd49;   // testbench: #(49*40); → back porch

  // ---------------- Vertical timing (lines per frame) ------------------
  // Adjusted to match test_lab6_sync timing: 480 active, 9 front, 2 sync, 34 back (total 525)
  wire [9:0] V_FRONT   = 10'd9;    // testbench: #(9*800*40); → front porch
  wire [9:0] V_SYNC    = 10'd2;    // testbench: #(2*800*40); → sync
  wire [9:0] V_BACK    = 10'd34;   // testbench: #(34*800*40); → back porch
  
  // Page 3: One way to think of this is to imagine that you have an 800 x 525 grid of pixels as shown below
  // (instead of the 640 x 480 pixels which correspond to the area you see on the monitor).
  wire [9:0] H_TOTAL   = `H_RES + H_FRONT + H_SYNC + H_BACK; // 640 + 15 + 96 + 49 = 800
  wire [9:0] V_TOTAL   = `V_RES + V_FRONT + V_SYNC + V_BACK; // 480 + 9 + 2 + 34 = 525

  // Generate sync pulses (active low)  
  wire [9:0] H_SYNC_START = `H_RES + H_FRONT;  // Start of Hsync pulse (640 + 15 = 655)
  // Page 4: The horizontal synchronization signal (Hsync) should be low exactly for the 96 pixels in each row starting with the 656th pixel and high for the rest.
  wire [9:0] H_SYNC_END   = H_SYNC_START + H_SYNC; // End of Hsync pulse   (655 + 96 = 750)
  // Page 4: The vertical synchronization signal (Vsync) should be low exactly for all of the pixels in the 490th
  wire [9:0] V_SYNC_START = `V_RES + V_FRONT;          // Start of Vsync pulse (480 + 9 = 489)
  // Page 4: and 491st rows and high for all pixels in all other rows.
  wire [9:0] V_SYNC_END   = V_SYNC_START + V_SYNC; // End of Vsync pulse   (489 + 2 = 491)

  wire [9:0] STEP = 10'd1;   // +1 step
  wire [9:0] ZERO = 10'd0;   // reset value (column/row 0)
  
  // Horizontal and vertical pixel/line counters
  // Page 3: This grid is traversed starting at the top left, location row 0, column 0.
  wire [9:0] hcnt, hcnt_next, // 799 → needs ceil(log2(800)) = 10 bits
             vcnt, vcnt_next; // 524 → needs ceil(log2(525)) = 10 bits

  // End conditions (include blanking periods)
  // One frame = H_TOTAL (800 pixel clocks) * V_TOTAL (525 lines) = 420,000 pixel clocks (total timing)
  wire end_of_line  = (hcnt == H_TOTAL - 1); // last horizontal pixel (hcnt == 799)
  wire end_of_frame = (vcnt == V_TOTAL - 1); // last vertical line  (vcnt == 524)
  
  // Horizontal counter (0..799). Increments every pixel clock; wraps at end_of_line.
  // Page 3: Each row is traversed from left to right followed by the row immediately below it and so on.
  assign hcnt_next = end_of_line ? ZERO : (hcnt + STEP);
  // Page 2: use only positive edge-triggered flip-flops (FDRE)
  FDRE #(.INIT(1'b0)) _hcnt [9:0] (.C(clk), .R(greset), .CE(1'b1), .D(hcnt_next), .Q(hcnt));

  // Vertical counter (0..524). Increments once per line (when hcnt wraps); wraps at end_of_frame.
  assign vcnt_next = end_of_line && end_of_frame ? ZERO :          // If last pixel of last line → start new frame
                     end_of_line                 ? (vcnt + STEP) : // If line ended (but not frame) → next line
                                                    vcnt;          // Otherwise → hold during the line
  // Page 2: use only positive edge-triggered flip-flops (FDRE)
  FDRE #(.INIT(1'b0)) _vcnt [9:0] (.C(clk), .R(greset), .CE(1'b1), .D(vcnt_next), .Q(vcnt));
   
  // Page 3: The Hsync and Vsync signals are used by the monitor to synchronize the start of each row and frame; 
  // they are low at fixed times between rows and frames.
  assign Hsync = ~((hcnt_next > H_SYNC_START) && (hcnt_next <= H_SYNC_END));
  assign Vsync = ~((vcnt_next >= V_SYNC_START) && (vcnt_next < V_SYNC_END));
  
  // Active video region (visible image area): hcnt<640 and vcnt<480
  // Page 2: The region of dimension 640 × 480 at the top left is the Active Region: the pixels in this region correspond to pixels on the screen.
  assign active = (hcnt < `H_RES) && (vcnt < `V_RES); // 0..639, 0..479
    
  // Page 7: To move objects at one pixel per frame and count once per frame you will need a signal frame
  // that is high for one clock cycle once per frame. A simple way to generate this signal is to edge
  // detect the Vsync signal since it has a single low pulse in each frame. Another way is to make a
  // signal that is high at one specific pixel address. Which ever way you choose, it's important that
  // this signal not be high in the active region to avoid updating the position of an object while it is being displayed.
  wire Vprev;
  FDRE #(.INIT(1'b0)) _ff (.C(clk), .CE(1'b1), .R(greset), .D(Vsync), .Q(Vprev));
  
  // Page 7: 8. There is no qsec signal provided for this lab. Do not try to use the qsec clks module. Instead
  // the frame signal mentioned above, which is high for one cycle per frame, can be used as the up (or down) input of a counter.
  assign frame_tick = (~Vprev) & Vsync; // rising edge of Vsync

  // Page 4: So Hsync and Vsync are low in only the regions shaded pink and blue below, respectively.
  // The frame is continuously transmitted to the monitor to refresh the image. Transmitting one frame takes 
  // 800 x 525 x 40ns = 16,800,000ns = 16.8ms, so the monitor is being refreshed roughly 60 times per second: at 60Hz.
  assign x = hcnt;
  assign y = vcnt;
  
endmodule
