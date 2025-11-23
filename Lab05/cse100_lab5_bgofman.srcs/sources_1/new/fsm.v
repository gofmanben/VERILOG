`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Gofman
// 
// Create Date: 11/01/2025 08:11:45 AM
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

/* 
Page 2: In this lab you will design another state machine. This time you will be using signals that could
be from two infrared light sensors to count the number of objects crossing the two sensors in both
directions. We'll be using pushbuttons as stand-ins for the sensor inputs. 
*/

module fsm (
  input wire clk_i,       // Page 6: The signal clk is your system clock.
  input wire L,           // 1 = unblocked, 0 = blocked
  input wire R,           // 1 = unblocked, 0 = blocked
  output wire count_up,   // 1-cycle pulse on L->R completion
  output wire count_dn,   // 1-cycle pulse on R->L completion
  output wire direction,  // 1 while attempting L->R
  output wire busy        // 1 while an attempt is in progress
);
  // State Machine
  // IDLE → STEP (Lonly/Ronly) → BOTH (maybe wrong_dir) → DONE (right_dir) → IDLE (NONE)

  // Sensor combinations (mapped to PDF pages)
  wire NONE  =  L &  R;  // Page 5: both sensors become unblocked again without a crossing
  wire BOTH  = ~L & ~R;  // Page 2: The sensors are close enough so that no object of interest fits in between the two sensors without blocking
  wire Lonly = ~L &  R;  // Page 4: should turn on in sequence repeatedly from left to right if the last crossing was left-to-right
  wire Ronly =  L & ~R;  // Page 4: and turn on repeatedly from right to left if that crossing was right-to-left

  // Direction register
  wire cur_direction;   // Remembers which cur_direction (left→right = 1, right→left = 0) was last detected

  // Helper singles relative to direction
  wire right_dir = (cur_direction & Ronly) | (~cur_direction & Lonly);  // Selects the sensor that should activate last for a valid crossing
  // Equivalent: wire right_dir = (cur_direction ? Ronly : Lonly);

  wire wrong_dir = (cur_direction & Lonly) | (~cur_direction & Ronly);  // Selects the sensor that activates incorrectly (same side we started on)
  // Equivalent: wire wrong_dir = (cur_direction ? Lonly : Ronly);

  // State definitions - one-hot encoding
  wire state_idle, state_step, state_both, state_done;  // Each represents a unique state; only one is active at a time

  // Illegal/no-state detector (for robust recovery)
  wire none_state = ~(state_idle | state_step | state_both | state_done);  // Detects if no valid state is active — used to reset FSM safely

  // IDLE: wait for a single; also recover from illegal and aborts
  // Page 3: We assume that there is no limit on how many times a turkey can change direction.
  wire next_idle =
      (state_done   & NONE)           |   // Go idle after a full crossing is finished
      (state_step   & NONE)           |   // Abort if attempt starts but no crossing occurs
      (state_both   & NONE)           |   // Abort if object disappears mid-crossing
      (state_idle   & ~Lonly & ~Ronly)|   // Stay idle while both sensors are unblocked
      (none_state);                       // Recover if FSM ever enters an invalid state

  // STEP: latched single until BOTH, or NONE aborts to IDLE
  // Page 3: The length of the low pulses depend on how fast the turkey is traveling.
  wire next_step =
      (state_idle  & (Lonly | Ronly))  |  // enter STEP on first single
      (state_step  & ~BOTH & ~NONE)    |  // stay STEP while exactly one sensor is blocked
      (state_done  & wrong_dir);          // cancel DONE → STEP if we reversed before NONE

  // reached BOTH; stay here on BOTH or the WRONG single; leave on NONE or RIGHT single
  // Page 3: But all of the turkeys are too wide to fit in between the sensors.
  wire next_both =
      (state_step & BOTH) |               // Enter once both sensors detect blockage
      (state_both & (BOTH | wrong_dir));  // Remain while both or wrong-side sensors stay active

  // DONE: only on RIGHT single; hold until NONE
  // Page 3: monitors the signals from the two IR sensors, and counts the number of objects that cross from right to left 
  // as well as the number of objects that cross from left to right.
  wire next_done =
        (state_both & right_dir) |         // Move to DONE when the opposite-side sensor clears last
        (state_done & ~NONE & ~wrong_dir); // Stay DONE until both sensors are unblocked or wrong_dir (cancel)
    
  // State flip-flops
  FDRE #(.INIT(1'b1)) _idle  (.C(clk_i), .CE(1'b1), .R(1'b0), .D(next_idle), .Q(state_idle));   // Holds IDLE state bit
  FDRE #(.INIT(1'b0)) _step  (.C(clk_i), .CE(1'b1), .R(1'b0), .D(next_step), .Q(state_step));   // Holds STEP state bit
  FDRE #(.INIT(1'b0)) _both  (.C(clk_i), .CE(1'b1), .R(1'b0), .D(next_both), .Q(state_both));   // Holds BOTH state bit
  FDRE #(.INIT(1'b0)) _done  (.C(clk_i), .CE(1'b1), .R(1'b0), .D(next_done), .Q(state_done));   // Holds DONE state bit

  // Page 3: One difficulty is that some objects (particularly turkeys) don't always know which way to go.
  wire next_direction = 
    ((state_idle & Lonly) & 1'b1) |                       // Force 1 when left triggers first
    ((state_idle & Ronly) & 1'b0) |                       // Force 0 when right triggers first
    ((~(state_idle & (Lonly | Ronly))) & cur_direction);  // Otherwise keep previous direction

  // Remembers the current crossing direction (used to decide count_up or count_dn)
  FDRE #(.INIT(1'b0)) _dir (.C(clk_i), .CE(1'b1), .R(1'b0), .D(next_direction), .Q(cur_direction));

  // Stores current DONE state into a delayed version each clock cycle
  wire prev_done;  // Tracks previous DONE state for edge detection
  FDRE #(.INIT(1'b0)) _prev_done (.C(clk_i), .CE(1'b1), .R(1'b0), .D(state_done), .Q(prev_done));  
  // Registers the previous DONE value to detect transitions

  // Page 3: So the waveforms observed might be more complicated if the object changes direction, perhaps multiple times, before completely crossing both sensors.
  wire leaving_done = prev_done & ~state_done;   // Detects when FSM exits DONE (one-shot pulse)
  wire commit       = leaving_done & NONE;       // commit only if the exit is to NONE

  // Output logic
  // Page 3: You will keep track of the difference using an up-down counter and display the difference
  assign count_dn  = commit & cur_direction;   // Pulse when crossing completes left→right (cur_direction = 1)
  assign count_up  = commit & ~cur_direction;  // Pulse when crossing completes right→left (cur_direction = 0)
  assign direction = cur_direction;            // Output direction bit for LED display
  assign busy      = state_step | state_both | state_done;  // High while a crossing is in progress

endmodule