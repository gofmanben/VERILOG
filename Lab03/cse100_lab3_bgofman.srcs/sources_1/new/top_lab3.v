`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/12/2025 02:10:37 PM
// Design Name:
// Module Name: top_lab3
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

// Top Module – Integrates all components and connects them to FPGA I/O.

// Page 5: 1. Design your top level such that it has the following inputs:
module top_lab3(
    input clkin,        // Page 5: this is the 100MHz clock on the BASYS3 Board
    input btnR,         // Page 5: this button will be connected the built-in global reset of the Artix 7 FPGA
    input btnU,         // Page 5: when pressed this button causes the counter to increment by just one
    input btnD,         // Page 5: when pressed this button causes the counter to decrement by just one
    input btnC,         // Page 5: when pressed this button causes the counter to advance continuously except in the FFFC to FFFF range
    input btnL,         // Page 5: when pressed this button causes the counter to load the value determined by the switches on the clock edge
    input [15:0] sw,    // Page 5: this 16 bit vector determines the value loaded into the counter when btnL is pressed
    
    // Page 5: and the following outputs:
    output [15:0] led,  // Page 5: led[15] - this is the leftmost LED below the switches and should display UTC
                        // Page 5: led[0] - this is the rightmost LED below the switches and should display DTC.
                        // Page 5: led[14:1] to 0 so that they will be connected to 0, and not display a random value.
    output [3:0] an,    // Page 5: this 4 bit vector controls the 4 digits of 7-segment display
    output [6:0] seg,   // Page 5: this 7 bit vector controls the segments in the 7-segment display
    output dp           // Page 5: this controls the dp segments in the 7-segment display
);

    // Clock signals for the design
    wire clk;           // Page 1: connect only the system clock as input to the clock pins of any sequential components
    wire digsel;        // Page 1: not connect the system clock as the input to any other logic (digsel is not a clock)
                        // Page 6: The signal digsel should be used to advance the Ring Counter; it should not be used as a clock!!!

    // Page 5: 6. Add an instance of the module labCnt clks to your top level
    labCnt_clks slowit (
        .clkin (clkin),   // Page 6: The signal clkin is your system clock.
        .greset(btnR),    // Page 6: Pushbutton btnR should be connected only to the greset input
        .clk   (clk),     // Page 1: connect only the system clock as input to the clock pins of any sequential components
        .digsel(digsel),  // Page 6: The signal digsel should be used to advance the Ring Counter; it should not be used as a clock!!!
        .fastclk()        // [Synth 8-7071] port 'fastclk' of module 'labCnt_clks' is unconnected for instance 'slowit' [top_lab3.v:49]
                          // [Synth 8-7023] instance 'slowit' of module 'labCnt_clks' has 5 connections declared, but only 4 given [top_lab3.v:49]
    );

    // Page 6: The signal clkin is your system clock. The signal digsel should be used to advance the Ring Counter; it should not be used as a clock!!!
`ifdef SYNTHESIS // for the testbench testTC.v
    wire clk_i = clk;     // Page 5: Connect the clk inputs of the Edge Detector and Counters to a net named clkin. 
                          // This is the system clock for the design. It is the only signal which can be used as a clock in your design.
`else
    wire clk_i = clkin;   // Page 1: not connect the system clock as the input to any other logic.
                          // simulation: raw 100 MHz (matches TB timing for Edge Detector, Counters, and Ring Counter)
`endif

    /*
    2. In your top level, add and connect the modules for your Edge Detector, Ring Counter,
    16-bit Counter, Selector and hex7seg.
    */
    
    // Page 4: Pushbuttons btnU and btnD will be connected to the input of an Edge Detector. An Edge Detector
    // will generate a high value for one clock cycle if the past two inputs consist of a 0 followed by a 1.
    // Page 4: Edge detector generates a one-clock-cycle pulse on a 0→1 transition.
    // Page 5: In your top level, add and connect the modules for your Edge Detector
    wire up_edge, down_edge;
    
    edge_detector edge_up   (
        .clk_i(clk_i),     // Page 5: 3. Connect the clk inputs of the Edge Detector and Counters to a net named clkin.
        .button_o(btnU),   // Page 2: increment each time pushbutton btnU is pressed
        .edge_o(up_edge)   // Page 4: Edge Detector will generate a high value for one clock cycle
    );
    
    edge_detector edge_down (
        .clk_i(clk_i),     // Page 5: 3. Connect the clk inputs of the Edge Detector and Counters to a net named clkin.
        .button_o(btnD),   // Page 2: decrement each time pushbutton btnD is pressed
        .edge_o(down_edge) // Page 4: Edge Detector will generate a high value for one clock cycle
    );
    
    wire ld_edge;          // Page 2: Your counter is also loadable: when pushbutton btnL is pressed
    
    edge_detector edge_load (
        .clk_i(clk_i),      // Page 5: Connect the clk inputs of the Edge Detector and Counters to a net named clkin.
        .button_o(btnL),    // Page 2: when pressed this button causes the counter to load the value determined by the switches on the clock edge
        .edge_o(ld_edge)    // Page 4: Edge Detector will generate a high value for one clock cycle
    );
    

    // Page 5: 2. In your top level, add and connect the modules for your Ring Counter
    // Page 3: Ring shifts on posedge clk when advance_i (digsel) is high; the bit shifted out wraps around.
    wire [3:0] ring;         // One-hot output: 1000, 0100, 0010, 0001 rotating pattern
    
    ring_counter ring4 (
        .clk_i    (clk_i),   // Page 4: System clock input
        .advance_i(digsel),  // Page 6: digsel should be used to advance the Ring Counter
        .ring_o   (ring)     // Page 4: shifting the bits in a ring.
    );

    // Page 5: 2. In your top level, add and connect the modules for your 16-bit Counter
    wire [15:0] count_16;

    wire utc_o,     // Page 3: Its utc_o output should be 1 when your 16-bit counter is at hex 0xFFFF
         dtc_o;     // Page 3: its dtc_o output should be 1 when your 16-bit counter is at 0x0000

    // Page 5: 2. You will need to provide logic so that depressing btnC does not advance the counter when it is in the range 0xFFFC to 0xFFFF.
    wire up_hold   = (btnC & ~(&(count_16[15:2]))); // Page 2: count up continuously, while btnC is held down except in the range 0xFFFC to 0xFFFF.
    wire held_down = btnL | btnC | btnR;            // Page 6: Pushbuttons btnU and btnD should also to held high for multiple clock cycles.
    
    // Page 3: Make sure it doesn't count when up_i is low and dw_i is low.
    wire up_i = (~held_down & ~btnD & up_edge) | up_hold;  // Page 2: increment each time pushbutton btnU is pressed,
                                                           // Page 2: count up continuously, while btnC is held down
    wire dw_i = ~held_down & ~btnU & down_edge;            // Page 2: decrement each time pushbutton btnD is pressed
    
    wire ld_i = ~btnU & ~btnD & ld_edge;                   // Page 5: when pressed this button causes the counter to load the value determined by the switches on the clock edge

    // Page 3: 16-bit Counter Design
    // Page 3: Your 16-bit counter will have the same ports as the 4-bit counters except that its input and output ports will be 16-bit vectors.
    // Page 3: Its utc_o output should be 1 when your 16-bit counter is at hex 0xFFFF and its dtc_o output should be 1 when your 16-bit counter is at 0x0000.
    // Page 2: Incrementing at value 0xFFFF will result in 0x0000 and decrementing from 0x0000 will result in 0xFFFF.
    countUD16L c16 (
        .clk_i (clk_i),      // Page 5: Connect the clk inputs of the Edge Detector and Counters to a net named clkin. This is the system clock for the design.
        .up_i  (up_i),       // Page 2: increment each time pushbutton btnU is pressed
        .dw_i  (dw_i),       // Page 2: decrement each time pushbutton btnD is pressed
        .ld_i  (ld_i),       // Page 2: when pushbutton btnL is pressed, the 16-bit number determined by the position of the rightmost 16 switches (sw[15:0]) is loaded into the counter
        .Din_i (sw),         // Page 2: the 16-bit number determined by the position of the rightmost 16 switches (sw[15:0]) is loaded into the counter
        .Q_o   (count_16),   // Page 3: a (16)-bit bus, Q_o which is the current value held by the counter
        .utc_o (utc_o),      // Page 3: Its utc_o output should be 1 when your 16-bit counter is at hex 0xFFFF
        .dtc_o (dtc_o)       // Page 3: its dtc_o output should be 1 when your 16-bit counter is at 0x0000
    );


    // ---------------------------- Display Output ----------------------------
    // Page 5: 2. In your top level, add and connect the modules for your Selector and hex7seg
    wire [3:0] nibble;
    selector sel (
        .Sel_i (ring),     // Page 3: a 4-bit control input, Sel i[3:0].
        .N_i   (count_16), // Page 3: has a 16-bit bus, N i[15:0],
        .H_o   (nibble)    // Page 3: output is a 4-bit range of N i[15:0] based on Sel_i.
    );

    // Page 2: These parts will be assembled as below to build a 16-bit counter and display its content in hexadecimal
    // on the four 7-segment displays, plus two LEDs.
    hex7seg display (
        .n  (nibble),     // Page 2: display its content in hexadecimal on the four
        .seg(seg)         // Page 5: this 7 bit vector controls the segments in the 7-segment display
    );

    // ---------------------------- Board Outputs ----------------------------
    assign an  = ~ring;     // Page 5: this 4 bit vector controls the 4 digits of 7-segment display
    assign dp  = 1'b1;      // Page 5: this controls the dp segments in the 7-segment display
    assign led = {utc_o, 14'b0, dtc_o};  // Page 5: this is the leftmost LED below the switches and should display UTC.
                                         // Page 5: Set led[14:1] to 0 so that they will be connected to 0, and not display a random value.
                                         // Page 5: this is the rightmost LED below the switches and should display DTC.

endmodule
