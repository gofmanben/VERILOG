`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 09:13:52 PM
// Design Name: 
// Module Name: decoder
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
Page 6: Decoder
*/
module decoder(
    input  [3:0]  in_i,    // Page 6: An n-bit decoder has n inputs ... 
    output [15:0] out_o    // Page 6: ... and 2n outputs.  (correct_sw)
);

    // Break out each input bit into a separate wire for readability and clarity.
    // This lets us write the logic equations more clearly (e.g., a0, a1, a2, a3 instead of in_i[3:0]).
    wire a0 = in_i[0];
    wire a1 = in_i[1];
    wire a2 = in_i[2];
    wire a3 = in_i[3];
    
    // Create the inverted versions (na0 = NOT a0, etc.)
    // These are used to build the AND terms for each output of the decoder.
    // Example: out_o[0] = ~a3 & ~a2 & ~a1 & ~a0 corresponds to input 0000.
    wire na0 = ~a0;
    wire na1 = ~a1;
    wire na2 = ~a2;
    wire na3 = ~a3;

    // One AND term per output bit.
    // Example: out_o[0] = ~a3 & ~a2 & ~a1 & ~a0 (0000)
    //          out_o[13] = a3 &  a2 & ~a1 &  a0 (1101 = 13)

    // Page 6: Specifically, the ith output is high when the input represents the value i in binary.
    // For clarity: when in_i = binary(i), out_o = one-hot pattern with bit i = 1.
    assign out_o[0]  = na3 & na2 & na1 & na0; // in=0000 (0)  -> out=0000_0000_0000_0001
    assign out_o[1]  = na3 & na2 & na1 &  a0; // in=0001 (1)  -> out=0000_0000_0000_0010
    assign out_o[2]  = na3 & na2 &  a1 & na0; // in=0010 (2)  -> out=0000_0000_0000_0100
    assign out_o[3]  = na3 & na2 &  a1 &  a0; // in=0011 (3)  -> out=0000_0000_0000_1000
    assign out_o[4]  = na3 &  a2 & na1 & na0; // in=0100 (4)  -> out=0000_0000_0001_0000
    assign out_o[5]  = na3 &  a2 & na1 &  a0; // in=0101 (5)  -> out=0000_0000_0010_0000
    assign out_o[6]  = na3 &  a2 &  a1 & na0; // in=0110 (6)  -> out=0000_0000_0100_0000
    assign out_o[7]  = na3 &  a2 &  a1 &  a0; // in=0111 (7)  -> out=0000_0000_1000_0000
    assign out_o[8]  =  a3 & na2 & na1 & na0; // in=1000 (8)  -> out=0000_0001_0000_0000
    assign out_o[9]  =  a3 & na2 & na1 &  a0; // in=1001 (9)  -> out=0000_0010_0000_0000
    assign out_o[10] =  a3 & na2 &  a1 & na0; // in=1010 (10) -> out=0000_0100_0000_0000
    assign out_o[11] =  a3 & na2 &  a1 &  a0; // in=1011 (11) -> out=0000_1000_0000_0000
    assign out_o[12] =  a3 &  a2 & na1 & na0; // in=1100 (12) -> out=0001_0000_0000_0000
    assign out_o[13] =  a3 &  a2 & na1 &  a0; // in=1101 (13) -> out=0010_0000_0000_0000
    assign out_o[14] =  a3 &  a2 &  a1 & na0; // in=1110 (14) -> out=0100_0000_0000_0000
    assign out_o[15] =  a3 &  a2 &  a1 &  a0; // in=1111 (15) -> out=1000_0000_0000_0000

endmodule