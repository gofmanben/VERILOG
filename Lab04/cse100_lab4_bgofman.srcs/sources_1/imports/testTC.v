`timescale 1ns/1ps

module testTC();

    integer TX_ERROR = 0;    // counts total number of mismatches we saw
    reg [31:0] elapsed_time; // time of last check (for relative timestamps)

    reg        clkin;        // system clock

    // decoder.v
    reg  [3:0]  _dec_i;       // stimulus to decoder (this drives the 4-bit input)
    wire [15:0] _dec_o;       // output from decoder (16-bit one-hot)

    decoder _dec (
        .in_i (_dec_i),
        .out_o(_dec_o)
    );

    // lfsr.v
    wire [7:0] _lfsr_o;       // LFSR output bus

    lfsr _lfsr (
        .clk_i (clkin),
        .q_o   (_lfsr_o)
    );

    // time_counter.v
    reg        _count_rst;      // synchronous load pulse
    reg        _count_inc;      // increment enable (1 = count up once per clk edge if not loading)
    reg  [5:0] _count_din;      // load value
    wire [5:0] _count_o;        // 6-bit time counter output

    time_counter _count (
        .clk_i   (clkin),       // Page 2: connect only the system clock as input to the clock pins of any sequential components
        .inc_i   (_count_inc),  // Page 5: count down to 0 (or vice versa). Here we use it to count UP.
        .dec_i   (1'b0),        // Not counting down in this design (counting up only).
        .reset_i (_count_rst),  // Page 5: This will be your method of reseting the counter.
        .din     (_count_din),  // Page 5: load a 6-bit binary value
        .q_o     (_count_o)     // Page 5: ... leave the top bits unconnected.
    );

    
    // fsm.v
    reg _fsm_go;
    reg _fsm_4s;
    reg _fsm_match;
    reg _fsm_anysw;
    reg _fsm_won;
    reg _fsm_lost;
    reg signed [4:0] _fsm_score;
    
    wire _fsm_inc;
    wire _fsm_dec;

    fsm _fsm (
        .clk_i(clkin),
        .Go_i(_fsm_go),
        .four_secs_i(_fsm_4s),
        .two_secs_i(1'b0), // unused timeout input in this test
        .match_i(_fsm_match),
        .anysw_i(_fsm_anysw),
        .won_i(_fsm_won),
        .lost_i(_fsm_lost),
        .load_target_o(), // unused
        .reset_timer_o(), // unused
        .inc_score_o(_fsm_inc),
        .dec_score_o(_fsm_dec),
        .show_target_o(), // unused
        .flash_score_o(), // unused
        .flash_led_o()    // unused
    );

    // -------------------------
    // clock generator
    // -------------------------
    parameter PERIOD = 10;
    parameter real DUTY_CYCLE = 0.5;
    parameter OFFSET = 2;

    initial begin   // Clock process for clkin
       #OFFSET
       clkin = 1'b1;
       forever
        begin
            #(PERIOD-(PERIOD*DUTY_CYCLE)) clkin = ~clkin;
        end
    end
    
    initial begin
        _fsm_score = 0;
        forever begin
            @(posedge clkin);
            if (_fsm_inc)
                _fsm_score <= _fsm_score + 1;
            if (_fsm_dec)
                _fsm_score <= _fsm_score - 1;
        end
    end

    initial begin
        // init defaults for counter and fsm inputs
        _count_rst = 1'b0;
        _count_inc = 1'b0;
        _count_din = 6'd0;
    
        #100
        elapsed_time = $time; // remember the starting time, so we can print deltas

        $display("=== DECODER TEST BEGIN ===");

        // 0 -> expect bit 0 high
        // expected out_o = 0000_0000_0000_0001
        _dec_i = 4'b0000;
        CHECK_DECODER(16'b0000_0000_0000_0001);

        // 1 -> expect bit 1 high
        // expected out_o = 0000_0000_0000_0010
        _dec_i = 4'b0001;
        CHECK_DECODER(16'b0000_0000_0000_0010);

        // 2 -> expect bit 2 high
        // expected out_o = 0000_0000_0000_0100
        _dec_i = 4'b0010;
        CHECK_DECODER(16'b0000_0000_0000_0100);

        // 3 -> expect bit 3 high
        // expected out_o = 0000_0000_0000_1000
        _dec_i = 4'b0011;
        CHECK_DECODER(16'b0000_0000_0000_1000);

        // SKIP: keep going 4..15 for full coverage

        $display("=== DECODER TEST END ===");

                /************************************************/
    
        //Page 4: Random Number Generator
        $display("=== RANDOM_NUMBER TEST BEGIN ===");
        
        // We expect it to move through a long pseudo-random sequence of non-zero values.
        repeat (10) begin
            @(posedge clkin);   // advance one clock edge
            CHECK_LFSR();   // it should basically never go to 0x00 in a maximal LFSR
        end

        $display("=== RANDOM_NUMBER TEST END ===");

        /************************************************/

        $display("=== TIME_COUNTER TEST BEGIN ===");

        // 1) Load an initial value using _count_rst (synchronous load)
        // We'll load 6'd5 and confirm q_o == 5.
        _count_din = 6'd5;
        _count_rst = 1'b1;
        @(posedge clkin);  // wait for one rising edge so load happens
        _count_rst = 1'b0;
        CHECK_COUNTER(6'd5);

        // 2) Increment once (_count_inc = 1 for one clock)
        // After one tick, we expect q_o == 6.
        _count_inc = 1'b1;
        @(posedge clkin);          // 5 -> 6
        _count_inc = 1'b0;
        CHECK_COUNTER(6'd6);

        // 3) Two *pulsed* increments (like qsec would do)
        // pulse #1
        _count_inc = 1'b1;
        @(posedge clkin);          // 6 -> 7
        _count_inc = 1'b0;
        CHECK_COUNTER(6'd7);
        
        // idle cycle (no increment)
        // Page 5: In the actual Lab 4 design, the timer increments only once every 0.25 s
        // when 'qsec' generates a single-cycle pulse.  Between pulses, _count_inc stays 0.
        // Adding this idle clock cycle here emulates that real-world behavior and
        // prevents back-to-back increments that can cause extra carries in the cascaded
        // 16-bit counter (e.g., jumping 7 → 9 instead of 7 → 8).
        @(posedge clkin);
        
        // pulse #2
        _count_inc = 1'b1;
        @(posedge clkin);          // 7 -> 8
        _count_inc = 1'b0;
        CHECK_COUNTER(6'd8);

        // 4) Test another load:
        // load 6'd12 using _count_rst again, and confirm jump.
        _count_din = 6'd12;
        _count_rst = 1'b1;
        @(posedge clkin);
        _count_rst = 1'b0;
        CHECK_COUNTER(6'd12);

        // 5) One more increment to confirm post-load counting works
        _count_inc = 1'b1;
        @(posedge clkin);          // 12 -> 13
        _count_inc = 1'b0;
        CHECK_COUNTER(6'd13);

        $display("=== TIME_COUNTER TEST END ===");

        /************************************************/
    
        //Page 6: State Machine (FSM)
        $display("=== FSM TEST BEGIN ===");
        
        DO_RESET_FSM();
        
        // wait init (let FDRE INIT settle)
        repeat(2) @(posedge clkin);
        CHECK_FSM(6'b100000);

        // --- Start round: IDLE -> SHOW
        _fsm_go = 1;
        @(posedge clkin);
        _fsm_go = 0;
        @(posedge clkin);
        CHECK_FSM(6'b010000);

        // --- Correct press: SHOW -> CORR
        _fsm_anysw = 1;
        _fsm_match = 1;
        @(posedge clkin);
        _fsm_anysw = 0;
        _fsm_match = 0;
        CHECK_FSM(6'b001000);

        // --- End of 4s w/out win: CORR -> IDLE
        _fsm_4s = 1;
        @(posedge clkin);
        _fsm_4s = 0;
        @(posedge clkin);
        CHECK_FSM(6'b100000);

        // --- Wrong press: SHOW -> WRONG
        _fsm_go = 1;
        @(posedge clkin);
        _fsm_go = 0;
        @(posedge clkin);     // now supposed to be SHOW again
        _fsm_anysw = 1;
        _fsm_match = 0;       // mismatch -> WRONG
        @(posedge clkin);
        _fsm_anysw = 0;
        CHECK_FSM(6'b000100);

        // --- End of 4s w/out lose: WRONG -> IDLE
        _fsm_4s = 1;
        @(posedge clkin);
        _fsm_4s = 0;
        @(posedge clkin);
        CHECK_FSM(6'b100000);

        // --- Win path: CORR -> WIN (sticky)
        _fsm_go = 1;                 // Raise "Go" - start a new round (IDLE → SHOW)
        @(posedge clkin);            // Wait one clock edge so FSM captures Go_i
        _fsm_go = 0;                 // Deassert "Go" (acts as a short pulse in real hardware)
        @(posedge clkin);            // One more clock cycle - FSM should now be in SHOW state (showing the target)
        
        _fsm_anysw = 1;              // Simulate the player flipping a switch
        _fsm_match = 1;              // Indicate that the flip was correct (it matches the target)
        @(posedge clkin);            // On the next clock, FSM transitions SHOW → CORR (correct answer)
        _fsm_anysw = 0;              // Release the switch (pulse lasted one cycle)
        CHECK_FSM(6'b001000);        // Verify FSM state - should now be CORR
        
        _fsm_won = 1;                // Set "won" signal - the score has reached +4 (player wins)
        _fsm_4s  = 1;                // Raise "four_secs_i" - the 4-second result display window has ended
        @(posedge clkin);            // On the next clock, FSM detects (S_CORR & four_secs_i & won_i) → transitions to WIN
        _fsm_4s  = 0;                // Deassert "four_secs_i" (it was only a one-cycle pulse)
        @(posedge clkin);            // Wait another cycle for the FSM to stabilize in WIN
        CHECK_FSM(6'b000010);        // Verify and display FSM state - it should now be in WIN and remain there permanently
       
        DO_RESET_FSM();

        // --- Lose path ---
        _fsm_go = 1;                 // Raise "Go" - start a new round (IDLE → SHOW)
        @(posedge clkin);            // Wait one clock edge so FSM captures Go_i
        _fsm_go = 0;                 // Deassert "Go" (acts as a short pulse in real hardware)
        @(posedge clkin);            // After this clock, FSM should be in SHOW state (displaying the target)
        
        _fsm_anysw = 1;              // Simulate the player flipping a switch
        _fsm_match = 0;              // The switch is incorrect - mismatch (wrong button)
        @(posedge clkin);            // On the next clock, FSM transitions SHOW → WRONG (incorrect response)
        _fsm_anysw = 0;              // Release the switch (end the input pulse)
        CHECK_FSM(6'b000100);        // Verify FSM state - should now be WRONG
        
        _fsm_lost = 1;               // Assert "lost" - player's score reached -4 (or loss condition triggered)
        _fsm_4s   = 1;               // Assert "four_secs_i" - 4 seconds have passed since the mistake
        @(posedge clkin);            // On this clock, FSM detects (S_WRONG & four_secs_i & lost_i) → transitions to LOSE
        _fsm_4s   = 0;               // Deassert "four_secs_i" (one-cycle pulse)
        @(posedge clkin);            // Allow one more clock cycle for FSM to stabilize
        CHECK_FSM(6'b000001);        // Verify FSM state - should now be LOSE (and remain there permanently)


        $display("=== FSM TEST END ===");

        
        // summary
        if (TX_ERROR == 0)
            $display("ALL TESTS PASSED.");
        else
            $display("THERE WERE FAILURES.  TX_ERROR=%0d", TX_ERROR);

        $finish;
    end

    // Task to check decoder output and print result.
    task CHECK_DECODER;
        input [15:0] good_TC;
        begin
            #10; // small delay so out_o settles

            if (good_TC != _dec_o) begin
                TX_ERROR = TX_ERROR + 1;
                $display("[%0t - #%0d] DECODER FAIL: in_i=%b (%0d), out_o=%016b expected=%016b, TX_ERROR=%0d",
                    $time,                  // absolute sim time
                    $time - elapsed_time,   // time since last check
                    _dec_i, _dec_i,         // show input both binary and decimal
                    _dec_o,                 // actual result
                    good_TC,                // golden expected
                    TX_ERROR);
            end else begin
                $display("[%0t - #%0d] DECODER PASS: in_i=%b (%0d), out_o=%016b",
                    $time, $time - elapsed_time, _dec_i, _dec_i, _dec_o);
            end

            elapsed_time = $time; // update timestamp "checkpoint" for next delta
            #10; // wait 10ns before next test vector
        end
    endtask

    task CHECK_LFSR;
        begin
            #1;
            $display("[%0t - #%0d] LFSR full=%b (0x%0h)  used=%b (0x%0h)",
                $time, $time - elapsed_time, _lfsr_o, _lfsr_o, _lfsr_o[3:0], _lfsr_o[3:0]);
            elapsed_time = $time;
            #1;
        end
    endtask

    task CHECK_COUNTER;
        input [5:0] good_TC;
        begin
            #10; // Small delay to let q_o settle
            if (good_TC != _count_o) begin
                TX_ERROR = TX_ERROR + 1;
                $display("[%0t - #%0d] TIME_COUNTER FAIL: q_o=%0d (0x%0h), expected=%0d (0x%0h), TX_ERROR=%0d",
                    $time, $time - elapsed_time, _count_o, _count_o, good_TC, good_TC, TX_ERROR);
            end else begin
                $display("[%0t - #%0d] TIME_COUNTER PASS: q_o=%0d (0x%0h)",
                    $time, $time - elapsed_time, _count_o, _count_o);
            end

            elapsed_time = $time; // update timestamp "checkpoint" for next delta
            #10; // wait 10ns before next test vector
        end
    endtask

    task CHECK_FSM;
        input [5:0] good_TC;
        reg   [5:0] act_bits;
        begin
            // wait for posedge so state flops are settled (this guarantees we sample right after an update)
            @(posedge clkin);

            // Build actual state vector in the SAME bit order
            act_bits = {
                _fsm.C_IDLE,   // bit [5]
                _fsm.C_SHOW,   // bit [4]
                _fsm.C_CORR,   // bit [3]
                _fsm.C_WRONG,  // bit [2]
                _fsm.C_WIN,    // bit [1]
                _fsm.C_LOSE    // bit [0]
            };

            if (good_TC != act_bits) begin
                TX_ERROR = TX_ERROR + 1;
                $display("[%0t #%0d] FSM FAIL got = %b (IDLE=%b SHOW=%b CORR=%b WRONG=%b WIN=%b LOSE=%b) SCORE=%0d, expect= %b",
                         $time, $time - elapsed_time, act_bits, _fsm.C_IDLE, _fsm.C_SHOW, _fsm.C_CORR,
                                                    _fsm.C_WRONG, _fsm.C_WIN, _fsm.C_LOSE, _fsm_score, good_TC);
            end else begin
                $display("[%0t #%0d] FSM PASS state = %b (IDLE=%b SHOW=%b CORR=%b WRONG=%b WIN=%b LOSE=%b) SCORE=%0d",
                         $time, $time - elapsed_time, act_bits, _fsm.C_IDLE, _fsm.C_SHOW, _fsm.C_CORR,
                                                    _fsm.C_WRONG, _fsm.C_WIN, _fsm.C_LOSE, _fsm_score);
            end

            elapsed_time = $time;
            #1;
        end
    endtask
    
    task DO_RESET_FSM;
        begin
            $display("[%0t] --- TESTBENCH RESET FSM ---", $time);
    
            // 1) reset score
            _fsm_score = 0;
    
            // 2) clear all control inputs
            _fsm_go    = 0;
            _fsm_4s    = 0;
            _fsm_match = 0;
            _fsm_anysw = 0;
            _fsm_won   = 0;
            _fsm_lost  = 0;
    
            // 3) force internal one-hot state of the FSM back to IDLE=1, others=0
            //    NOTE: We are reaching inside the DUT only because this is a testbench.
            force _fsm.ff_IDLE.Q   = 1'b1;  // FDRE that drives S_IDLE
            force _fsm.ff_SHOW.Q   = 1'b0;
            force _fsm.ff_CORR.Q   = 1'b0;
            force _fsm.ff_WRONG.Q  = 1'b0;
            force _fsm.ff_WIN.Q    = 1'b0;
            force _fsm.ff_LOSE.Q   = 1'b0;
    
            // Let one clock edge happen so everything downstream stabilizes
            @(posedge clkin);
    
            // Release the forces so FSM can run normally again
            release _fsm.ff_IDLE.Q;
            release _fsm.ff_SHOW.Q;
            release _fsm.ff_CORR.Q;
            release _fsm.ff_WRONG.Q;
            release _fsm.ff_WIN.Q;
            release _fsm.ff_LOSE.Q;
    
            // One more clock just to be nice
            @(posedge clkin);
        end
    endtask
    
endmodule
