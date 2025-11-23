`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/09/2025 06:53:35 PM
// Design Name: 
// Module Name: SignChanger
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

module SignChanger(
    input [7:0] A_i,               // Input: 8-bit number, which we will either leave unchanged or invert (sw[7:0])
    input sign_i,                  // Input: "sign change" flag from btnU. 0 → keep A_i as is, 1 → output -A_i
    output [7:0] D_i,              // Output: result of the operation (either A_i or -A_i)
    output ovfl_o                  // Output: overflow flag, if the result does not fit into 8 bits
);

    AddSub8 addsub(
        .A_i(8'b0),                // Assign the value 0 to this signal (all 8 bits are zero)
        .B_i(A_i),                 // Connect our original number - this is sw[7:0]
        .sub_i(sign_i),            // Operation select signal: 0 → addition (0 + A_i), 1 → subtraction (0 - A_i) - driven by btnU
        .S_o(D_i),                 // Output of the sum/difference connected to D_i (our result)
        .ovfl_o(ovfl_o)            // Overflow signal from AddSub8 propagated to the module output
    );

endmodule