`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/09/2025 06:53:35 PM
// Design Name: 
// Module Name: mux8bit
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

module mux8bit(
    input [7:0] A_i,     // Input A: First 8-bit signal (option #1)
    input [7:0] B_i,     // Input B: Second 8-bit signal (option #2)
    input Sel,           // Selector: Determines which input is passed to the output
                         // When Sel = 0, output is A_i.
                         // When Sel = 1, output is B_i.
    output [7:0] C       // Output: The selected 8-bit signal (either A_i or B_i)
);

  // The output C is selected based on the value of Sel:
  // - If Sel = 0, output is A_i.
  // - If Sel = 1, output is B_i.
  assign C = Sel ? B_i : A_i;  // If Sel = 1, select B_i; otherwise, select A_i.

endmodule