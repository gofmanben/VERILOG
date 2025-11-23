`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/01/2025 10:56:43 PM
// Design Name: 
// Module Name: top_lab1
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


module top_lab1(
    input wire d2, d1, d0, btnD,
    output wire CA, CB, CC, CD, CE, CF, CG, DP, AN3, AN2, AN1, AN0
    );
    
    assign CA = (~d2 & ~d1 & d0) | (d2 & ~d1 & ~d0);
    assign CB = (d2 & ~d1 & d0) | (d2 & d1 & ~d0);
    assign CC = ~d2 & d1 & ~d0;
    assign CD = (~d2 & ~d1 & d0) | (d2 & ~d1 & ~d0) | (d2 & d1 & d0);
    assign CE = (~d2 & ~d1 & d0) | (~d2 & d1 & d0) | (d2 & ~d1 & ~d0) | (d2 & ~d1 & d0) | (d2 & d1 & d0);
    assign CF = (~d2 & ~d1 & d0) | (~d2 & d1 & ~d0) | (~d2 & d1 & d0) | (d2 & d1 & d0);
    assign CG = (~d2 & ~d1 & ~d0) | (~d2 & ~d1 & d0) | (d2 & d1 & d0);
    assign DP = btnD;
    // 1 = width (1 bit), b = binary, # = value (0 = on, 1 = off)
    assign AN3 = 1'b1;
    assign AN2 = 1'b1;
    assign AN1 = 1'b1;
    assign AN0 = 1'b0;

endmodule