`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/01/2025 08:08:31 AM
// Design Name: 
// Module Name: sensor
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


// Page 5: Since the pushbuttons are asynchronous inputs you will want to synchronize them before connecting them to you state machine.

module sensor (
  input  wire clk_i,   // Page 6: System clock used for synchronization
  input  wire in_i,    // Raw pushbutton input (active-low): 0 = pressed/blocked, 1 = released/unblocked
  output wire out_o    // Synchronized, active-high output: 1 = unblocked, 0 = blocked
);

  wire current; // intermediate signal between first and second synchronizer stages

  // First stage of synchronizer
  // Samples the asynchronous button input on the rising edge of clk_i.
  // INIT=1'b1 ensures output defaults HIGH (matching unblocked sensor state).
  FDRE #(.INIT(1'b1)) _s1 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(in_i), .Q(current));

  // Second stage of synchronizer
  // Captures signal to further reduce metastability risk.
  // Also initialized HIGH so that idle sensors read as unblocked after reset.
  FDRE #(.INIT(1'b1)) _s2 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(current), .Q(out_o));

endmodule