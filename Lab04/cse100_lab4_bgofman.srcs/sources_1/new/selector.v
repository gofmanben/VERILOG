`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/12/2025 02:10:37 PM
// Design Name: 
// Module Name: selector
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

// Selector – Chooses one of four 4-bit segments from a 16-bit bus for display. (hex7seg)
module selector(
    input  [3:0]  Sel_i,   // Lab03. Page 3: a 4-bit control input, Sel i[3:0].
                           // One-hot output: 1000, 0100, 0010, 0001 rotating pattern (See ring_counter output)
    input  [15:0] N_i,     // Lab03. Page 3: has a 16-bit bus, N i[15:0],  (See countUD16L output Q_o)
    output [3:0]  H_o      // Lab03. Page3: Its output is a 4-bit bus, H o[3:0] which is a 4-bit range of the N i[15:0] bus.
);
    // Lab03. Page 4: Multiplexer logic for digit selection
    // H_o is N_i[15:12] when Sel_i=(1000)
    // H_o is N_i[11:8] when Sel_i=(0100)
    // H_o is N_i[7:4] when Sel_i=(0010)
    // H_o is N_i[3:0] when Sel_i=(0001)
    assign H_o =
        ({4{Sel_i[3]}} & N_i[15:12]) |  // Select bits 15-12 when Sel_i[3]=1
        ({4{Sel_i[2]}} & N_i[11:8 ]) |  // Select bits 11-8 when Sel_i[2]=1
        ({4{Sel_i[1]}} & N_i[7:4  ]) |  // Select bits 7-4 when Sel_i[1]=1
        ({4{Sel_i[0]}} & N_i[3:0  ]);   // Select bits 3-0 when Sel_i[0]=1
        
   /* Equivalent:
    assign H_o = Sel_i[3] ? N_i[15:12] :    // Select bits 15-12 when Sel_i[3]=1
                 Sel_i[2] ? N_i[11:8]  :    // Select bits 11-8 when Sel_i[2]=1
                 Sel_i[1] ? N_i[7:4]   :    // Select bits 7-4 when Sel_i[1]=1
                 Sel_i[0] ? N_i[3:0]   :    // Select bits 3-0 when Sel_i[0]=1
                            4'b0000;        // Default value
   */

endmodule