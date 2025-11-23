`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/01/2025 08:08:31 AM
// Design Name:
// Module Name: top_lab5
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

module top_lab5(
    input  clkin,       // Page 1: connect only the system clock to the clock input pins of any sequential components (Basys3 100 MHz input clock)
    input  btnU,        // Page 6: Note that btnU is being used for global reset signal in Lab 5.
    input  btnL,        // Page 6: by pressing btnL and btnR to simulate an object crossing the sensors. (Left pushbutton)
    input  btnR,        // Page 6: by pressing btnL and btnR to simulate an object crossing the sensors. (Right pushbutton)
    output [3:0]  an,   // Page 3: You will keep track of the difference using an up-down counter and display the difference
    output [6:0]  seg,  // on the 2 rightmost digits of the seven segment display.
    output [15:0] led   // Page 3: LED15 (led[15]) displays the signal from the left IR sensor and LED8 (led[8]) 
                        // displays the signal from the right IR sensor.
);

    // ---------------- Clocks ----------------
    // Page 4: They should turn on at the rate of one per 0.25 seconds.
    // You will be provided with a signal qsec that is high for one clock cycle every quarter of a second (same as Lab 4) that you can be used for the leds.
    wire clk, digsel, qsec;
    lab5_clks slowit (
        .clkin (clkin),
        .greset(btnU),
        .clk   (clk),
        .digsel(digsel),
        .qsec  (qsec)
    );

`ifdef SYNTHESIS
    wire clk_i = clk;     // HW: use derived system clock (lab block)
`else
    wire clk_i = clkin;   // SIM: allow direct 100 MHz to speed up testing
`endif

    // ------------- Button → "sensor" interface -------------
    // Page 5: Since the pushbuttons are asynchronous inputs you will want to synchronize them before connecting
    // them to you state machine. Be sure to initialize these synchronizers to reflect the default value of the sensors.
    // So we (1) synchronize each button, then (2) invert so 1=unblocked, 0=blocked.
    wire btnL_sync, btnR_sync;                                      // Synchronized button levels (active-HIGH)
    sensor _syncL (.clk_i(clk_i), .in_i(btnL), .out_o(btnL_sync));  // Two-FF synchronizer
    sensor _syncR (.clk_i(clk_i), .in_i(btnR), .out_o(btnR_sync));  // Two-FF synchronizer

    // ------------- FSM -------------
    // Detects completed crossings and direction, asserts 1-cycle pulses for up/down counting,
    // exports direction bit for the LED walker, and exposes "busy" while a crossing is in progress.
    wire up_pulse, dn_pulse, direction, busy;
    
    // Page 2: In this lab you will design another state machine. This time you will be using signals
    fsm _fsm (
      .clk_i     (clk_i),
      .L         (~btnL_sync),  // 1 = unblocked, 0 = blocked  (invert pushbutton to match sensor polarity) 
      .R         (~btnR_sync),  // 1 = unblocked, 0 = blocked  
      .count_up  (up_pulse),    // L→R completion
      .count_dn  (dn_pulse),    // R→L completion
      .direction (direction),   // 1 while attempting L→R; held afterward to dir walker
      .busy      (busy)         // 1 while attempting a crossing; LEDs must be off then
    );

    // ------------- LED walker (direction indicator) -------------
  
    // Gets enabled by a score change
    wire start_walk = up_pulse | dn_pulse;
    
    // Current direction: update immediately when an up/down pulse occurs, else hold direction
    wire dir_now =
        (up_pulse & 1'b1) |        // set to 1 when up_pulse asserted
        (dn_pulse & 1'b0) |        // set to 0 when dn_pulse asserted
        (~up_pulse & ~dn_pulse & direction);  // hold previous direction
    /* Equivalent:
        wire dir_now = up_pulse ? 1'b1 :
                       dn_pulse ? 1'b0 : direction;
    */
                                    

    // Walker active flag and 3-bit step counter
    // The walker lights the 8 rightmost LEDs one at a time after a crossing is completed.
    wire        walk_active;  // 1 while the LED sequence is running
    wire [2:0]  walk_cnt;     // counts LED steps (0-7)
    
    // pause LEDs while any button is held (also while busy, as before)
    wire paused = busy | btnL_sync | btnR_sync;  // Pause/blank condition: pause during a crossing (busy) OR while any button is held


    // Page 4: You will also need an 8-bit shifter for controlling the 8 rightmost LEDs. You'll want to be able to shift
    // in either from the right or left at the rate of 0.25 seconds.
    wire will_step = walk_active & ~paused & qsec; // advance one LED per qsec when idle

    // Stop after step #7 (8 total)
    // walk_cnt == 3'b111 → all bits are 1 → AND them together
    wire last_walk_led = will_step & walk_cnt[2] & walk_cnt[1] & walk_cnt[0];

    // Active flag FF: start on completion; stop after 8th step; else hold
    wire walk_active_next =
        (start_walk & 1'b1) |            // set to 1 when a new crossing starts
        (~start_walk & walk_active);     // just hold once set flashing
    /* Equivalent:
        wire walk_active_next = start_walk ? 1'b1  :  walk_active;
    */
    
    // D flip-flop with synchronous enable (FDRE primitive)
    // Holds the walker active flag (1 while the LED runner is moving)
    // .INIT(1'b0): walker is inactive on power-up
    // .C(clk_i): driven by system clock
    // .D(walk_active_next): next-state logic (set/start, stop, or hold)
    // .Q(walk_active): current active state output
    FDRE #(.INIT(1'b0)) _walk_active (
        .C(clk_i),            // clock input
        .CE(1'b1),            // always enabled
        .R(1'b0),             // no asynchronous reset
        .D(walk_active_next), // input (next-state)
        .Q(walk_active)       // output (current state)
    );

    // Page 4: You'll also want to be able to reset the shifter to turn off all of the LEDs.
    // 3-bit step counter (0-7):
    // Reset to 0 on start of new walk, Increment by 1 on each will_step, Otherwise hold.
    wire [2:0] walk_cnt_next;

    // Structural "+1" ripple incrementer for walk_cnt
    wire [2:0] inc = walk_cnt + 3'd1;

    // Select between increment and hold; start_walk implicitly resets to 0
    // When start_walk = 1, both masks are 0 → walk_cnt_next = 3'b000 (reset)
    assign walk_cnt_next =
        ({3{~start_walk & will_step}}  & inc)      |  // increment on will_step
        ({3{~start_walk & ~will_step}} & walk_cnt);   // hold otherwise
    /* Equivalent:
        wire [2:0] walk_cnt_next = start_walk ? 3'd0 :
                                   will_step  ? (walk_cnt + 3'd1) :  walk_cnt;
    */
    
    // Page 1: use only positive edge-triggered flip-flops
    FDRE #(.INIT(1'b0)) _ff0 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_cnt_next[0]), .Q(walk_cnt[0]));
    FDRE #(.INIT(1'b0)) _ff1 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_cnt_next[1]), .Q(walk_cnt[1]));
    FDRE #(.INIT(1'b0)) _ff2 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_cnt_next[2]), .Q(walk_cnt[2]));

    wire [7:0] walk;

    // Starting LED pattern for each crossing direction:
    wire [7:0] lr_start = 8'b1000_0000;  // L→R: light starts on the leftmost (LED7)
    wire [7:0] rl_start = 8'b0000_0001;  // R→L: light starts on the rightmost (LED0)

    // Page 4: should turn on in sequence repeatedly from left to right if the last crossing was left-to-right, 
    // and turn on repeatedly from right to left if that crossing was right-to-left.
    wire [7:0] dir = ({8{dir_now}} & lr_start) | ({8{~dir_now}} & rl_start);
    // Equivalent: wire [7:0] dir = dir_now ? lr_start : rl_start;

    // Shift patterns for motion 
    wire [7:0] step_lr = {walk[0], walk[7:1]}; // logical right shift
    wire [7:0] step_rl = {walk[6:0], walk[7]}; // logical left shift

    // Page 4: All of these eight leds should be off before the first crossing and also should be off while a turkey is attempting a crossing.
    wire [7:0] step = ({8{direction}} & step_lr) | ({8{~direction}} & step_rl);
    // Equivalent: wire [7:0] step = direction ? step_lr : step_rl;

    // Page 4: You will also need an 8-bit shifter for controlling the 8 rightmost LEDs. You'll want to be able to shift
    // in either from the right or left at the rate of 0.25 seconds. The current qsec provided by qsec clks
    // should be used. You'll also want to be able to reset the shifter to turn off all of the LEDs.
    
    // Step-or-hold sub-block (qsec is an enable, not a clock)
    // When qsec = 1 → take the next shifted step pattern
    // When qsec = 0 → hold the current pattern (no shift)
    wire [7:0] next_walk_step = ({8{qsec}} & step) | ({8{~qsec}} & walk);
    // Equivalent: wire [7:0] next_walk_step = qsec ? step : walk;

    wire [7:0] walk_next =
        ({8{start_walk}} & dir) |                                        // load dir when a new crossing completes
        ({8{~start_walk & (walk_active & ~paused)}} & next_walk_step) |   // step/hold when active and not paused
        ({8{~start_walk & ~(walk_active & ~paused)}} & walk);             // hold current pattern otherwise
    /* Equivalent:
            wire [7:0] walk_next =
                start_walk ? dir :
               (walk_active & ~paused) ? next_walk_step : 
               walk;
    */

    // Page 1: use only positive edge-triggered flip-flops (Walker FFs explicit 8 bits)
    FDRE #(.INIT(1'b0)) _w0 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_next[0]), .Q(walk[0]));
    FDRE #(.INIT(1'b0)) _w1 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_next[1]), .Q(walk[1]));
    FDRE #(.INIT(1'b0)) _w2 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_next[2]), .Q(walk[2]));
    FDRE #(.INIT(1'b0)) _w3 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_next[3]), .Q(walk[3]));
    FDRE #(.INIT(1'b0)) _w4 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_next[4]), .Q(walk[4]));
    FDRE #(.INIT(1'b0)) _w5 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_next[5]), .Q(walk[5]));
    FDRE #(.INIT(1'b0)) _w6 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_next[6]), .Q(walk[6]));
    FDRE #(.INIT(1'b0)) _w7 (.C(clk_i), .CE(1'b1), .R(1'b0), .D(walk_next[7]), .Q(walk[7]));

    // The LED pattern appears only when not busy, and shows the dir immediately after a crossing.
    // Page 4: All of these eight leds should be off before the first crossing and also should be off while a turkey is attempting a crossing.
    wire [7:0] walk_led =
        ({8{(walk_active | start_walk) & ~paused}} & walk) |   // show LEDs when active or just started
        ({8{~((walk_active | start_walk) & ~paused)}} & 8'b0); // otherwise all off
    // Equialent: wire [7:0] walk_led = ((walk_active | start_walk) & ~paused) ? walk : 8'b0;


    // Page 4: The current value of the sensor inputs should be displayed on LED15 and LED8.
    assign led = {
        btnL_sync,   // Page 3: LED15 (led[15]) displays the current from the left IR sensor
        6'b0,        // [14:9] unused LEDs
        btnR_sync,   // Page 3: and LED8 (led[8]) displays the current from the right IR sensor.
        walk_led     // Page 4: The 8 rightmost leds, led[7:0], should turn on in sequence repeatedly from left to right if the last crossing was left-to-right,
                      // and turn on repeatedly from right to left if that crossing was right-to-left.
    };
    
    // ------------- Counter (same clock as FSM) -------------
    // Page 3: You will keep track of the difference using an up-down counter and display the difference on the 2 rightmost digits of the seven segment display.
    wire [15:0] counter;
    
    // Page 4: You will need an 8-bit counter that can count up or down. Your Lab 4 counters should be handy.
    wire [7:0] anode = counter[7:0]; // the 2 rightmost anodes
    
    // Detect +127 (0x7F = 0111_1111)
    wire pos127 = (~anode[7]) & &anode[6:0]; // anode[7] must be 0, and all lower bits 1 → +127
    // Equivalent: wire pos127 = (anode == 8'h7F);

    // Detect -127 (0x81 = 1000_0001)
    wire neg127 = anode[7] & ~(|anode[6:1]) & anode[0]; // anode[7]=1, bits[6:1]=0, bit[0]=1 → -127 (two's complement)
    // Equivalent: wire neg127 = (anode == 8'h81);
    
    // Page 3: There are at most 127 turkeys so 7 bits will be enough to hold the highest positive value (127). But there could
    // be more left-to-right crossings than right-to-left and this will be a negative number (as low as -127).
    // So your counter will range from -127(-7F in hex) to 127(7F in hex)
    
    // R→L (up_pulse) now increments toward +127
    wire up_i = up_pulse & ~pos127; // block UP at +127   (wire up_i = up_pulse & ~pos127; is L→R)
    
    // L→R (dn_pulse) now decrements toward -127
    wire down_i = dn_pulse & ~neg127; // block DOWN at -127 (wire down_i = dn_pulse & ~neg127; is R→L)

    countUD16L cnt16 (
      .clk_i (clk_i),
      .up_i  (up_i),
      .dw_i  (down_i),
      .ld_i  (1'b0),
      .Din_i (16'h0000),
      .Q_o   (counter),
      .utc_o (), .dtc_o ()
    );

    // Page 3: But when the value held by the counter is negative, it should be converted to its positive
    // magnitude and displayed with a minus sign. For example, in the image below the number displayed
    // is -2 since internally the counter has FE. So, when the number is negative you will need to turn on
    // the led CG (seg[6]) of AN2 and convert the value to its positive magnitude.

    // Idea: if anode is negative, compute (~anode + 1). We do a conditional bitwise invert (XOR with neg)
    // and then ripple-add +1 using XOR (sum) and AND (carry) only.
    wire       neg = anode[7];                 // Sign bit of anode (1 → negative, 0 → positive) 
    wire [7:0] x   = anode ^ {8{neg}};         // Conditional bitwise invert: if neg=1, x=~anode; else x=anode
    
    // Page 4: Note that negative numbers are represented with a "-" sign.
    wire c1 = neg;                            // Initial carry-in = 1 when neg (to add +1), else 0
    
    // Ripple add "+1 when neg" across each bit (sum = x ^ carry_in; carry_out = x & carry_in)
    wire s0 = x[0] ^ c1;  wire c2 = x[0] & c1;  // Bit 0: sum s0, carry to bit1 c2
    wire s1 = x[1] ^ c2;  wire c3 = x[1] & c2;  // Bit 1: sum s1, carry to bit2 c3
    wire s2 = x[2] ^ c3;  wire c4 = x[2] & c3;  // Bit 2: sum s2, carry to bit3 c4
    wire s3 = x[3] ^ c4;  wire c5 = x[3] & c4;  // Bit 3: sum s3, carry to bit4 c5
    wire s4 = x[4] ^ c5;  wire c6 = x[4] & c5;  // Bit 4: sum s4, carry to bit5 c6
    wire s5 = x[5] ^ c6;  wire c7 = x[5] & c6;  // Bit 5: sum s5, carry to bit6 c7
    wire s6 = x[6] ^ c7;  wire c8 = x[6] & c7;  // Bit 6: sum s6, carry to bit7 c8
    wire s7 = x[7] ^ c8;                        // Bit 7: final sum s7 (ignore overflow carry)
    
    // Reassemble the magnitude from MSB→LSB
    wire [7:0] mag = {s7, s6, s5, s4, s3, s2, s1, s0};  // mag = |anode|

    // Nibble select for active digit (only AN0/AN1 carry magnitude)
    wire [15:0] nibbles = {8'h00, mag};
    wire [3:0]  hex_sel;
    
    // ------------- Seven-seg display -------------
    // Ring counter (active-LOW one-hot) selects which digit is driven by hex7seg.
    wire [3:0] ring;
    // Page 6: The current digsel should be used to advance the Ring Counter for the 7-segment displays; it should not be used as a clock!!!
    ring_counter _ring (.clk_i(clk_i), .advance_i(digsel), .ring_o(ring));
    
    // Selector needs active-HIGH one-hot; invert ring (active-LOW) to select the nibble
    selector _sel (.N_i(nibbles), .Sel_i(~ring), .H_o(hex_sel)); // selector expects active-HIGH one-hot

    // 7-seg decode (active-LOW segments)
    wire [6:0] seg_q;
    hex7seg _hex (.n(hex_sel), .seg(seg_q));

    // Overlay minus on AN2 when negative (segment g only); otherwise show decoded digit
    wire minus_sel  = neg & ~ring[2];   // show minus only on AN2 and only when negative
    wire [6:0] seg_minus = 7'b0111111;  // only segment g ON (active-LOW)
    
    // Page 3: It is extremely convenient that no change in the binary counter is required to hold 2’s complement
    // integers. But when the value held by the counter is negative, it should be converted to its positive
    // magnitude and displayed with a minus sign. For example, in the image below the number displayed
    // is -2 since internally the counter has FE. So, when the number is negative you will need to turn on
    // the led CG (seg[6]) of AN2 and convert the value to its positive magnitude.
    assign an[0] = ring[0];       // AN0 follows ring[0] (active-LOW)
    assign an[1] = ring[1];       // AN1 follows ring[1] (active-LOW) 
    assign an[2] = ~minus_sel;    // AN2 on (low) only when negative AND digit 2 is selected
    assign an[3] = 1'b1;          // AN3 off (unused)

    // Page 3: when the value held by the counter is negative, it should be converted to its positive magnitude and displayed with a minus sign.
    assign seg = ({7{minus_sel}} & seg_minus) | ({7{~minus_sel}} & seg_q);
    // Equivalent: assign seg = minus_sel ? seg_minus : seg_q;

endmodule
