`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2025 05:54:38 PM
// Design Name: 
// Module Name: countUD16L
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

// 16-bit Counter – Built by cascading four countUD4L modules.
module countUD16L(
    input         clk_i,    // Page 3: The system input clock
    input         up_i,     // Page 3: Increment input port         (btnU)
    input         dw_i,     // Page 3: Decrement input port         (btnD)
    input         ld_i,     // Page 3: Load control input port (Load enable when 1, load Din_i on the next clock edge)      (btnL)
    input  [15:0] Din_i,    // Data input port (16-bit), that will be loaded into the counter on the positive clock edge if ld_i is high (sw[15:0])
    output [15:0] Q_o,      // Page 3: Your 16-bit counter will have the same ports as the 4-bit counters except that its input and port ports will be 16-bit vectors.
    output        utc_o,    // Page 3: the signal (Up Terminal Count) which is 1 only when the counter is at 16'hFFFF
    output        dtc_o     // Page 3: the signal (Down Terminal Count) which is 1 only when the counter is at 16'h0000
);

    // Terminal count signals from each 4-bit sub-counter:
    // - up_utc[n] = 1 when nibble n is at maximum (4'b1111) and counting up
    // - dw_utc[n] = 1 when nibble n is at minimum (4'b0000) and counting down
    wire [3:0] up_utc, dw_utc;  // Updates from Flip-Flop

    // ---------- Ripple Carry Logic ----------
    // Page 3: 4-bit counter to make a 16-bit counter as in the overview figure.

    // Carry logic (counting up): Each higher nibble increments only when all lower nibbles reach 0xF and roll over.
    wire up0 = up_i;                                      // btnU increments LSB nibble: 0x0000 → 0x000F  (from 0 → 15)
    wire up1 = up_i & up_utc[0];                          // increments [7:4]   from 0x0010 → 0x00FF once [3:0] rolls over (from 16 → 255)
    wire up2 = up_i & up_utc[0] & up_utc[1];              // increments [11:8]  from 0x0100 → 0x0FFF once lower 8 bits roll over (from 256 → 4095)
    wire up3 = up_i & up_utc[0] & up_utc[1] & up_utc[2];  // increments [15:12] from 0x1000 → 0xFFFF once lower 12 bits roll over (from 4096 → 65535)


    // Borrow logic (counting down): Each higher nibble decrements only when all lower nibbles reach 0x0 and borrow (wrap) from 0xF.
    wire dw0 = dw_i;                                      // btnD decrements LSB nibble: 0x000F → 0x0000  (from 15 → 0)
    wire dw1 = dw_i & dw_utc[0];                          // decrements [7:4]   from 0x00FF → 0x0010 once [3:0] underflows (from 255 → 16)
    wire dw2 = dw_i & dw_utc[0] & dw_utc[1];              // decrements [11:8]  from 0x0FFF → 0x0100 once lower 8 bits underflow (from 4095 → 256)
    wire dw3 = dw_i & dw_utc[0] & dw_utc[1] & dw_utc[2];  // decrements [15:12] from 0xFFFF → 0x1000 once lower 12 bits underflow (from 65535 → 4096)

    // Page 3: To build your 16-bit counter, use a few additional gates to connect four instances of your 
    // 4-bit counter to make a 16-bit counter as in the overview figure.

    // Instance #1 – LSB 4 bits [3:0]
    // utc_o: asserted when Q_o[3:0] == 4'b1111 (carry out to next nibble)
    // dtc_o: asserted when Q_o[3:0] == 4'b0000 (borrow out to next nibble)
    countUD4L _16ff0 (.clk_i(clk_i),
        .up_i(up0), .dw_i(dw0), .ld_i(ld_i),          // Trigger on each button press
        .Din_i(Din_i[3:0]), .Q_o(Q_o[3:0]),           // Update Q_o[3:0] from Din_i (btnL)
        .utc_o(up_utc[0]), .dtc_o(dw_utc[0])          // Get utc_o and dtc_o for bit 0 (btnU or btnD)
    );

    // Instance #2 – bits [7:4]
    // utc_o: asserted when Q_o[7:4] == 4'b1111
    // dtc_o: asserted when Q_o[7:4] == 4'b0000
    countUD4L _16ff1 (.clk_i(clk_i),
        .up_i(up1), .dw_i(dw1), .ld_i(ld_i),          // Trigger on button press when LSB nibble rolls over
        .Din_i(Din_i[7:4]), .Q_o(Q_o[7:4]),           // Update Q_o[7:4] from Din_i (btnL)
        .utc_o(up_utc[1]), .dtc_o(dw_utc[1])          // Get utc_o and dtc_o for bit 1 (btnU or btnD)
    );

    // Instance #3 – bits [11:8]
    // utc_o: asserted when Q_o[11:8] == 4'b1111
    // dtc_o: asserted when Q_o[11:8] == 4'b0000
    countUD4L _16ff2 (.clk_i(clk_i),
        .up_i(up2), .dw_i(dw2), .ld_i(ld_i),          // Trigger on button press when two nibbles roll over
        .Din_i(Din_i[11:8]), .Q_o(Q_o[11:8]),         // Update Q_o[11:8] from Din_i (btnL)
        .utc_o(up_utc[2]), .dtc_o(dw_utc[2])          // Get utc_o and dtc_o for bit 2 (btnU or btnD)
    );

    // Instance #4 – MSB 4 bits [15:12]
    // utc_o: asserted when Q_o[15:12] == 4'b1111
    // dtc_o: asserted when Q_o[15:12] == 4'b0000
    countUD4L _16ff3 (.clk_i(clk_i),
        .up_i(up3), .dw_i(dw3), .ld_i(ld_i),          // Trigger on button press when three nibbles roll over
        .Din_i(Din_i[15:12]), .Q_o(Q_o[15:12]),       // Update Q_o[15:12] from Din_i (btnL)
        .utc_o(up_utc[3]), .dtc_o(dw_utc[3])          // Get utc_o and dtc_o for bit 3 (btnU or btnD)
    );


    // ---------- Output Assignment ----------
    assign utc_o =  &up_utc; // Page 3: Its utc_o output should be 1 when your 16-bit counter is at hex 0xFFFF
                             // &up_utc - up_utc[0] & up_utc[1] & up_utc[2] & up_utc[3];
    assign dtc_o =  &dw_utc; // Page 3: and its dtc_o output should be 1 when your 16-bit counter is at 0x0000.
                             // &dw_utc - dw_utc[0] & dw_utc[1] & dw_utc[2] & dw_utc[3];

endmodule
