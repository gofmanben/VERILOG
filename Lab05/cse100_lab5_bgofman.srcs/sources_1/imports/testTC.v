`timescale 1ns/1ps

module testTC();
    integer TX_ERROR = 0;

    reg  clkin;
    reg  btnU;
    reg  btnL;
    reg  btnR;
    wire [3:0]  an;
    wire [6:0]  seg;
    wire [15:0] led;

    top_lab5 top (
        .clkin(clkin),
        .btnU(btnU),
        .btnL(btnL),
        .btnR(btnR),
        .an(an),
        .seg(seg),
        .led(led)
    );

    // -------------------------
    // clock generator (100 MHz)
    // -------------------------
    parameter PERIOD = 10;
    parameter real DUTY_CYCLE = 0.5;
    parameter OFFSET = 2;
    initial begin
      #OFFSET
	  clkin = 1'b1;
      forever begin
        #(PERIOD-(PERIOD*DUTY_CYCLE)) clkin = ~clkin;
      end
    end

    wire [15:0] cnt_q = top.cnt16.Q_o;

    initial begin
        btnL = 1'b0;  // released
        btnR = 1'b0;  // released
        btnU = 1'b0;  // reset inactive (released)

        $display("\n=== RESET ===");
        #100 btnU = 1'b1;  // assert reset
        #100 btnU = 1'b0;  // deassert
        CHECK_CNT(16'd0);

        $display("\n=== TEST 1: Single L press (no change) ===");
        #100 btnL = 1'b1;  // press L   (Lonly)
        #100 btnL = 1'b0;  // release L (NONE)
        CHECK_CNT(16'd0);

        $display("\n=== TEST 2: Single R press (no change) ===");
        #100 btnR = 1'b1;  // press R   (Ronly)
        #100 btnR = 1'b0;  // release R (NONE)
        CHECK_CNT(16'd0);

        $display("\n=== TEST 3: L,R,R,L (no change) ===");
        #100 btnL = 1'b1;  // press L   (Lonly)
        #100 btnR = 1'b1;  // press R   (BOTH)
        #100 btnR = 1'b0;  // release R (Lonly)
        #100 btnL = 1'b0;  // release L (NONE)
        CHECK_CNT(16'd0);

        $display("\n=== TEST 4: R,L,L,R (no change) ===");
        #100 btnR = 1'b1;  // press R   (Ronly)
        #100 btnL = 1'b1;  // press L   (BOTH)
        #100 btnL = 1'b0;  // release L (Ronly)
        #100 btnR = 1'b0;  // release R (NONE)
        CHECK_CNT(16'd0);

        // Add brief dwells at BOTH and NONE so the FSM reliably hits DONE and emits the count pulse.
        $display("\n=== TEST 5: L,R,L,R (expect -1) ===");
        #100 btnL = 1'b1;  // press L   (Lonly)
        #100 btnR = 1'b1;  // press R   (BOTH)
        #100;              // dwell at BOTH
        #100 btnL = 1'b0;  // release L (Ronly)
        #100 btnR = 1'b0;  // release R (NONE)
        #100;              // dwell at NONE
        CHECK_CNT(16'hFFFF);

        $display("\n=== TEST 6: R,L,R,L (expect +1) ===");
        #100 btnR = 1'b1;  // press R   (Ronly)
        #100 btnL = 1'b1;  // press L   (BOTH)
        #100;              // dwell at BOTH
        #100 btnR = 1'b0;  // release R (Lonly)
        #100 btnL = 1'b0;  // release L (NONE)
        #100;              // dwell at NONE
        CHECK_CNT(16'd0);

        $display("\n=== TEST 7: R,L,R,L (expect +1) ===");
        #100 btnR = 1'b1;  // press R (Ronly)
        #100 btnL = 1'b1;  // press L (BOTH)
        #100;              // dwell at BOTH
        #100 btnR = 1'b0;  // release R (Lonly)
        #100 btnL = 1'b0;  // release L (NONE)
        #100;              // dwell at NONE
        CHECK_CNT(16'd1);
        
        $display("\n=== TEST 8: R,L,R,R,L,R (no change) ===");
        #100 btnR = 1'b1;  // press R (Ronly)
        #100 btnL = 1'b1;  // press L (BOTH)
        #100;              // dwell at BOTH
        #100 btnR = 1'b0;  // release R (Lonly)
        #100 btnR = 1'b1;  // press R (BOTH)
        #100 btnL = 1'b0;  // release L (Ronly)
        #100 btnR = 1'b0;  // release R (NONE)
        #100;              // dwell at NONE
        CHECK_CNT(16'd1);

        $display("\n=== TEST 9: L,R,L,L,R,L (no change) ===");
        #100 btnL = 1'b1;  // press R (Ronly)
        #100 btnR = 1'b1;  // press L (BOTH)
        #100;              // dwell at BOTH
        #100 btnL = 1'b0;  // release R (Lonly)
        #100 btnL = 1'b1;  // press R (BOTH)
        #100 btnR = 1'b0;  // release L (Ronly)
        #100 btnL = 1'b0;  // release L (NONE)
        #100;              // dwell at NONE
        CHECK_CNT(16'd1);

        $display("\n=== TEST 10: btnU reset (expect 0) ===");
        #100 btnU = 1'b1;  // assert reset
        #100 btnU = 1'b0;  // deassert
        CHECK_CNT(16'd0);

        // Summary
        if (TX_ERROR == 0)
            $display("\n=== ALL TESTS PASSED! ===");
        else
            $display("\n=== THERE WERE %0d TEST FAILURES ===", TX_ERROR);

        $finish;
    end

    // -------------------------
    // helper: counter check
    // -------------------------
    task CHECK_CNT;
        input [15:0] good_TC;
        begin
            #800; // settle
            if (cnt_q !== good_TC) begin
                TX_ERROR = TX_ERROR + 1;
                $display("[%0t] CNT FAIL: actual=%0d (0x%h), expect=%0d (0x%h)",
                         $time, cnt_q, cnt_q, good_TC, good_TC);
            end else begin
                $display("[%0t] CNT PASS: %0d (0x%h)", $time, cnt_q, cnt_q);
            end
        end
    endtask

    // -------------------------
    // live monitor (Debugging)
    // -------------------------    
    /*initial begin
      $monitor("t=%0t L=%b R=%b | Ls=%b Rs=%b | I=%b A=%b M=%b D=%b | up=%b dn=%b | dir=%b  count=%0d",
        $time, btnL, btnR, top.L_s, top.R_s, top.u_fsm.state_idle, top.u_fsm.state_armed, top.u_fsm.state_middle, 
        top.u_fsm.state_done, top.u_fsm.count_up, top.u_fsm.count_dn, top.u_fsm.dir_right, cnt_q);
    end*/

endmodule
