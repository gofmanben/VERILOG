`timescale 1ns/1ps
// Verilog code to test UTC and DTC of your 15 bit counter
// Fall 2022



module testTC();
  reg clkin, btnR, btnC, btnU, btnD, btnL;
  reg [15:0] sw;
  wire [15:0] led;
  wire [6:0] seg;
  wire [3:0] an;
  wire dp, UTC, DTC;
  
  reg [31:0] elapsed_time; // Difference between the current time and the last time
  
  top_lab3  // replace with your top level module's name
   UUT (
      .clkin(clkin),
      .btnR(btnR),
      .btnU(btnU),
      .btnD(btnD),
      .btnL(btnL),
      .btnC(btnC),
      .sw(sw),
      .seg(seg),
      .dp(dp),
      .led(led),
      .an(an)
      );   

integer TX_ERROR = 0;
    assign UTC = led[15];
    assign DTC = led[0];	

// Run this simulation for 3ms. If correct TX_ERROR should be 0 at the end.
// UTC should be high and then go low at 2,705us and go low at 2,706.3us.

    parameter PERIOD = 10;
    parameter real DUTY_CYCLE = 0.5;
    parameter OFFSET = 2;
	 

	initial    // Clock process for clkin
	begin
	  btnC = 1'bx;
	  btnR = 1'b0;
	  btnU = 1'bx;
	  btnD = 1'bx;
	  btnL = 1'bx;
    
       #OFFSET
		clkin = 1'b1;
       forever
         begin
            #(PERIOD-(PERIOD*DUTY_CYCLE)) clkin = ~clkin;
         end
	  end
	
	initial
	begin
     #2000;
     elapsed_time = $time; // Capture the current simulation time (ignoring the boot time)
	 btnC=1'b0;
	 btnU=1'b0;
	 btnD=1'b0;
	 btnL=1'b0;
	 btnR=1'b0;
	 sw = 16'h9034;
	 #200;
	 btnR = 1'b1;
	 #500 btnR = 1'b0;
	 #300 btnC=1'b1;
	 btnR = 1'b0;
	 #1330000 btnC=1'b0;
	 #200; btnU=1'b1;
	 #600; btnU=1'b0;
	 #200; btnU=1'b1;
	 #700; btnU=1'b0;
	 #200; btnU=1'b1;
	 #800; btnU=1'b0;
	 CHECK_UTC(1'b1); CHECK_DTC(1'b0);
	 #400;
	 CHECK_UTC(1'b1); CHECK_DTC(1'b0);
	 #200; 
	 btnU=1'b1;
	 #200; 
	 btnU=1'b0;
	 #100;
	 CHECK_UTC(1'b0); CHECK_DTC(1'b1);
	 #200; btnU=1'b0;
	 #200; btnU=1'b1;
	 #100;
	 CHECK_UTC(1'b0);  CHECK_DTC(1'b0);
	 #300 btnD=1'b1;
	 #200;

	 // Additional block for handling: wire dw_i = ~held_down & ~btnU & down_edge; 
	 CHECK_UTC(1'b0);  CHECK_DTC(1'b0);  // Changed DTC from 1 to 0: btnD ignored while btnU=1
	 #200; btnD=1'b0;                    // Release btnD
	 #200; btnU=1'b0;                    // Release btnU so btnD can take effect on the next press
     #200; btnD=1'b1;                    // Re-press btnD to create a clean down_edge
     #100;
     // End block 

	 CHECK_UTC(1'b0);  CHECK_DTC(1'b1);
	 #200; btnD=1'b0;
     #200; btnD=1'b1;
     #100;
	 CHECK_UTC(1'b1); CHECK_DTC(1'b0);
	 #200; btnD=1'b0;
     #200; btnD=1'b1;
     #100;
     CHECK_UTC(1'b0); CHECK_DTC(1'b0);
     #200; btnU=1'b0;
     #200; btnU=1'b1;
     #100;

     // Additional block for handling: wire up_i = (~held_down & ~btnD & up_edge) | up_hold
     CHECK_UTC(1'b0);  CHECK_DTC(1'b0);  // Changed UTC from 1 to 0: btnU ignored while btnD=1
	 #200; btnU=1'b0;                    // Release btnU
	 #200; btnD=1'b0;                    // Release btnD so btnU can take effect on the next press
     #200; btnU=1'b1;                    // Re-press btnU to create a clean up_edge
     #100;
     // End block

     CHECK_UTC(1'b1); CHECK_DTC(1'b0);
     #200; btnU=1'b0;
     #200; btnU=1'b1;
     #100;
     CHECK_UTC(1'b0); CHECK_DTC(1'b1);
     #100;
     
	end
	
	task CHECK_UTC;
        input good_TC;

        #0 begin
            if (good_TC !== UTC) begin
                TX_ERROR = TX_ERROR + 1;
                $display("[%0t - #%0d] UTC check FAILED: expected = %b, actual = %b (TX_ERROR = %0d)", 
                    $time, $time - elapsed_time, good_TC, UTC, TX_ERROR);
            end else begin
                $display("[%0t - #%0d] UTC check PASSED: expected = %b, actual = %b", 
                    $time, $time - elapsed_time, good_TC, UTC);
            end
        end
    endtask
    
	task CHECK_DTC;
        input good_TC;
    
       #0 begin
           if (good_TC !== DTC) begin
               TX_ERROR = TX_ERROR + 1;
               $display("[%0t - #%0d] DTC check FAILED: expected = %b, actual = %b (TX_ERROR = %0d)", 
                    $time, $time - elapsed_time, good_TC, DTC, TX_ERROR);
            end else begin
               $display("[%0t - #%0d] DTC check PASSED: expected = %b, actual = %b", 
                    $time, $time - elapsed_time, good_TC, DTC);
           end
           elapsed_time = $time; // set current time
       end
    endtask
        
endmodule

