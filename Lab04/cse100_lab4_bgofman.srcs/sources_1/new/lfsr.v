`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/23/2025 10:10:37 PM
// Design Name:
// Module Name: lfsr
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

/* 
Page 4: Random Number Generator
You will use a Linear Feedback Shift Register (LFSR) to generate a random 8-bit binary number.
Below is an 8-bit linear feedback shift register.
*/
module lfsr(
    input clk_i,
    output [7:0] q_o
);
    /* Page 5: This sequence is not random, but reading the LFSR at random times (assuming it cycles through
    enough states fast enough) will give you a random 8-bit number in the same way a roulette wheel
    provides a random outcome. The choice of inputs into the XOR gate is not arbitrary so be sure to use the correct inputs.
    */
    wire [7:0] d;
    
    // Page 4: You will use a Linear Feedback Shift Register (LFSR) to generate a random 8-bit binary number.
    wire feedback;
    
    // Page 5: The choice of inputs into the XOR gate is not arbitrary so be sure to use the correct inputs.
    assign feedback = q_o[7] ^ q_o[5] ^ q_o[4] ^ q_o[3]; // Feedback polynomial: x^8 + x^6 + x^5 + x^4 + 1
    
    // The choice of inputs into the XOR gate is not arbitrary so be sure to use the correct inputs.
    // Shift right and insert feedback at bit 0
    // Page 5: This LFSR is simply an 8-bit shift register where the input to the first register is the XOR of specific
    // bits in the register. If all the bits in the register are 0 then the LFSR output will always be 0's.
    assign d[7] = q_o[6];
    assign d[6] = q_o[5];
    assign d[5] = q_o[4];
    assign d[4] = q_o[3];
    assign d[3] = q_o[2];
    assign d[2] = q_o[1];
    assign d[1] = q_o[0];
    assign d[0] = feedback;
    
    // Page 2: use only positive edge-triggered flip-flops (FDRE)
    // Page 8: your LFSR should start with the contents 8’b10000000 when the global reset (btnR) is asserted

    // F = Flip-flop | D = D-type | R = synchronous Reset input | E = clock Enable
    
    // .INIT(1'b1): Page 8: LFSR should start with the contents 8'b10000000
    // .C(clk_i): main clock input - defines *when* the flip-flop samples D (on rising edge)
    // .R(1'b0): synchronous reset (inactive here) - can force Q to 0 regardless of D
    // .CE(1'b1): clock enable (always ON) - allows capturing new data every clock cycle
    // .D(next[0]): next-state value for bit 0, computed by combinational logic
    // .Q(current[0]): current state (output) of bit 0, updated on the next rising clock edge
    FDRE #(.INIT(1'b1)) _ff7 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(d[7]), .Q(q_o[7]));
    FDRE #(.INIT(1'b0)) _ff6 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(d[6]), .Q(q_o[6]));
    FDRE #(.INIT(1'b0)) _ff5 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(d[5]), .Q(q_o[5]));
    FDRE #(.INIT(1'b0)) _ff4 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(d[4]), .Q(q_o[4]));
    FDRE #(.INIT(1'b0)) _ff3 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(d[3]), .Q(q_o[3]));
    FDRE #(.INIT(1'b0)) _ff2 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(d[2]), .Q(q_o[2]));
    FDRE #(.INIT(1'b0)) _ff1 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(d[1]), .Q(q_o[1]));
    FDRE #(.INIT(1'b0)) _ff0 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(d[0]), .Q(q_o[0]));
    
endmodule