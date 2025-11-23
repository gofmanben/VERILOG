`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/23/2025 10:10:37 PM
// Design Name:
// Module Name: time_counter
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
Page 5: Time Counter
*/
module time_counter(
    input        clk_i,     // Page 2: connect only the system clock as input to the clock pins of any sequential components
    input        inc_i,     // Page 5: count down to 0 (or vice versa).
                            // count up enable (1 = increment on this clock edge)
    input        dec_i,     // not used in our design, but provided for completeness
    input        reset_i,   // Page 5: This will be your method of reseting the counter.
                            // synchronous load signal (1 = load din on this clock edge).
    input  [5:0] din,       // Page 5: load a 6-bit binary value
    output [5:0] q_o        // Page 5: You can actually use your 16-bit counter and leave the top bits unconnected.
);


    // Page 5: You can actually use your 16-bit counter and leave the top bits unconnected.
    wire [15:0] Din16;                // By forcing the upper bits to 0 and never reading them, synthesis will prune them
    assign Din16[5:0]   = din;        // Page 5: You will need a loadable counter that can load a 6-bit binary value and count down to 0 (or vice versa)
    assign Din16[15:6]  = 10'b0;      // Page 5: leave the top bits unconnected. (high bits unused)

    // Full 16-bit count output from countUD16L
    wire [15:0] Q16;
    
    // Page 5: Since you have completed Lab 3 you should have one handy. You can actually use your 16-bit counter and leave the top bits unconnected. 
    // The tools will remove any logic that is not useful and that will turn your 16-bit counter into a smaller counter.
    // In case it wasn't obvious enough you should directly reuse your UD16L counter from Lab 3.
    countUD16L _counter16 (
        .clk_i (clk_i),             // same system clock
        .up_i  (inc_i & ~reset_i),  // increment when enabled and not loading
        .dw_i  (dec_i & ~reset_i),  // decrement when enabled and not loading
                                    // However in Lab 4 dec_i = 0 (counting up only).
        .ld_i  (reset_i),           // Page 5: This will be your method of reseting the counter.
                                    // when 1, synchronously load Din16 on this clock
        .Din_i (Din16),             // 16-bit load value (we only care about low 6 bits)
        .Q_o   (Q16),               // 16-bit counter state
        .utc_o (),                  // not used in Lab 4
        .dtc_o ()                   // not used in Lab 4
    );

   // Page 5: You can actually use your 16-bit counter and leave the top bits unconnected.
    assign q_o = Q16[5:0];  // Expose only the lower 6 bits as q_o

endmodule
