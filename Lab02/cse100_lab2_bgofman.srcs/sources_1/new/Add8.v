`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/09/2025 06:53:35 PM
// Design Name: 
// Module Name: Add8
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

module Add8(
    input [7:0] A_i,      // 8-bit operand A - usually zero (for addition/subtraction)
    input [7:0] B_i,      // 8-bit operand B - either sw[7:0] or ~sw[7:0] depending on the operation
    input cin_i,          // Initial carry-in to the least significant bit (LSB): 0 for addition, 1 for A + (~B) + 1 in subtraction
    output [7:0] S_o,     // 8-bit sum/result (S_o[0] = LSB ... S_o[7] = MSB)
    output ovfl_o,        // Signed overflow flag: set if the result overflows beyond the representable range for signed numbers
    output cout_o         // Carry-out flag: the carry-out from the MSB, indicates overflow for unsigned operations
);
    wire [5:0] C_o;       // Intermediate carries between bit positions: C[0] → bit1, C[1] → bit2, ..., C[5] → bit6

// Example: A = 1110_1101 (0xED = 237),   B = 1010_0111 (0xA7 = 167)
// Perform bit-by-bit addition, starting from the least significant bit (LSB) at A[0], B[0] to the most significant bit (MSB) at A[7], B[7].

// 1. LSB (A[0], B[0], and cin): A[0]=1, B[0]=1, cin=0 (no carry-in from previous bit)
//    → Result: S_o[0] = 0, Carry-out (C_o[0]) = 1 (this is the carry into the next bit)
fa fa0(.A_i(A_i[0]), .b(B_i[0]), .cin_i(cin_i), .s(S_o[0]), .cout_o(C_o[0]));

// 2. LSB (A[1], B[1], and carry C_o[0]): A[1]=0, B[1]=1, C_o[0]=1
//    → Result: S_o[1] = 0, Carry-out (C_o[1]) = 1 (this carry moves to the next bit)
fa fa1(.A_i(A_i[1]), .b(B_i[1]), .cin_i(C_o[0]), .s(S_o[1]), .cout_o(C_o[1]));

// 3. LSB (A[2], B[2], and carry C_o[1]): A[2]=1, B[2]=1, C_o[1]=1
//    → Result: S_o[2] = 1, Carry-out (C_o[2]) = 1 (this carry propagates to the next bit)
fa fa2(.A_i(A_i[2]), .b(B_i[2]), .cin_i(C_o[1]), .s(S_o[2]), .cout_o(C_o[2]));

// 4. LSB (A[3], B[3], and carry C_o[2]): A[3]=1, B[3]=0, C_o[2]=1
//    → Result: S_o[3] = 0, Carry-out (C_o[3]) = 1 (carry into the next bit)
fa fa3(.A_i(A_i[3]), .b(B_i[3]), .cin_i(C_o[2]), .s(S_o[3]), .cout_o(C_o[3]));

// 5. LSB (A[4], B[4], and carry C_o[3]): A[4]=0, B[4]=0, C_o[3]=1
//    → Result: S_o[4] = 1, Carry-out (C_o[4]) = 0 (no carry to the next bit)
fa fa4(.A_i(A_i[4]), .b(B_i[4]), .cin_i(C_o[3]), .s(S_o[4]), .cout_o(C_o[4]));

// 6. LSB (A[5], B[5], and carry C_o[4]): A[5]=1, B[5]=1, C_o[4]=0
//    → Result: S_o[5] = 0, Carry-out (C_o[5]) = 1 (carry into the next bit)
fa fa5(.A_i(A_i[5]), .b(B_i[5]), .cin_i(C_o[4]), .s(S_o[5]), .cout_o(C_o[5]));

// 7. LSB (A[6], B[6], and carry C_o[5]): A[6]=1, B[6]=0, C_o[5]=1
//    → Result: S_o[6] = 0, Carry-out (ovfl_o) = 1 (overflow flag set due to carry in this bit position)
//    The **overflow flag** (ovfl_o) is set when the signed result exceeds the representable range for 8 bits.
fa fa6(.A_i(A_i[6]), .b(B_i[6]), .cin_i(C_o[5]), .s(S_o[6]), .cout_o(ovfl_o));

// 8. MSB (A[7], B[7], and carry C_o[6]): A[7]=1, B[7]=1, C_o[6]=1
//    → Result: S_o[7] = 1, Carry-out (cout_o) = 1
//    The **carry-out** (cout_o) is the final carry signal that indicates an unsigned overflow, i.e., if the result does not fit within the 8-bit range.
fa fa7(.A_i(A_i[7]), .b(B_i[7]), .cin_i(ovfl_o), .s(S_o[7]), .cout_o(cout_o));

//cout s[7] s[6] s[5] s[4] s[3] s[2] s[1] s[0]
//  1    1    0    0    1    0    1    0    0 → 1_1001_0100₂ = 0x1BC = 404₁₀

endmodule