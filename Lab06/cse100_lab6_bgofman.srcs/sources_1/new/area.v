`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/08/2025 11:29:34 AM
// Design Name: 
// Module Name: area
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

// Page 4: 1. The playing area is the 640 x 480 screen.
module area(
    input  wire [9:0] x,       // current pixel column (0..799)
    input  wire [9:0] y,       // current pixel row    (0..524)
    output wire border_o       // 1 when current pixel is within border area
);

  // Assert border_o if the pixel is within the border region
  assign border_o = (x < `BORDER) || (x >= (`H_RES - `BORDER)) || // inside horizontal span
                    (y < `BORDER) || (y >= (`V_RES - `BORDER));   // inside vertical span

endmodule