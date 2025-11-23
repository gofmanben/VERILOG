`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/09/2025 06:53:35 PM
// Design Name: 
// Module Name: AddSub8
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

module AddSub8(
    input  [7:0] A_i,               // Input A (first operand) - always zero
    input  [7:0] B_i,               // Input B (second operand) - value from sw[7:0] (switches)
    input        sub_i,             // btnU button: 0 → A_i + B_i,  1 → A_i - B_i
    output [7:0] S_o,               // Output: sum (S_o) or difference depending on sub_i
    output       ovfl_o             // Output: signed overflow flag, indicates overflow during addition/subtraction
);
    wire [7:0] mux_out;             // Mux output: either B_i or ~B_i depending on sub_i (subtraction or addition)

    mux8bit mux(
        .A_i(B_i),          // Option #1: B_i (from switches)
        .B_i(~B_i),         // Option #2: ~B_i (negation of B_i, used for subtraction)
        .Sel(sub_i),        // Selection: 0 → use B_i (addition), 1 → use ~B_i (subtraction)
        .C(mux_out)         // Output: selected value (either B_i or ~B_i)
    );
    
    wire ovfl_out;          // Intermediate signal for adjusted overflow flag
    wire cout_out;          // Carry-out from the most significant bit (MSB) of the addition/subtraction operation
     
    // A - B = A +(~B + 1)
    // sub_i = 0: S = A + B + 0
    // sub_i = 1: S = A + ~B + 1 = A - B
    Add8 adder(
        .A_i(A_i),          // First operand A (always 0)
        .B_i(mux_out),      // Second operand: either B_i or ~B_i (negated B_i for subtraction)
        .cin_i(sub_i),      // Carry-in: 0 for addition, 1 for subtraction (A + ~B + 1)
        .S_o(S_o),          // Sum (or difference)
        .ovfl_o(ovfl_out),  // Overflow flag: set if signed overflow occurs
        .cout_o(cout_out)   // Carry-out flag (for unsigned overflow detection)
    );

    assign ovfl_o = ovfl_out ^ cout_out; // Assign the final overflow value to the output
 
endmodule