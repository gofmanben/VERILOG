`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/09/2025 06:53:35 PM
// Design Name: 
// Module Name: fa
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

module fa(          // Full Adder module that computes the sum of three inputs: A, B, and carry-in (cin)
    input A_i,      // Input bit A - 1st operand (single bit)
    input b,        // Input bit B - 2nd operand (single bit)
    input cin_i,    // Input carry-in from the previous bit (0 for the least significant bit or as passed along in subsequent bits)
    output s,       // Output sum bit (the result of adding A, B, and carry-in for this bit)
    output cout_o   // Output carry-out (indicates whether there was a carry to the next bit)
);

    // Sum bit (s): The sum for this bit is calculated using XOR (exclusive OR) logic.
    // It adds A_i, b, and cin_i, where the XOR operation effectively computes the sum modulo 2.
    // The sum bit is 1 if an odd number of the inputs are 1, and 0 if an even number of inputs are 1.
    assign s = A_i ^ b ^ cin_i;  // XOR the three inputs to calculate the sum for the current bit.

    // Carry-out (cout_o): The carry-out is set when any two or more of the inputs are 1.
    // This is because, in binary addition, if two bits are 1, the result is 10, so a carry of 1 is generated.
    // The formula for carry-out (cout_o) is derived from the sum-of-products form:
    //   - Carry is generated if A_i and b are both 1
    //   - Carry is generated if A_i and cin_i are both 1
    //   - Carry is generated if b and cin_i are both 1
    assign cout_o = (A_i & b) | (A_i & cin_i) | (b & cin_i); // Carry-out is true if any two of the three inputs are 1.

endmodule

