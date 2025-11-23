`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/12/2025 02:10:37 PM
// Design Name: 
// Module Name: ring_counter
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

// Ring Counter – Cycles control signals for digit selection on the 7-segment display.
module ring_counter(
    input clk_i,        // Page 4: a clock input, clk_i.
    input advance_i,    // Page 4: a control input, advance_i   // (See labCnt_clks output digsel) 
                        // If advance_i is high on the positive clock edge then all bits shift to the right.
    output [3:0] ring_o // One-hot output: 1000, 0100, 0010, 0001 rotating pattern
);

    // Page 1: use only positive edge-triggered flip-flops (FDRE)
    wire [3:0] next,     // next 4 bits (FDRE .D inputs)
               current;  // current 4 bits (flip-flop .Q outputs)
    
    // Page 4: If advance_i is high on the positive clock edge then all bits shift to the
    // right. The 0th bit will replace the top bit, shifting the bits in a ring.
    
    // Rotation pattern: 1000 → 0100 → 0010 → 0001 → 1000 (cycles)
    
    // Bit 0: when advancing, takes value from bit 1; when holding, keeps current value
    assign next[0] = (~advance_i & current[0]) | (advance_i & current[1]);
    // Bit 1: when advancing, takes value from bit 2; when holding, keeps current value  
    assign next[1] = (~advance_i & current[1]) | (advance_i & current[2]);
    // Bit 2: when advancing, takes value from bit 3; when holding, keeps current value
    assign next[2] = (~advance_i & current[2]) | (advance_i & current[3]);
    // Bit 3: when advancing, takes value from bit 0 (wraps around); when holding, keeps current value
    assign next[3] = (~advance_i & current[3]) | (advance_i & current[0]);
    /*
        Equivalent, more compact form:
        assign next = advance_i ? {current[0], current[3:1]} : current;
    */
    
    
    // Page 1: Using the FDRE module that is part of the "built-in" Unisim library.
    // F = Flip-flop | D = D-type | R = synchronous Reset input | E = clock Enable
    
    // .INIT(1'b0): sets initial Q=0 **once at FPGA configuration time** (power-up). 
    // .C(clk_i): main clock input - defines *when* the flip-flop samples D (on rising edge)
    // .R(1'b0): synchronous reset (inactive here) - can force Q to 0 regardless of D
    // .CE(1'b1): clock enable (always ON) - allows capturing new data every clock cycle
    // .D(next[0]): next-state value for bit 0, computed by combinational logic
    // .Q(current[0]): current state (output) of bit 0, updated on the next rising clock edge
    
    // Page 4: You will need to make sure that one of the FFs has a 1 on reset.
    FDRE #(.INIT(1'b1)) // Create an FDRE flip-flop #1 (LSB)
        _rff0 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(next[0]), .Q(current[0]));
    
    // Flip-flop for bit 1: initialized to 0
    // Will become 1 when ring rotates from 1000 to 0100
    FDRE #(.INIT(1'b0)) // Create an FDRE flip-flop #2
        _rff1 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(next[1]), .Q(current[1]));
    
    // Flip-flop for bit 2: initialized to 0  
    // Will become 1 when ring rotates from 0100 to 0010
    FDRE #(.INIT(1'b0)) // Create an FDRE flip-flop #3
        _rff2 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(next[2]), .Q(current[2]));
    
    // Flip-flop for bit 3: initialized to 0
    // Will become 1 when ring rotates from 0010 to 0001, then back to 1000
    FDRE #(.INIT(1'b0))  // Create an FDRE flip-flop #4 (MSB)
        _rff3 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(next[3]), .Q(current[3]));
    
    assign ring_o = current;

endmodule