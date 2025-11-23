`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/12/2025 02:10:37 PM
// Design Name: 
// Module Name: countUD4L
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

// 4-bit Counter (countUD4L) – A loadable up/down counter with terminal count detection.
module countUD4L(
    input clk_i,        // Page 3: The system input clock
    input up_i,         // Page 3: Increment input port         (btnU)
    input dw_i,         // Page 3: Decrement input port         (btnD)
    input ld_i,         // Page 3: Load control input port      (btnL)
    input [3:0] Din_i,  // Page 3: Data input port, that will be loaded into the counter on the positive clock edge if ld_i is high
                        // (sw[3:0], sw[7:4], sw[11:8], sw[15:12])     
    output [3:0] Q_o,   // Page 3: a 4-bit bus, which is the current value held by the counter
    output utc_o,       // Page 3: the signal (Up Terminal Count) which is 1 only when the counter is at 4'b1111 (15 in decimal)
    output dtc_o        // Page 3: the signal (Down Terminal Count) which is 1 only when the counter is at 4'b0000.
);

    // ---------- Control Logic ----------
    // Page 3: Make sure it doesn't count when up_i is low and dw_i is low.
    wire do_up     =  up_i & ~dw_i;   // Increment when up=1, down=0
    wire do_down   = ~up_i &  dw_i;   // Decrement when up=0, down=1
    wire do_ignore = ~(ld_i | do_up | do_down); // NOT (btnC OR btnU OR btnD)

    // Page 1: use only positive edge-triggered flip-flops (FDRE)
    wire [3:0] next,     // next 4 bits (FDRE .D inputs)
                current; // current 4 bits (FDRE .Q outputs)
    
    // ---------- +1 ripple adder with constant '1' ----------
    // Implements binary addition: current_value + 1
    wire [3:0] plus1 = current + 4'b0001;

    // ---------- -1 using two's complement subtraction (wrap) ----------
    // Implements binary subtraction: current_value - 1
    // In two's complement arithmetic, A - B = A + (~B + 1).
    // Because the counter is 4 bits wide, the result wraps around mod 16 automatically.
    wire [3:0] minus1 = current + 4'b1111;  // Example: 4'b0000 + 4'b1111 = 4'b1111 (0 + 15) mod 16 = 15
                                            //          4'b0101 + 4'b1111 = 4'b0100 (5 + 15) mod 16 = 4

    // ---------- Next-state Multiplexer ----------
    // Page 3: Make sure it loads whenever ld_i is high regardless of up_i or dw_i.
    assign next =
        ({4{ld_i}}      & Din_i)  |   // Page 2: when pushbutton btnL is pressed, the 4-bit number on Din_i is loaded into the counter
        ({4{do_up}}     & plus1)  |   // Page 2: increment each time pushbutton btnU is pressed
        ({4{do_down}}   & minus1) |   // Page 2: decrement each time pushbutton btnD is pressed
        ({4{do_ignore}} & current);   // Page 3: hold the current value when neither input is active
    /* Equivalent:
    assign next =
        ld_i     ? Din_i  :   // Page 2: when pushbutton btnL is pressed, the 4-bit number on Din_i is loaded into the counter
        do_up    ? plus1  :   // Page 2: increment each time pushbutton btnU is pressed
        do_down  ? minus1 :   // Page 2: decrement each time pushbutton btnD is pressed
                   current;   // Page 3: hold the current value when neither input is active
    */

    // Page 1: Using the FDRE module that is part of the "built-in" Unisim library.
    // F = Flip-flop | D = D-type | R = synchronous Reset input | E = clock Enable
    
    // .INIT(1'b0): sets initial Q=0 **once at FPGA configuration time** (power-up). 
    // .C(clk_i): main clock input - defines *when* the flip-flop samples D (on rising edge)
    // .R(1'b0): synchronous reset (inactive here) - can force Q to 0 regardless of D
    // .CE(1'b1): clock enable (always ON) - allows capturing new data every clock cycle
    // .D(next[0]): next-state value for bit 0, computed by combinational logic
    // .Q(current[0]): current state (output) of bit 0, updated on the next rising clock edge
    FDRE #(.INIT(1'b0)) // Create an FDRE flip-flop #1 (LSB)
        _4ff1 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(next[0]), .Q(current[0]));
    
    // Bit 1 flip-flop
    // Captures .D(next[1]) on rising clock edge (when CE=1 and reset inactive)
    // .Q(current[1]) stores the current state of bit 1
    FDRE #(.INIT(1'b0)) // Create an FDRE flip-flop #2
        _4ff2 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(next[1]), .Q(current[1]));
    
    // Bit 2 flip-flop
    // Captures .D(next[2]) on rising clock edge .C(clk_i)
    // .Q(current[2]) stores the current state of bit 2
    FDRE #(.INIT(1'b0)) // Create an FDRE flip-flop #3
        _4ff3 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(next[2]), .Q(current[2]));
    
    // Bit 3 flip-flop (most significant bit)
    // Captures .D(next[3]) on rising clock edge .C(clk_i)
    // .Q(current[3]) stores the current state of bit 3 (MSB)
    FDRE #(.INIT(1'b0)) // Create an FDRE flip-flop #4 (MSB)
        _4ff4 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(next[3]), .Q(current[3]));


    // ---------- Output Assignment ----------
    assign Q_o   = current;
    // Page 3: Make sure utc_o is high only when the counter bits are all 1's
    assign utc_o = &current;        // AND all bits: 1 when all bits are 1 (1111)
                                    // assign utc_o =  (current[0] & current[1] & current[2] & current[3])
    // Page 3: and dtc_o is high only when the counter bits are all 0's.
    assign dtc_o = ~|current;       // NOT all bits: 1 when all bits are 0 (0000)
                                    // assign dtc_o =  ~(current[0] | current[1] | current[2] | current[3])
endmodule