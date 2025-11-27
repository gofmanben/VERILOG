### Lab Assignment 6

## Overview

[You will design and implement a version of the game ”Subway Slugging” using the BASYS3 board<br>
and the VGA monitor connected to it](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L12) |. [In this game, a slug must avoid trains traveling down tracks<br>
by jumping between the three tracks or hovering above the middle track](cse100_lab6_bgofman.srcs/sources_1/new/slug.v#L41) |. [A collision with a train ends<br>
the game and the number of trains the slug has avoided is the score](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L233) |. [The slug can only hover for a<br>
limited time](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L51) |. [Once the slug’s energy level, displayed on the left, reaches 0 the slug will drop](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L42).<br>

[Initially, the slug and the energy level bar are displayed, but no trains are present](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L151) |. [The score, initially 0](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L254) |,<br> [is displayed on AN1 and AN0](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L338) |. [Pressing btnC starts the game](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L85) |. [No other pushbutton has an effect<br>
before the game starts (except the global reset, btnD, of course)](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L52) |. [When the game starts the trains will<br>
start traveling down the tracks and pressing btnL/btnR](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L131) | [slides the slug one track to the left/right](cse100_lab6_bgofman.srcs/sources_1/new/slug.v#L60) |. [If<br>
the energy level is not 0 and the slug is in the middle, then the slug will hover while btnU is pressed](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L48) |.<br>
[But hovering will use up energy. The slug will drop as soon as btnU is released or the energy level is<br>
down to 0](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L45) |. [The slug should change color and flash while it is hovering](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L284) |. [While the slug is not hovering<br>
the energy level increases](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L46) |. [Each time a train passes the slug, a point is scored](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L253) |. [A crash occurs if the<br>
slug is not hovering and overlaps a train](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L234) |. [A crash ends the game, and when the game is over, the<br>
slug and all trains stop moving, and the slug flashes](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L285) |. [Only the global reset, btnD, will have an effect<br>
when the game is over](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L77) |. [Switch sw[3] will be a cheat switch that makes the slug immortal: it can go<br>
through trains without crashing](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L235).

## VGA controller

Read the section on the VGA Port in the **BASYS3 Board Reference Manual**. Do not use the<br>
circuit design shown there: it is asynchronous.<br>

[To control the monitor you must generate two control signals, Hsync and Vsync, as well as the 12](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L304) |<br>
[RGB data signals (vgaRed[3:0], vgaBlue[3:0], and vgaGreen[3:0]) for each of the screen’s 640 x<br>
480 pixels](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L305) |. [The value of these 12 signals are sent one at a time for each pixel](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L31) |, [row by row from left to<br>
right and top to bottom using one cycle of the 25MHz clock (provided to you) for each pixel](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L32).<br>

[There is also some time between rows and between frames](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L84) | [(after all 480 rows)](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L15) | [which allows the cathode<br>
ray to be re-positioned for the next row or frame](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L16) |. [The Hsync and Vsync signals are used by the<br>
monitor to ”synchronize” the start of each row and frame; they are low at fixed times between rows<br>
and frames](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L39). (Yes the monitors we will use are lcd displays, not cathode ray tubes. But the protocol<br>
used to communicate with these monitors is a standard that lives on.)<br>

[One way to think of this is to imagine that you have an 800 x 525 grid of pixels as shown below](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L61) |<br>
[(instead of the 640 x 480 pixels which correspond to the area you see on the monitor)](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L62) |. [This grid is<br>
traversed starting at the top left, location row 0, column 0](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L36) |. [Each row is traversed from left to right<br>
followed by the row immediately below it and so on](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L89) |. [The region of dimension 640 x 480 at the top<br>
left is the *Active Region*: the pixels in this region corresponds to pixels on the screen](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L43). The pixels<br>
outside this region correspond to time where the cathode ray would be off the screen. So the L-shaped<br>
region outside the active region is not part of the screen but represents the time needed between rows<br>
and frames in terms of pixels.<br>

[The value of the RGB data signals determine the color displayed for pixels in the Active Region](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L103) |, [with<br>
one cycle of the 25MHz clock corresponding to a pixel](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L104) |. [For a pixel outside the Active Region the<br>
12 RGB data signals should be low](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L109) |. [The horizontal synchronization signal (Hsync) should be low<br>
exactly for the 96 pixels in each row starting with the 656th pixel and high for the rest](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L68) |. [The vertical<br>
synchronization signal (Vsync) should be low exactly for all of the pixels in the 490th](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L70) | [and 491st rows<br>
and high for all pixels in all other rows](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L72) |. [So Hsync and Vsync are low in only the regions shaded pink<br>
and blue below, respectively](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L122) |. [The frame is continuously transmitted to the monitor to refresh the<br>
image. Transmitting one frame takes](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L123) | [800 x 525 x 40ns = 16,800,000ns = 16.8ms, so the monitor is<br>
being refreshed roughly 60 times per second: at 60Hz](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L124).<br>

## Game Requirements

Your implementation of Subway Slugging must meet each of the following requirements.<br>

[1. The playing area is the 640 x 480 screen](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L13).<br>
[2. The border along all 4 edges of the screen is white and 8 pixels wide](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L23).<br>
[3. The green bar indicating the slug’s energy level is near the left border](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L308) |. [It is 20 pixels wide](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L38) | [and<br>
192 pixels long at the maximum energy level](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L39).<br>
[4. There are three vertical tracks that are each 60 pixels wide](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L25) |. [They are not visible unless you <br>
choose to display them](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L104) |. [But the trains that will descend along these tracks will be visible](cse100_lab6_bgofman.srcs/sources_1/new/train.v#L60).<br>
[5. The tracks should be positioned in the right 2/3’s of the screen](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L37) | [with 10 pixels between adjacent
tracks](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L27).<br>
[6. The slug is a 16 by 16 pixel](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L20) | [yellow square](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L291) | [or a shape that fits in](cse100_lab6_bgofman.srcs/sources_1/new/slug.v#L24) | [this square and touches all 4 <br>
sides of the square](cse100_lab6_bgofman.srcs/sources_1/new/slug.v#L80) |. [The top edge of the slug is in row 360](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L21) | [and the slug is initially in the middle<br>
of the middle track](cse100_lab6_bgofman.srcs/sources_1/new/slug.v#L66).<br>
[7. The slug cannot move or change until the game starts (btnC is pressed)](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L48).<br>
[8. Pressing btnC will start the game](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L85) |, [but once the game is started btnC has no further effect](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L144).<br>
[9. During the game, the slug is either at rest, centered on one of the three tracks, or transitioning<br>
between two adjacent tracks](cse100_lab6_bgofman.srcs/sources_1/new/slug.v#L44).<br>
[10. Pressing btnR starts the transition to the adjacent track on the right (unless the slug is on the<br>
rightmost track)](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L140).<br>
[11. Pressing btnL starts the transition to the adjacent track on the left (unless the slug is on the<br>
leftmost track)](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L141).<br>
[12. The slug will move horizontally at 2 pixels per frame while it is transitioning](cse100_lab6_bgofman.srcs/sources_1/new/slug.v#L39).<br>
[13. Once a transition has started it will continue](cse100_lab6_bgofman.srcs/sources_1/new/slug.v#L78) | [unless the game ends (a crash occurs)](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L241).<br>
[14. Pressing btnL or btnR during a transition or while the slug is hovering has no effect](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L130).<br>
[15. Holding btnU down while the slug is centered on the middle track](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L175) | [and its energy level is not 0<br>
will cause the slug to hover](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L49).<br>
[16. The slug changes color while it is hovering](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L289).<br>
[17. When btnU is released or the slug’s energy level reaches 0, the slug stops hovering](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L54).<br>
[18. While the slug is hovering its energy decreases level by 1 every frame down to 0](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L50).<br>
[19. While the slug is not hovering its energy level increases by 1 every frame up to a maximum of 192](cse100_lab6_bgofman.srcs/sources_1/new/energy.v#L53).<br>
[20. Each track will have two trains](cse100_lab6_bgofman.srcs/sources_1/new/train.v#L89).<br>
[21. Pressing btnC opens the three tracks in the following order: the left track is first](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L35) |, [followed by](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L36) |<br>
[the right track 2 seconds later](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L61) |, [and finally the middle track 6 seconds after the right track](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L67).<br>
[22. When a track is opened, its first train with start](cse100_lab6_bgofman.srcs/sources_1/new/train.v#L90).<br>
[23. When a train starts, it will pick a random length](cse100_lab6_bgofman.srcs/sources_1/new/train.v#L37) |, [wait a random amount of time](cse100_lab6_bgofman.srcs/sources_1/new/train.v#L49) |, [and then<br>
descend at one pixel per frame until it is completely off the screen](cse100_lab6_bgofman.srcs/sources_1/new/train.v#L59).<br>
[24. Trains are 60 pixels wide](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L26).<br>
[25. When the bottom of either train reaches row 400 (440 for the middle track) the other train](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L32) |<br>
[will start in the same manner: picking a random length and waiting a random time before descending](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L80).<br>
[26. The two trains continually move down their track](cse100_lab6_bgofman.srcs/sources_1/new/train.v#L67) |, [restarting each other until the game ends](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L56).<br>
[27. When the top of the train reaches the row below the slug, a point is scored](cse100_lab6_bgofman.srcs/sources_1/new/track.v#L120).<br>
[28. The length of the train is 60 + B pixels](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L29) | [where B is a randomly selected number between 0 and 63](cse100_lab6_bgofman.srcs/sources_1/new/constants.vh#L30).<br>
[29. The random amount of wait time before descending is T frames where T is a randomly selected<br>
number between 0 and 127](cse100_lab6_bgofman.srcs/sources_1/new/train.v#L55).<br>
[30. A crash occurs whenever the slug is not hovering and it overlaps any train by at least 1 pixel](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L139).<br>
[31. If a crash occurs, the game is over: the trains stop moving](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L198) |, [the slug stops moving and flashes,<br>
and only btnD can have an effect](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L286).<br>
[32. When the game is over, pressing btnD will start a new game](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L90).<br>

## Module Overview

- [A new module generates the V/H coordinates (i.e. pixel address) of the current pixel](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L93) | (but likely<br>
will be composed of pre-existing modules)
- [A new module is needed to generate the V/Hsync signals](cse100_lab6_bgofman.srcs/sources_1/new/vga_controller.v#L40).
- [A new module is needed to produce the 16-bit RGB pixel data from the user input, the pushbuttons/switches,<br>
and the pixel address and manage gameplay](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L287). This may contain multiple modules itself,<br>
and may have similar components to Lab 4/5. You can reuse code from prior labs, but it must be your code.
- [The module labVGA clks is provided](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L75).
- [The RingCounter/Selector/hex7seg logic may be reused from prior labs, but it must be your own code](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L258).
- [While only two 7-segment displays are required](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L55) |, [you may find it useful to allow other<br>
information from your design to be displayed on the remaining two](cse100_lab6_bgofman.srcs/sources_1/new/lab6_top.v#L267).<br>
