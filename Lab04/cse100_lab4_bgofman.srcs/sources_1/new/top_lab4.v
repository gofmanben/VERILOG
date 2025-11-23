`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 10/23/2025 10:10:37 PM
// Design Name:
// Module Name: top_lab4
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

module top_lab4(
    input clkin,        // Page 2: connect only the system clock as input to the clock pins of any sequential components
    input btnR,         // Page 3: btnR will be used as global reset (as usual) and should only be connected to the module qsec clks.v described below
    input btnC,         // Page 3: will be used as the "Go" signal.
                        // Page 3: A Go signal is given (pushbutton btnC is pressed) to start each round,
    input  [15:0] sw,   // Page 3: however the round will not begin unless all switches are set to 0.
                        // Page 3: 3. The round ends as soon as any switch is flipped
                        // Page 3: 6. The correct switch corresponds to the value of the target number. For example if the target number is C, then switch sw[12], the fourth from the left, should be flipped.
    output [3:0] an,    // Page 3: When it is less than 0, it is represented as with a "-" on an[1] and its magnitude on an[0].
                        // Page 3: The score is always displayed on the rightmost digit of the 7-segment display.
    output [6:0] seg,   // Page 3: 2. In each round, a random 4-bit binary value (the target number) is selected and displayed on the leftmost digit.
                        // Page 3: 11. The score is always displayed on the rightmost digit of the 7-segment display. When it is less than 0, it is represented as with a "-"
    output [15:0] led   // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost and the led next to the correct switch flashes for four seconds.
                        // Page 3: 5. If the correct switch is flipped then the current score flashes for two seconds, then it is incremented and flashes for two more seconds.
                        // Page 3: the game has been won. The score will continue flashing and all 16 leds will also flash.
                        // Page 3: And if the score is currently -4, the correct led will continue flashing and the game is over. This is a loss.
);

    // Clock signals for the design
    wire clk;           // Page 8: Create a net named clk, connect it to the clock input of your state machine, LFSR, 8-bit loadable
                        // counter and any other sequential components. This is the system clock for the design. 
                        // It is the only signal which can be used as a clock in your design.
    wire digsel;        // Page 8: The signal digsel should be used to advance the Ring Counter for
                        // the 7-segment displays; it should not be used as a clock!!!
    wire qsec;          // Page 3: is high for one clock cycle every 1/4 of a second and is provided by qsec clks.v.
                        // Page 8: is high for one clock cycle each 1/4 second (4 times per second) and should be used to
                        // advance the Time Counter; it should not be used as a clock!!!
    
    //-------------------------------------------------
    // Clock Monitor (See qsec_clks.v)
    //-------------------------------------------------
    // Page 8: Add an instance of the module qsec_clks to your top level as follows:
    qsec_clks slowit (
        .clkin (clkin),   // Page 8: clkin is your system clock.
        .greset(btnR),    // Page 3: will be used as global reset (as usual) and should only be connected to the module qsec clks.v described below
        .clk   (clk),     // Page 4: The BASYS3 clock clkin and global reset btnR are inputs, but will not be part of the rest of your logic.
        .digsel(digsel),  // Page 8: The signal digsel should be used to advance the Ring Counter for
                          // the 7-segment displays; it should not be used as a clock!!!
        .qsec(qsec)       // Page 8: qsec is high for one clock cycle each 1/4 second (4 times per second) and should be used to
                          // advance the Time Counter; it should not be used as a clock!!!
    );

    wire clk_i = clk;     // Page 8: Create a net named clk, connect it to the clock input of your state machine, LFSR, 8-bit loadable
    
    // Page 3: 8. But if the score is currently 4 then the game has been won.
    wire signed [3:0] WIN_SCORE  =  4'sd4;   // 4 width, signed(s), decimal(d), +4 (value in two's complement binary: 0100)
    
    // Page 3: 9. And if the score is currently -4, the correct led will continue flashing and the game is over. This is a loss.
    wire signed [3:0] LOSE_SCORE = -4'sd4;   // 4-bit width, signed(s), decimal(d), -4 (value two's complement binary: 1100)
    
    //-------------------------------------------------
    // Score register, clamped to [-4, +4]
    //-------------------------------------------------
    
    // Page 3: 5. If the correct switch is flipped then the current score flashes for two seconds, then it is incremented and flashes for two more seconds.
    wire inc_score_o, dec_score_o;           // From FSM: request +1 or -1 to the score this cycle
    
    wire signed [3:0] score_c;               // Current signed score, range [-4 .. +4]
    wire signed [3:0] score_n;               // Next score value to be clocked in
    
    // Candidate next score before saturation
    wire signed [3:0] plus1  = score_c + 4'sd1;  // score + 1 → 4-bit width, signed(s), decimal(d), +1 (value in two's complement binary: 0001)
    wire signed [3:0] minus1 = score_c - 4'sd1;  // score - 1 → 4-bit width, signed(s), decimal(d), -1 (value in two's complement binary: 1111)
    
    // Compute the next score value based on FSM control signals
    wire signed [3:0] bin_next =
        ({4{inc_score_o}} & plus1)  |    // If inc_score_o = 1 → increase score by 1
        ({4{dec_score_o}} & minus1) |    // Else if dec_score_o = 1 → decrease score by 1
        ({4{~(inc_score_o | dec_score_o)}} & score_c); // Else → keep the current score unchanged
    // Equivalent: wire signed [4:0] bin_next = inc_score_o ? plus1 : dec_score_o ? minus1 : score_c;
    
    // Saturation logic: keep score within the allowed range [-4, +4]
    assign score_n =
        ({4{ (bin_next > WIN_SCORE) }} & WIN_SCORE)  |  // If bin_next exceeds +4 → clamp to +4
        ({4{ (bin_next < LOSE_SCORE)}} & LOSE_SCORE) |  // If bin_next goes below -4 → clamp to -4
        ({4{~((bin_next > WIN_SCORE) | (bin_next < LOSE_SCORE))}} & bin_next); // within range, no change
    /* Equivalent: 
        assign score_n =
            (bin_next > WIN_SCORE)   ? WIN_SCORE  : // If bin_next exceeds +4 → clamp to +4
            (bin_next < LOSE_SCORE)  ? LOSE_SCORE : // If bin_next goes below -4 → clamp to -4
                                       bin_next;    // within range, no change
    */
    
    // 4 flip-flops hold the score register. INIT(0) means we start at score 0.
    FDRE #(.INIT(1'b0)) s0 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(score_n[0]), .Q(score_c[0]));
    FDRE #(.INIT(1'b0)) s1 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(score_n[1]), .Q(score_c[1]));
    FDRE #(.INIT(1'b0)) s2 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(score_n[2]), .Q(score_c[2]));
    FDRE #(.INIT(1'b0)) s3 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(score_n[3]), .Q(score_c[3]));
    
    // XOR finds any mismatched bits, and reduction NOR (~|) outputs 1 only if all bits match.
    wire won_i  = ~| (score_c ^ WIN_SCORE);   // High when score == +4 → game is won
    // Equality check: wire won_i  = (score_c ==  WIN_SCORE);
    wire lost_i = ~| (score_c ^ LOSE_SCORE);  // High when score == -4 → game is lost
    // Equality check: wire lost_i  = (score_c ==  LOSE_SCORE);
    
    // Page 5: This will be your method of reseting the counter.
    wire  reset_timer_o;   // From FSM: one-cycle pulse during which the time counter synchronously loads 0 instead of incrementing.
    wire [5:0]  q_time;    // 6-bit time count; increments by 1 on each qsec pulse (once every 0.25 s)
                           // and goes back to 0 when reset_timer_o is asserted (start of a new timed phase).

    //-------------------------------------------------
    // Time Counter (See time_counter.v)
    //-------------------------------------------------
    time_counter _time_counter (
        .clk_i    (clk_i),          // Page 8: clkin is your system clock. The signal digsel should be used to advance the Ring Counter
        .inc_i    (qsec),           // Page 8: 12: is high for one clock cycle each 1/4 second (4 times per second) and should be used to advance the Time Counter;
        .dec_i    (1'b0),           // Not counting down in this design (counting up only).
        .reset_i  (reset_timer_o),  // Page 5: This will be your method of reseting the counter.
                                    // When 1, synchronously load din instead of incrementing.
        .din      (6'b0),           // Page 5: You will need a loadable counter that can load a 6-bit binary value and count down to 0 (or vice versa).
                                    // Value to load on reset (0).
        .q_o      (q_time)          // Page 5: You can actually use your 16-bit counter and leave the top bits unconnected.
                                    // Output: current time count in 1/4-second ticks.
    );

    //-------------------------------------------------
    // Derive 2-second and 4-second event pulses
    //-------------------------------------------------
    // Since q_time increments every 0.25 seconds:
    // 8 ticks = 2 seconds, 16 ticks = 4 seconds.
    // Page 3: 3. The round ends as soon as any switch is flipped or when two seconds have elapsed, which ever occurs first.
    wire [5:0] TWO_SEC_TICKS  = 6'd8;   // 8 × 0.25 s = 2 seconds

    // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost and the led next to the correct switch flashes for four seconds.
    wire [5:0] FOUR_SEC_TICKS = 6'd16;  // 16 × 0.25 s = 4 seconds
    
    // XOR highlights bit differences; reduction NOR (~|) outputs 1 only if all bits match.
    // So hit_2sec = 1 when q_time == 8; hit_4sec = 1 when q_time == 16.
    wire hit_2sec = ~| (q_time ^ TWO_SEC_TICKS);   // Page 3: the led next to the correct switch flashes for four seconds.
                                                   // High when q_time == 8
    wire hit_4sec = ~| (q_time ^ FOUR_SEC_TICKS);  // Page 3: 7. After 4 seconds, either way, if the score is less than 4 and greater than negative 4,
                                                   // High when q_time == 16
    
    // Combine with qsec pulse to generate single-cycle timing events. FSM uses these to control phase transitions.
    wire two_secs_i  = qsec & hit_2sec;  // Page 3: the switch associated with the number must be flipped within two seconds.
                                         // Pulse when 2-second mark reached
    wire four_secs_i = qsec & hit_4sec;  // Page 3: It will remain on the display until the 4 seconds after a correct or incorrect or no switch is flipped.
                                         // Pulse when 4-second mark reached

    //-------------------------------------------------
    // FSM instance input/output
    //-------------------------------------------------
    
    // Page 3: 5. If the correct switch is flipped then the current score flashes for two seconds, then it is incremented and flashes for two more seconds.
    // Page 3: 8. But if the score is currently 4 then the game has been won. The score will continue flashing
    wire flash_score_o;   // FSM: when 1, make the score blink for celebration / feedback.

    // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost and the led next to the correct switch flashes for four seconds.
    // Page 3: 8. But if the score is currently 4 then the game has been won. The score will continue flashing and all 16 leds will also flash.
    // Page 3: 9. And if the score is currently -4, the correct led will continue flashing and the game is over. This is a loss.
    wire flash_led_o;     // FSM: when 1, blink the correct LED (or all LEDs if won).
    
    // Page 3: 2. In each round, a random 4-bit binary value (the target number) is selected and displayed on the leftmost digit.
    wire show_target_o;   // FSM: when 1, we should display the target value on the leftmost 7-seg digit.
    
    // Page 3: 2. In each round, a random 4-bit binary value (the target number) is selected and displayed on the leftmost digit.
    wire load_target_o;   // One-cycle pulse from FSM to load a new 4-bit random target from LFSR at the start of each round.   
    
    // Page 3: 6. The correct switch corresponds to the value of the target number ...
    wire [3:0] target_c;  // Holds the current target number that the player is trying to match.
    
    // Page 3: 12. The target number after the Go signal. It will remain on the display until the 4 seconds after a correct or incorrect or no switch is flipped.
    wire [3:0] target_n;  // Next value that will be loaded into target_c on the next clock edge.
    
    // Page 6: 2. Anysw: This is an input that tells the FSM that one of the switches on the board has been flipped.   
    wire anysw_i = |sw;   // High if ANY of the 16 switches is ON (OR-reduction of sw[15:0]). Used by FSM to know "the player made a choice".

    //-------------------------------------------------
    //  Decoder (See decoder.v)
    //-------------------------------------------------
    // Page 3: ... For example if the target number is C, then switch sw[12], the fourth from the left, should be flipped.
    wire [15:0] correct_sw;   // One-hot LED mask: exactly one bit is 1, all others 0. This marks which switch/LED is the "correct" one.

    // Page 6: An n-bit decoder has n inputs and 2n outputs. Only one of the outputs is high, the one corresponding to the value represented by the n-bit inputs.
    decoder _dec (
        .in_i  (target_c),    // The 4-bit target value (0..15).
        .out_o (correct_sw)   // Expands that value to a 16-bit one (0001000... style).
    );
    
    // Page 6: Comparing the decoder output with the switches will provide the match input to the state machine that indicates whether the correct or incorrect switch was flipped.
    // Page 7: 4. Match: This signal is used to determine whether the player correctly matched the switch that corresponds to the value of the target number.
    wire match_i = ~| (sw ^ correct_sw);    // High if player's switch pattern EXACTLY equals the
    // Equivalent: 
    // wire match_i = (sw == correct_sw);
    
    //-------------------------------------------------
    // Edge detect / synchronize btnC -> Go pulse (See edge_detector.v)
    //-------------------------------------------------
    wire btnC_edge;
    edge_detector _go (
        .clk_i    (clk_i),      // Page 6: Note that the inputs from btnC is not synchronized with your clock (it is asynchronous).
        .button_i (btnC),       // Page 3: A Go signal is given (pushbutton btnC is pressed) to start each round,
        .edge_o   (btnC_edge)   // Page 6: This Go signal is tied to btnC.
    );

    //-------------------------------------------------
    // State Machine (FSM) (See fsm.v)
    //-------------------------------------------------
    fsm _fsm (
        .clk_i          (clk_i),         // System clock.
        .Go_i           (btnC_edge),     // "Go" pulse (btnC edge-detected and synchronized).
        .four_secs_i    (four_secs_i),   // 4-second timeout event.
        .two_secs_i     (two_secs_i),    // 2-second timeout event.
        .match_i        (match_i),       // Player picked the correct switch.
        .anysw_i        (anysw_i),       // Player flipped at least one switch.
        .won_i          (won_i),         // Global win state (score == +4).
        .lost_i         (lost_i),        // Global lose state (score == -4).

        .load_target_o  (load_target_o), // Ask target register to capture a new random target.
        .reset_timer_o  (reset_timer_o), // Reset the q_time counter for a new phase.
        .inc_score_o    (inc_score_o),   // Add +1 to score.
        .dec_score_o    (dec_score_o),   // Subtract 1 from score.
        .show_target_o  (show_target_o), // Tell display logic to show the target on left digit.
        .flash_score_o  (flash_score_o), // Blink the score on the display.
        .flash_led_o    (flash_led_o)    // Blink LEDs (correct LED or all LEDs).
    );
    
    //-------------------------------------------------
    // Linear Feedback Shift Register (LFSR) (See lfsr.v)
    //-------------------------------------------------
    // Page 4: a Linear Feedback Shift Register (LFSR) to generate a random 8-bit binary number.
    wire [7:0] lfsr_q;
    lfsr _lfsr (
        .clk_i(clk_i),          // Page 8: It is the only signal which can be used as a clock in your design.
        .q_o  (lfsr_q)          // Page 5: will go through a sequence of all 255 non-zero states before it repeats.
    );

    // Multiplex between holding the old target and capturing a new random value.
    assign target_n[0] = (~load_target_o & target_c[0]) | (load_target_o & lfsr_q[0]);
    // Equivalent: assign target_n[0] = load_target_o ? lfsr_q[0] : target_c[0];
    assign target_n[1] = (~load_target_o & target_c[1]) | (load_target_o & lfsr_q[1]);
    // Equivalent: assign target_n[1] = load_target_o ? lfsr_q[1] : target_c[1];
    assign target_n[2] = (~load_target_o & target_c[2]) | (load_target_o & lfsr_q[2]);
    // Equivalent: assign target_n[2] = load_target_o ? lfsr_q[2] : target_c[2];
    assign target_n[3] = (~load_target_o & target_c[3]) | (load_target_o & lfsr_q[3]);
    // Equivalent: assign target_n[3] = load_target_o ? lfsr_q[3] : target_c[3];

    // Page 2: Your designs must be synchronous with the system clock specified in the lab. This means:
    // • use only positive edge-triggered flip-flops (FDRE)
    // INIT(0) here means the target starts as 0000 after configuration so you don't get Xs.
    FDRE #(.INIT(1'b0)) t0 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(target_n[0]), .Q(target_c[0]));
    FDRE #(.INIT(1'b0)) t1 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(target_n[1]), .Q(target_c[1]));
    FDRE #(.INIT(1'b0)) t2 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(target_n[2]), .Q(target_c[2]));
    FDRE #(.INIT(1'b0)) t3 (.C(clk_i), .R(1'b0), .CE(1'b1), .D(target_n[3]), .Q(target_c[3]));

    //-------------------------------------------------
    // Blink generator for flashing LEDs / digits
    //-------------------------------------------------
    // Page 3: 4. ... the led next to the correct switch flashes for four seconds.
    // Page 3: 8. ... all 16 leds will also flash.
    wire blink_c;                     // Holds a 1-bit state that flips 0→1→0→1...
    wire blink_n =
        ({1{qsec}}  & ~blink_c) |     // if qsec = 1 → toggle state
        ({1{~qsec}}  &  blink_c);     // if qsec = 0 → hold current state
    // Equivalent: wire blink_n = qsec ? ~blink_c : blink_c;

    FDRE #(.INIT(1'b0)) _blink (.C(clk_i), .R(1'b0), .CE(1'b1), .D(blink_n), .Q(blink_c));

    //-------------------------------------------------
    // LED output policy
    // - If the player wins: flash all LEDs
    // - If wrong or lost: blink the correct LED for feedback
    // - If in "show target" phase: show correct LED only if CHEAT mode is ON
    // - Otherwise: turn all LEDs off
    //-------------------------------------------------
    
    // Page 3: 8. But if the score is currently 4 then the game has been won. The score will continue flashing and all 16 leds will also flash. 
    wire game_won_flash = won_i & blink_c; 
    
    // Page 3: 9. And if the score is currently -4, the correct led will continue flashing and the game is over. This is a loss.
    // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost and the led next to the correct switch flashes for four seconds.
    wire wrong_flash = flash_led_o & blink_c;  // Blink pattern for WRONG or LOSE: blink the correct LED
    
    // CHEAT mode (debug): 1 = reveal correct LED during the round, 0 = hide it from the player.
    assign cheat = 0;              
    
    // Priority encoder for LED driving:
    // 1) If we've won: flash all LEDs.
    // 2) Else if we're in WRONG/LOSE feedback: flash only the correct LED bit.
    // 3) Else if we're in normal ROUND SHOW: optionally reveal correct LED if cheat=1.
    // 4) Else: LEDs off.
    assign led =
        ({16{game_won_flash}} & 16'hFFFF) |                       // WIN: blink all LEDs
        ({16{flash_led_o & wrong_flash}} & correct_sw) |          // WRONG/LOSE: blink correct LED
        ({16{show_target_o & cheat}} & correct_sw);               // SHOW: reveal correct LED (debug)
    /* 
    Equivalent: 
        assign led =
            game_won_flash ? 16'hFFFF :                              // WIN: blink all 16 LEDs
            flash_led_o    ? (wrong_flash ? correct_sw : 16'h0000) : // WRONG/LOSE: blink the correct LED
            show_target_o  ? (correct_sw & {16{cheat}}) :            // SHOW: show correct LED only if cheat=1
                           16'h0000;                                 // Otherwise: all LEDs off
    */
    
    //-------------------------------------------------
    // 7-segment value generation and encoding
    //------------------------------------------------

    // Page 3: After 4 seconds, either way, if the score is less than 4 and greater than negative 4,
    // then a new round can begin with a Go signal if the switches are all reset back to 0.
    wire neg = score_c[3];   // neg = 1 if score is negative (MSB of 4-bit signed score_c).
    
    // compute absolute value of signed 4-bit score_c (range -4..+4)
    // Two's-complement absolute value: if negative, invert+1, else keep.
    wire [3:0] score_abs =
        ({4{~neg}} & score_c) |           // when not negative → pass through
        ({4{neg}}  & (~score_c + 4'sd1)); // when negative → invert + 1
    // Equivalent: wire [3:0] score_abs = neg ? (~score_c + 4'sd1) : score_c;

    // d0 (rightmost): show absolute value of the score.
    // Page 3: 11. The score is always displayed on the rightmost digit of the 7-segment display.
    wire [3:0] hex_d0 = score_abs[3:0];

    // d1: show '-' when score is negative, otherwise blank.
    // Page 3: 11 ... When it is less than 0, it is represented as with a "-" on an[1]
    wire [3:0] hex_d1 =
        ({4{neg}}  & 4'hD) |     // if negative → display dash ("-")
        ({4{~neg}} & 4'hF);      // else → blank
    // Equivalent: wire [3:0] hex_d1 = neg ? 4'hD : 4'hF;

    // d2: always blank (unused digit).
    wire [3:0] hex_d2 = 4'hF;

    // d3 (leftmost): show the target value when FSM requests it.
    // Page 3: 11 ... and its magnitude on an[0].
    // Page 3: 2. In each round, a random 4-bit binary value (the target number) is selected and displayed on the leftmost digit.
    wire [3:0] hex_d3 =
        ({4{ show_target_o}} & target_c) |  // when show_target_o = 1 → show target
        ({4{~show_target_o}} & 4'hF);       // else → blank
    // Equivalent: wire [3:0] hex_d3 = show_target_o ? target_c : 4'hF;

    // Page 8: The signal digsel should be used to advance the Ring Counter for the 7-segment displays; it should not be used as a clock!!!
    wire [3:0] an_q; // Page 3: A ring counter holds a bit vector which has a single 1 bit.

    //-------------------------------------------------
    // Ring Counter - Cycles control signals (See ring_counter.v)
    //-------------------------------------------------
    ring_counter _ring_counter (
        .clk_i     (clk_i),   // Page 8: clkin is your system clock.
        .advance_i (digsel),  // Page 8: The signal digsel should be used to advance the Ring Counter for the 7-segment displays
        .ring_o    (an_q)     // Lab 3. Page 4: A ring counter holds a bit vector which has a single 1 bit.
    );

    // Pack all 4 digits' nibbles and all 4 "which digit is active" selects.
    wire [15:0] nibble_bus = {hex_d3, hex_d2, hex_d1, hex_d0};
    wire [3:0]  sel_an     = {~an_q[3], ~an_q[2], ~an_q[1], ~an_q[0]};

    wire [3:0] hex_sel;  // The nibble (0..F) that should be shown RIGHT NOW.

    //-------------------------------------------------
    // Selector - Chooses one of four 4-bit segments (See selector.v)
    //-------------------------------------------------
    selector _sel (
        .Sel_i (sel_an),      // One-hot select of which digit is active.
        .N_i   (nibble_bus),  // All 4 nibbles bundled together.
        .H_o   (hex_sel)      // Output = the nibble for the active digit.
    );

    // Convert a 4-bit hex nibble (0..F plus 0xD for minus) into 7-seg segments.
    wire [6:0] seg_q;

    //-------------------------------------------------
    // 7-Segment Converter (See hex7seg.v)
    //-------------------------------------------------
    hex7seg _hex (
        .n   (hex_sel),
        .seg (seg_q)
    );

    // If currently scanning digit1 (an_q[1] == 0, active low)
    // and the score is negative, show a custom '-' (middle segment only);
    // otherwise, show the normal hex pattern.
    assign seg =
        ({7{(~an_q[1] & neg)}} & 7'b0111111) |  // active digit1 and negative → show '-'
        ({7{~(~an_q[1] & neg)}} & seg_q);       // otherwise → show normal hex
    // Equivalent: seg = (~an_q[1] & neg) ? 7'b0111111 : seg_q;

    //-------------------------------------------------
    // Anode enable and scan control
    //-------------------------------------------------

    // (rightmost): show score (and blink it if flash_score_o is set).
    wire an0 = ((~flash_score_o) & 1'b1) | (flash_score_o & blink_c);
    // Equivalent:  an0 = (flash_score_o ? blink_c : 1'b1)

    // show '-' if score is negative (and blink it together with score).
    wire an1 = ((~flash_score_o) & neg) | (flash_score_o & (neg & blink_c));
    // Equivalent: an1 = (flash_score_o ? (neg & blink_c) : neg)

    // an2: always off.
    wire an2 = 1'b0;

    // (leftmost): show the target value when FSM says so.
    wire an3 = show_target_o;

    // Masked anodes = what actually goes to the board.
    // If a digit is "disabled", force its anode bit to 1 (off).
    wire [3:0] masked_an;
    assign masked_an[0] = ((~an0) & 1'b1) | (an0 & an_q[0]);
    // Equivalent: assign masked_an[0] = an0 ? an_q[0] : 1'b1;

    assign masked_an[1] = ((~an1) & 1'b1) | (an1 & an_q[1]);
    // Equivalent: assign masked_an[1] = an1 ? an_q[1] : 1'b1;

    assign masked_an[2] = ((~an2) & 1'b1) | (an2 & an_q[2]);
    // Equivalent: assign masked_an[2] = an2 ? an_q[2] : 1'b1;

    assign masked_an[3] = ((~an3) & 1'b1) | (an3 & an_q[3]);
    // Equivalent: assign masked_an[3] = an3 ? an_q[3] : 1'b1;
    assign an = masked_an;  // Drive FPGA anode pins with masked pattern.
    
endmodule
