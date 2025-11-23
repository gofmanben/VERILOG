`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/12/2025 02:10:37 PM
// Design Name: 
// Module Name: edge_detector
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

// Edge Detector – Generates single-cycle pulses on button presses.
module edge_detector(
    input clk_i,        // Page 5: Connect the clk inputs of the Edge Detector and Counters to a net named clkin.
    input button_o,     // Page 4: Pushbuttons btnU and btnD will be connected to the input of an Edge Detector.
                        // btnU or btnD or btnL
    output edge_o       // Single clock cycle pulse on rising edge of button
);

    // Two-stage synchronizer: reduces metastability risk and aligns to clk_i domain.
    wire cur_state, prv_state;
    
    // Page 1: Using the FDRE module that is part of the "built-in" Unisim library.
    // F = Flip-flop | D = D-type | R = synchronous Reset input | E = clock Enable
    
    // .INIT(1'b0): sets initial Q=0 **once at FPGA configuration time** (power-up). 
    // .C(clk_i): main clock input - defines *when* the flip-flop samples D (on rising edge)
    // .R(1'b0): synchronous reset (inactive here) - can force Q to 0 regardless of D
    // .CE(1'b1): clock enable (always ON) - allows capturing new data every clock cycle
    // .D(button_o): input button signal (asynchronous) to be synchronized
    // .Q(cur_state): synchronized output, updated on the next rising clock edge
    FDRE #(.INIT(1'b0)) // Create an FDRE flip-flop #1 (first synchronizer stage)
        _eff0 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(button_o), .Q(cur_state));

    // ---------- Flip-Flop Stage 2 ----------
    // Captures cur_state one clock later to provide a "previous state" version.
    FDRE #(.INIT(1'b0)) // Create an FDRE flip-flop #2 (second synchronizer stage)
        _eff1 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(cur_state), .Q(prv_state));
    
    // Page 4: generate a high value for one clock cycle if the past two inputs consist of a 0 followed by a 1.
    assign edge_o = cur_state & ~prv_state; // Rising-edge detect: current=1 & previous=0 → 1-clock pulse

endmodule