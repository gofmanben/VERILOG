`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 09:13:52 PM
// Design Name: 
// Module Name: fsm
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

module fsm(
    input  clk_i,           // Page 8: This is the system clock for the design. It is the only signal which can be used as a clock in your design.
    input  Go_i,            // Page 6: 1. Go: To initiate a round, the Go signal must be set high for a cycle while the FSM waits for a
                            // new round to start. This Go signal is tied to btnC.                                                
    input  four_secs_i,     // Page 7: 3. FourSecs and TwoSecs: These signals are created using the output of the Time Counter
    input  two_secs_i,      // module with some additional logic. Hint: is there a signal created by a module that you know oscillates at a known frequency?
    input  match_i,         // Page 7: 4. Match: This signal is used to determine whether the player correctly matched the switch that
                            // corresponds to the value of the target number. Equilavence is easily checked with a single logic
                            // gate. Hint: it is one of the lesser known ones.
    input  anysw_i,         // Page 6: 2. Anysw: This is an input that tells the FSM that one of the switches on the board has been flipped.
    input  won_i,           // Page 7: 5. These are the signals that tell the FSM whether the game has been won or lost in its entirety.
                            // Global win state (score == +4).
    input  lost_i,          // Page 7: 5. These are the signals that tell the FSM whether the game has been won or lost in its entirety.
                            // Global lose state (score == -4).

    output load_target_o,   // Page 3: 2. In each round, a random 4-bit binary value (the target number) is selected and displayed on the leftmost digit.
                            // Ask target register to capture a new random target.
    output reset_timer_o,   // Page 7: 3. These signals are created using the output of the Time Counter module with some additional logic.
                            // Reset the q_time counter for a new phase.
    output inc_score_o,     // Page 3: 5. If the correct switch is flipped then the current score flashes for two seconds, then it is incremented and flashes for two more seconds.
                            // Add +1 to score.
    output dec_score_o,     // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost and the led next to the correct switch flashes for four seconds.
                            // Subtract 1 from score.
    output show_target_o,   // Page 3: 2. In each round, a random 4-bit binary value (the target number) is selected and displayed on the leftmost digit.
                            // Page 3: 12. The target number after the Go signal. It will remain on the display until the 4 seconds
    output flash_score_o,   // Page 3: 5. If the correct switch is flipped then the current score flashes for two seconds, then it is incremented and flashes for two more seconds.
                            // Page 3: 8. But if the score is currently 4 then the game has been won. The score will continue flashing
    output flash_led_o      // and all 16 leds will also flash.
                            // Page 3: 9. And if the score is currently -4, the correct led will continue flashing and the game is over. This is a loss.
                            // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost and the led next to the correct switch flashes for four seconds.
);

    // States (one-hot)
    // IDLE   : waiting for next round
    // SHOW   : target displayed, waiting for player or timeout
    // CORR   : correct answer -> score incremented, flash score 4s
    // WRONG  : wrong/timeout -> score decremented, flash LED 4s
    // WIN    : score == +4, game locked
    // LOSE   : score == -4, game locked
    wire C_IDLE, C_SHOW, C_CORR, C_WRONG, C_WIN, C_LOSE; // C_ - current
    wire N_IDLE, N_SHOW, N_CORR, N_WRONG, N_WIN, N_LOSE; // N_ - next

    // helper cond
    wire ready_for_round =  ~won_i & ~lost_i & // Page3: 1. A Go signal is given (pushbutton btnC is pressed) to start each round,
                            ~anysw_i;          // however the round will not begin unless all switches are set to 0.
    wire flip_correct    = anysw_i & match_i; // Page 6: This signal is used to determine whether the player correctly matched the switch that
                                              // corresponds to the value of the target number.

    // Page 3: You will use the BASYS3 board to implement the following single player game in which a target
    // number is presented and the switch associated with the number must be flipped within two seconds.
    wire round_fail = (anysw_i & ~match_i) |       // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost
                      (~anysw_i & two_secs_i);     // Page 3: when two seconds have elapsed, which ever occurs first.

    // Next state logic:

    // IDLE:
    // - Stay in IDLE by default.
    // - Leave IDLE and go to SHOW if Go is pressed AND we're allowed to start a round.
    // - Return to IDLE after CORR/WRONG finishes the 4-second feedback, provided the game is not over.
    assign N_IDLE =
        // Page 3: then a new round can begin with a Go signal if the switches are all reset back to 0.
        (C_IDLE & ~(Go_i & ready_for_round))|
        // Page 3: 5. If the correct switch is flipped then the current score flashes for two seconds
        // Page 3: 7. After 4 seconds, either way, if the score is less than 4 and greater than negative 4
        // Page 3: 10. The Go signal will have no effect when the game is over, win or lose.
        (C_CORR & four_secs_i & ~won_i & ~lost_i) |
        // Page 3: 4. If an incorrect switch is flipped or no switch is flipped
        // Page 3: 7. After 4 seconds, either way, if the score is less than 4 and greater than negative 4
        // Page 3: 10. The Go signal will have no effect when the game is over, win or lose.
        (C_WRONG & four_secs_i & ~won_i & ~lost_i);

    // SHOW:
    // - Stay in SHOW until:
    // - Player gets it right  (flip_correct),
    // - OR we detect fail (wrong flip or timeout) round_fail.
    assign N_SHOW =
        // Page 3: 1. A Go signal is given (pushbutton btnC is pressed) to start each round, however the round will not begin unless all switches are set to 0.
        (C_IDLE & Go_i & ready_for_round) |
        // Page 3: 3. The round ends as soon as any switch is flipped or when two seconds have elapsed, which ever occurs first.
        (C_SHOW & ~(flip_correct | round_fail));

    // CORR:
    // - Enter when correct flip happens in SHOW
    // - Stay until 4-second window ends, unless game is now WIN
    assign N_CORR =
        (C_SHOW & flip_correct) |  // Page 3: 5. If the correct switch is flipped then the current score
        (C_CORR & ~four_secs_i);   // flashes for two seconds, then it is incremented and flashes for two more seconds.

    // WRONG:
    // - Enter on wrong/timeout in SHOW
    // - Stay until 4-second window ends, unless game is now LOSE
    assign N_WRONG =
        (C_SHOW & round_fail) |     // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost
        (C_WRONG & ~four_secs_i);   // and the led next to the correct switch flashes for four seconds.

    // WIN:
    // - Enter WIN after CORR finishes 4s and we hit +4,
    // - Then remain there forever
    assign N_WIN =
        (C_CORR  & four_secs_i       // Page 3: 5. If the correct switch is flipped then the current score flashes for two seconds, then it is incremented and flashes for two more seconds.
         & won_i) |                  // Page 3: 8. But if the score is currently 4 then the game has been won.
        C_WIN;                       // Page 3: 10. The Go signal will have no effect when the game is over, win or lose.

    // LOSE:
    // - Еnter LOSE after WRONG finishes 4s and we hit -4,
    // - Тhen remain there forever
    assign N_LOSE =
        (C_WRONG & four_secs_i     // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost and the led next to the correct switch flashes for four seconds.
        &  lost_i) |               // Page 3: 9. And if the score is currently -4, the correct led will continue flashing and the game is over. This is a loss.
        C_LOSE;                    // Page 3: 10. The Go signal will have no effect when the game is over, win or lose.

    // Page 6: Note that the inputs from btnC is not synchronized with your clock (it is asynchronous). You
    // should pass this input through a syncronizer (D Flip-Flop) before using them in your design.
    FDRE #(.INIT(1'b1)) ff_IDLE  (.C(clk_i), .R(1'b0), .CE(1'b1), .D(N_IDLE),  .Q(C_IDLE));
    FDRE #(.INIT(1'b0)) ff_SHOW  (.C(clk_i), .R(1'b0), .CE(1'b1), .D(N_SHOW),  .Q(C_SHOW));
    FDRE #(.INIT(1'b0)) ff_CORR  (.C(clk_i), .R(1'b0), .CE(1'b1), .D(N_CORR),  .Q(C_CORR));
    FDRE #(.INIT(1'b0)) ff_WRONG (.C(clk_i), .R(1'b0), .CE(1'b1), .D(N_WRONG), .Q(C_WRONG));
    FDRE #(.INIT(1'b0)) ff_WIN   (.C(clk_i), .R(1'b0), .CE(1'b1), .D(N_WIN),   .Q(C_WIN));
    FDRE #(.INIT(1'b0)) ff_LOSE  (.C(clk_i), .R(1'b0), .CE(1'b1), .D(N_LOSE),  .Q(C_LOSE));

    // Pulsed control outputs:

    // load new target when we FIRST enter SHOW from IDLE
    // Page 3: 2. In each round, a random 4-bit binary value (the target number) is selected and displayed on the leftmost digit.
    assign load_target_o = (N_SHOW & ~C_SHOW);

    // reset the time counter whenever we enter any timed, post-decision state
    // Each term (N_STATE & ~C_STATE) becomes 1 for exactly one clock cycle
    // at the moment we *enter* that state, producing a clean synchronous reset pulse for the Time Counter.
    // Page 7: 3. FourSecs and TwoSecs: These signals are created using the output of the Time Counter module with some additional logic.
    assign reset_timer_o =
          (N_SHOW  & ~C_SHOW)       // entering SHOW → begin 2-second timer
        | (N_CORR  & ~C_CORR)       // entering CORR → begin 4-second "success" timer
        | (N_WRONG & ~C_WRONG);     // entering WRONG → begin 4-second "failure" timer

    // Page 3: 4. If an incorrect switch is flipped or no switch is flipped, then a point is lost and the led next to the correct switch flashes for four seconds.
    assign dec_score_o = (N_WRONG & ~C_WRONG);

    // Page 3: 5. If the correct switch is flipped then the current score flashes for two seconds, then it is incremented and flashes for two more seconds.
    assign inc_score_o = (N_CORR  & ~C_CORR);

    // Display control:

    // show target only while round is active (SHOW)
    assign show_target_o = C_SHOW;

    // flash score during CORR (correct result flash) and WIN
    assign flash_score_o = C_CORR | C_WIN;

    // flash the "correct" LED during WRONG (fail flash) and LOSE
    assign flash_led_o  = C_WRONG | C_LOSE;

endmodule
