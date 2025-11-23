`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  Martine
// 
// Create Date: 10/2/2023 07:29:02 PM
// Design Name: 
// Module Name: test_signchanger
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


module test_signchanger( ); // no inputs/outputs, this is a wrapper


// registers to hold values for the inputs to your top level
    //reg [15:0] sw; // WARNING: actual bit length 16 differs from formal bit length 8 for port 'sw'
    reg [7:0] sw;
    reg btnU, btnR, clkin;
// wires to see the values of the outputs of your top level
    wire [6:0] seg;
    wire [3:0] an;
    wire dp;
    //wire [15:0] led; // WARNING: actual bit length 16 differs from formal bit length 8 for port 'led'
    wire [7:0] led;
    
// create one instance of your top level
// and attach it to the registers and wires created above
    top_lab2 UUT (
     .sw(sw),
     .btnU(btnU),
     .btnR(btnR), 
     .clkin(clkin),
     .seg(seg),
     .an(an),
     .led(led),
     .dp(dp)
    );
    
    
// create an oscillating signal to impersonate the clock provided on the BASYS 3 board
    parameter PERIOD = 10;
    parameter real DUTY_CYCLE = 0.5;
    parameter OFFSET = 2;

    initial    // Clock process for clkin
    begin
        #OFFSET
		  clkin = 1'b1;
        forever
        begin
            #(PERIOD-(PERIOD*DUTY_CYCLE)) clkin = ~clkin;
        end
    end
	
// here is where the values for the registers are provided
// time must be advanced so that the change will have an effect
   initial
   begin
	 // add your test vectors here
	 // to set signal foo to value 0 use
	 // foo = 1'b0;
	 // to set signal foo to value 1 use
	 // foo = 1'b1;
	 //always advance time by multiples of 500ns
	 btnR=1'b0;
	 btnU=1'b0;
	 sw = 16'h0017;
	 // to advance time by 500ns use the following line
	 #500;
	 btnU=1'b1;
     #500;
     btnU=1'b0;
	 sw = 16'h00A0;
	 #500;
	 btnU=1'b1;
     #500;

// you will need to add more .... perhaps the values from Q4 in the prelab?
          
    // The binary addition of A + ~A + 1

    sw = 16'h0017;  // 0x17 = 0001_0111 (binary), 23₁₀, -23 (0xE9)
                    // 0001_0111 + 1110_1000 + 1 = 1110_1001 = 0xE9
    #500;
    btnU = 1'b1;
    #500;
    btnU = 1'b0;

    sw = 16'h00A0;  // 0xA0 = 1010_0000 (binary), -96₁₀, 96 (0x60)
                    // 1010_0000 + 0101_1111 + 1 = 01100000 = 0x60
    #500; 
    btnU = 1'b1;
    #500;
    btnU = 1'b0;

    sw = 16'h007F;  // 0x7F = 0111_1111 (binary), 127₁₀, -127 (0x81)
                    // 0111_1111 + 1000_0000 + 1 = 10000001 = 0x81
    #500;
    btnU = 1'b1;  
    #500;
    btnU = 1'b0;

    sw = 16'h001F;  // 0x1F = 0001_1111 (binary), 31₁₀, -31 (0xE1)
                    // 0001_1111 + 1110_0000 + 1 = 1110_0001 = 0xE1

    #500;
    btnU = 1'b1;
    #500;
    btnU = 1'b0;

    sw = 16'h00FF;  // 0xFF = 1111_1111 (binary), -1₁₀, 1 (0x01)
                    // 1111_1111 + 0000_0000 + 1 = 0000_0001 = 0x01
    #500;
    btnU = 1'b1;
    #500;
    btnU = 1'b0;

   end

endmodule
