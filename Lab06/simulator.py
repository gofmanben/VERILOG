# -*- coding: utf-8 -*-
# -----------------------------------------------------------------------------
# Verilog → Python simulator
# -----------------------------------------------------------------------------

import pygame
import numpy as np

# Non-vectorized, per-pixel version (easy to debug but very slow)  
DEBUG = False
# draw borders around track sections
SHOW_SECTION = False

# ----------------- Colors -----------------
AREA_RGB      = (255, 255, 255)  # border → white  Page 4: The border along all 4 edges of the screen is white
ENERGY_RGB    = (0, 255, 0)      # energy → green  Page 4: The green bar indicating the slug's energy level
LIVE_RGB      = (255, 255, 0)    # live   → yellow Page 3. The slug should change color 
TRAIN_RGB     = (0, 0, 255)      # train  → blue
RAILS1_RGB    = (102, 51, 17)    # rails  → brown
RAILS2_RGB    = (10, 51, 255)    # rails  → blue

COLOR_HUD_TXT = (220, 220, 220)

# Section border colors (timing verified)
BORDER_SEC0   = (0, 255, 255)    # section 0 bands
BORDER_SEC1   = (255, 0, 255)    # section 1 bands

# ----------------- constants.vh -----------------

# Page 4: 1. The playing area is the 640 x 480 screen.
H_RES = 640     # visible horizontal pixels - shown on screen
V_RES = 480     # visible vertical lines - shown on screen
                          # Page 3: There is also some time between rows and between frames (after all 480 rows) 
                          # which allows the cathode ray to be re-positioned for the next row or frame.

FREQ_HZ        = 60        # Page 4: the monitor is being refreshed roughly 60 times per second: at 60Hz.
SLUG_SIZE      = 16        # Page 4: 6. The slug is a 16 by 16 pixel yellow square (or a shape that fits in this square and touches all 4 sides of the square).
SLUG_TOP_ROW   = 360       # Page 4: The top edge of the slug is in row 360 and the slug is initially in the middle of the middle track.

BORDER         = 8        # Page 4: 2. The border along all 4 edges of the screen is white and 8 pixels wide.

TRACK_H        = 60        # Page 4: There are three vertical tracks that are each 60 pixels wide.
                                    # Page 5: Trains are 60 pixels wide.
TRACK_GAP      = 10        # Page 4: with 10 pixels between adjacent tracks.

MIN_TRAIN_V    = 60        # Page 5: The length of the train is 60 + B pixels 
MAX_TRAIN_V    = 123       # where B is a randomly selected number between 0 and 63.

# Page 5: 25. When the bottom of either train reaches row 400 (440 for the middle track) the other train'
# will start in the same manner: picking a random length and waiting a random time before descending.
ROW_HEIGHT    = 400                # total used vertical height for one section
ROW_GAP       = (440 - ROW_HEIGHT) # using 40 px gap between trains/sctions for maneuvering slug (16 px)

# Page 4: 5. The tracks should be positioned in the right 2/3's of the screen with 10 pixels between adjacent tracks.
MIDDLE_LINE = H_RES - (H_RES // 3)   # in the right 2/3's of the screen
LEFT_LINE   = MIDDLE_LINE - TRACK_H - TRACK_GAP  # center of left lane
RIGHT_LINE  = MIDDLE_LINE + TRACK_H + TRACK_GAP  # center of right lane

# ----------------- countUD16L.v -----------------

class countUD16L:
    # 16-bit Counter – Built by cascading four countUD4L modules.
    def __init__(self, Din_i=0):
        self.up_i = 0       # Lab03. Page 3: Increment input port         (btnU)
        self.dw_i = 0       # Lab03. Page 3: Decrement input port         (btnD)
        self.ld_i = 0       # Lab03. Page 3: Load control input port (Load enable when 1, load Din_i on the next clock edge)      (btnL)
        self.Din_i = Din_i  # Data input port (16-bit), that will be loaded into the counter on the positive clock edge if ld_i is high (sw[15:0])
        self.Q_o = Din_i    # Lab03. Page 3: Your 16-bit counter will have the same ports as the 4-bit counters except that its input and port ports will be 16-bit vectors.
    
    def tick(self, up_i=False, dw_i=False, ld_i=False, Din_i=0):
        if ld_i:
            self.Q_o = Din_i
        else:
            if up_i and not dw_i:
                self.Q_o = (self.Q_o + 1)
            elif dw_i and not up_i:
                self.Q_o = (self.Q_o - 1)

# ----------------- lfsr.v -----------------

class lfsr:
    # Module Name: lfsr (8-bit LFSR)
    # taps (8,6,5,4) -> x^8 + x^6 + x^5 + x^4 + 1
    def __init__(self, seed):
        self.q = seed & 0xFF
    
    def tick_clk(self):
        fb = ((self.q >> 7) ^ (self.q >> 5) ^ (self.q >> 4) ^ (self.q >> 3)) & 1
        self.q = ((self.q << 1) & 0xFF) | fb
        return self.q


# ----------------- vga_controller.v -----------------

# Page 3: for each of the screen's 640 x 480 pixels. The value of these 12 signals are sent one at a time for each pixel, 
# row by row from left to right and top to bottom using one cycle of the 25MHz clock (provided to you) for each pixel.
class vga_controller:
    def __init__(self):
        self.x          = 0   # Current pixel X position (0-639 when active)
        self.y          = 0   # Current pixel Y position (0-479 when active)
        self.frame_tick = 1   # 1-cycle pulse on Vsync rising edge (happens in blanking, not active)
        self.fb = None        # vectorized via shared geometry

    def isActive(self):     # 1-cycle pulse on Vsync rising edge (happens in blanking, not active)
        active = self.frame_tick
        self.frame_tick = 1
        return active
    
    def draw(self, mask, color):
        if isinstance(mask, np.ndarray):
            self.fb[mask] = color
        elif mask:
            self.fb[self.y, self.x] = color

    def tick(self):
        if not DEBUG:
            x = np.arange(H_RES, dtype=np.int32)[None, :]
            y = np.arange(V_RES, dtype=np.int32)[:, None]
            self.frame_tick = 0
            return x, y

        hcnt = self.x
        vcnt = self.y

        # Page 2: One way to think of this is to imagine that you have an 800 x 525 grid of pixels as shown below
        # (instead of the 640 x 480 pixels which correspond to the area you see on the monitor).
        H_TOTAL   = H_RES # + H_FRONT + H_SYNC + H_BACK; // total pixels per line  (800 pixels)
        V_TOTAL   = V_RES # + V_FRONT + V_SYNC + V_BACK; // total lines per frame  (525 pixels)

        STEP = 1;   # +1 step
        ZERO = 0;   # reset value (column/row 0)

        end_of_line  = (hcnt == (H_TOTAL - STEP)); # last horizontal pixel (hcnt == 799)
        end_of_frame = (vcnt == (V_TOTAL - STEP)); # last vertical line  (vcnt == 524)

        # Page 2: Each row is traversed from left to right followed by the row immediately below it and so on.
        hcnt_next = ZERO if end_of_line else (hcnt + STEP)
        
        if end_of_line and end_of_frame:
            vcnt_next = ZERO            # If last pixel of last line → start new frame
        elif end_of_line:
            vcnt_next = (vcnt + STEP)   # If line ended (but not frame) → next line
        else:
             vcnt_next = vcnt           # Otherwise → hold during the line

        # Page 7: 8. There is no qsec signal provided for this lab. Do not try to use the qsec clks module. Instead
        # the frame signal mentioned above, which is high for one cycle per frame, can be used as the up (or down) input of a counter.
        self.frame_tick = not (end_of_line and end_of_frame)
      
        self.x = hcnt_next
        self.y = vcnt_next
        return self.x, self.y

# ----------------- area.v -----------------

class area:
    # Module Name: area
    def __init__(self):
        self.border_o = False  # 1 when current pixel is within border area

    def tick(self, x, y):
        # Assert border_o if the pixel is within the border region
        self.border_o = ((x < BORDER) | (x >= (H_RES - BORDER)) |  # inside horizontal span
                         (y < BORDER) | (y >= (V_RES - BORDER)))   # inside vertical span
        return self.border_o

# ----------------- slug.v -----------------

class slug:
    #  Page 4: 6. The slug is a 16 by 16 pixel yellow square (or a shape that fits in this square and touches all 4
    # sides of the square). The top edge of the slug is in row 360 and the slug is initially in the middle of the middle track.
    def __init__(self):
        self.freeze   = False   # Page 4: 7. The slug cannot move or change until the game starts (btnC is pressed).
        self.position = 0       # expects -1 (left), 0 (middle), +1 (right) - two's complement
        self.busy_o   = False   # high while the slug is animating toward the target lane center
        self.slug_o   = False   #  1 when (x,y) is inside the slug's 16x16 box

        self.cur_x = 0          # current animated x-center of the slug

    def tick(self, x, y, pos_s):
        # Constants
        STEP_PX = 2;            # Page 4: 12. The slug will move horizontally at 2 pixels per frame while it is transitioning.

        # Page 3: In this game, a slug must avoid trains traveling down tracks by jumping between the three tracks or hovering above the middle track.
        self.position = pos_s;  # alias as signed value for clarity
    
        # Page 4: 9. During the game, the slug is either at rest, centered on one of the three tracks, or transitioning between two adjacent tracks.
        if pos_s == 0:
            target_x = MIDDLE_LINE  # 0 → middle
        # Page 4: 11. Pressing btnL starts the transition to the adjacent track on the left (unless the slug is on the leftmost track).
        elif pos_s <  0:
            target_x = LEFT_LINE   # -1 → left
        # Page 4: 10. Pressing btnR starts the transition to the adjacent track on the right (unless the slug is on the rightmost track).
        else:
            target_x = RIGHT_LINE  # +1 → right

        # ---------------- Animation control ----------------
        cur_x = self.cur_x;      # current animated x-center of the slug
  
        # This ensures the subtraction works correctly and doesn't overflow when cur_x > target_x.
        diff = target_x - cur_x  # Compute signed difference between target and current X positions.
        if diff >  STEP_PX:
            step = STEP_PX       #move right by STEP_PX
        elif diff < -STEP_PX:
            step = -STEP_PX      #move left  by STEP_PX
        else:
            step = diff;         #final small step
                           
        moved = cur_x + step;    # cur_x ± step toward target_x
        if self.freeze and cur_x == 0:
            next_x = MIDDLE_LINE # initial snap-to-middle
        elif self.freeze:
            next_x = cur_x       # stay frozen
        else:
            next_x = moved       # move toward target

        cur_x = next_x
        self.cur_x = cur_x

        # ---------------- Bounding box & pixel flag ----------------
        slug_x0 = cur_x - (SLUG_SIZE >> 1)               # left edge of slug box
        slug_x1 = slug_x0 + SLUG_SIZE                    # right edge (exclusive)
        slug_y0 = SLUG_TOP_ROW                           # top edge (fixed)
        slug_y1 = (SLUG_TOP_ROW + SLUG_SIZE)             # bottom edge (exclusive)
  
        self.busy_o = (cur_x != target_x)                # animating until centers match

        # Assert slug_o if the pixel is within the slug region
        self.slug_o = ((x >= slug_x0) & (x < slug_x1) &  # inside horizontal span
                       (y >= slug_y0) & (y < slug_y1))   # inside vertical span
        
        return self.slug_o
    
# ----------------- energy.v -----------------

class energy:
    # Page 7: (d) Display the energy level bar.
    def __init__(self):
        self.freeze    = False    # Page 4: 8. Pressing btnC will start the game, but once the game is started btnC has no further effect.
        self.hovering  = False    # btnU: 1 (energy decreases), 0 (energy increases)
                                  # Page 5: Holding btnU down while the slug is centered on the middle track and its energy level is not 0 will cause the slug to hover.
        self.hovering_o = False   # Page 4: 192 pixels long at the maximum energy level
        self.energy_o   = False   # High when (x,y) lies inside the green bar region

        self.level_c  = 0

    def tick(self, x, y):
        # ---------------- Constants ----------------
        BAR_W     = 20   # Page 4: It is 20 pixels wide
        MAX_LEVEL = 192  # and 192 pixels long at the maximum energy level.
        PAD       = 10   # Gap between border and energy bar

        # Page 3: Once the slug's energy level, displayed on the left, reaches 0 the slug will drop.
        level_c, level_n = self.level_c, 0

        # Page 3: But hovering will use up energy. The slug will drop as soon as btnU is released or the energy level is down to 0.
        # Page 3: While the slug is not hovering the energy level increases.
        if self.freeze:
            level_n = MAX_LEVEL         # Page 3: If the energy level is not 0 and the slug is in the middle, then the slug will hover while btnU is pressed.
        elif self.hovering and level_c > 0: 
            level_n = level_c - 1       # Page 3: But hovering will use up energy.  (decreasing bar)
        elif not self.hovering and level_c < MAX_LEVEL:
            level_n =  level_c + 1      # Page 3: The slug will drop as soon as btnU is released or the energy level is down to 0. (increasing bar)
        else:
            level_n =  level_c          # Page 5: 17. When btnU is released or the slug's energy level reaches 0, the slug stops hovering.                                                   

        # Level register (updated once per frame)
        self.level_c = level_n

        # Page 4: 3. The green bar indicating the slug's energy level is near the left border.
        x0 = BORDER + PAD                     # left edge
        x1 = x0 + BAR_W                       # right edge (exclusive)
        y_bottom = BORDER + PAD + MAX_LEVEL   # fixed bottom
        y_top    = y_bottom - level_c         # dynamic top moves upward

        # Assert energy_o if the pixel is within the bar region
        self.energy_o = ((x >= x0) & (x < x1) &               # inside horizontal span
                         (y >= y_top) & (y < y_bottom))       # inside vertical span

        # Page 3: Once the slug's energy level, displayed on the left, reaches 0 the slug will drop.
        self.hovering_o = not self.freeze and self.hovering and (level_c > 0); # expose energy level to other modules

        return self.energy_o

# ----------------- track.v -----------------

class track:
    # Page 7: (g) Next you should work on one track. Please make a separate module for a track.
    def __init__(self):
        self.freeze      = False   # Page 4: 7. The slug cannot move or change until the game starts (btnC is pressed).
        self.next_live   = False   # Page 9: You may decide if the game coninues when a life is lost or if the game pauses when a life is lost
        self.trains_o    = False   # 1 => current pixel is on any active train,
        self.end_train_o = False   # 1 => when the current pixel is the bottom-right corner of the any train sprite

        # ----------------------- start-after-delay (in frames) -----------------------
        self._start_delay = countUD16L(0)            # frame counter for start delay
        
        # ----------------------- Motion generators for two rows ----------------------
        self._count_0     = countUD16L(0)
        self._count_1     = countUD16L(0)

        self._rnd0 = lfsr(0xA5)  # Random source for section 1 (train heights/positions)
        self._rnd1 = lfsr(0x3C)  # Random source for section 2 (train heights/positions)
        
        self.random0_c = self.random1_c = self.cursor_y0 = self.cursor_y1 = 0

    def tick(self, x, y):
        # Page 5: 21. Pressing btnC opens the three tracks in the following order: the left track is first, 
        # followed by the right track 2 seconds later, and finally the middle track 6 seconds after the right track.
        DELAY_1 = 2               # the left track is first, followed by the right track 2 seconds later
        DELAY_2 = DELAY_1 + 6     # the middle track 6 seconds after the right track.
        DELAY_3 = DELAY_2 + 7     # disable start delay count after 15 seconds (2 + 6 + 7 = 15)

        if not self.freeze and self._start_delay.Q_o  < (DELAY_3 * FREQ_HZ): # start increment after btnC pressed and stop incrementing after 15 seconds (cap)
            self._start_delay.tick(up_i=True)
        start_delay = self._start_delay.Q_o

        # Page 7: You'll need a timer for the staggered track opening and to make things flash.
        if not self.freeze and start_delay >= DELAY_1 * FREQ_HZ: # Page 5: the left track is first, followed by the right track 2 seconds later
            self._count_0.tick(up_i=True)

        if not self.freeze and start_delay >= DELAY_2 * FREQ_HZ: # Page 5: the middle track 6 seconds after the right track
            self._count_1.tick(up_i=True)

        # Use 11 signed bits because vertical math (R*_Y*) can go slightly negative (≈ -286) when trains are offscreen at the top, 
        # and positive up to ≈ +879. 11 bits (-1024..+1023) safely covers this full range; signed compare prevents wrap.
        self.cursor_y0 = self._count_0.Q_o  # visible 0..~900 range, signed for geometry arithmetic
        self.cursor_y1 = self._count_1.Q_o  # identical reasoning for the second baseline

        # Page 5: 25. When the bottom of either train reaches row 400 (440 for the middle track)
        reset_0 = (self.cursor_y1 == ROW_HEIGHT)      # reset first cursor y position after the first section reaches 400 px
        reset_1 = (self.cursor_y0 == ROW_HEIGHT       # reset second cursor y position after the first section reaches 400 px
                   and start_delay >=  DELAY_3 * FREQ_HZ)            # enable after first rotation ("only after 15 s")

        if self.next_live       : self._start_delay.tick(ld_i=True)
        if self.next_live or reset_0: self._count_0.tick(ld_i=True)  # .ld_i  (next_live | reset_0), .Din_i (16'd0)
        if self.next_live or reset_1: self._count_1.tick(ld_i=True)  # .ld_i  (next_live | reset_1), .Din_i (16'd0)
        self.next_live = False

        if reset_0 or (start_delay == DELAY_1 * FREQ_HZ):       # Page 5: 23. When a train starts, it will pick a random length, wait a random amount of time.
            self.random0_c = self._rnd0.tick_clk() & 0x3F       # Random source for section 1 (train heights/positions)

        if reset_1 or (start_delay == DELAY_2 * FREQ_HZ):       # Page 5: 23. When a train starts, it will pick a random length, wait a random amount of time.
            self.random1_c = self._rnd1.tick_clk() & 0x3FF      # Random source for section 2 (train heights/positions)

        # Trains 0-2 belong to the first section (row0_*), 
        train0, score0 = train(0).tick(self.random0_c, x, y, self.cursor_y0)
        train1, score1 = train(1).tick(self.random0_c, x, y, self.cursor_y0)
        train2, score2 = train(2).tick(self.random0_c, x, y, self.cursor_y0)

        # Trains 3-5 to the second section (row1_*).
        train3, score3 = train(0).tick(self.random1_c, x, y, self.cursor_y1)
        train4, score4 = train(1).tick(self.random1_c, x, y, self.cursor_y1)
        train5, score5 = train(2).tick(self.random1_c, x, y, self.cursor_y1)

        # ------------------------------- Final Output ---------------------------------
        # Combine all trains: if any is active at this pixel, output logic high (1)
        self.trains_o = (train0 | train1 | train2 | train3 | train4 | train5)

        # Page 5: 27. When the top of the train reaches the row below the slug, a point is scored.
        self.end_train_o = score0 | score1 | score2 | score3 | score4 | score5; # High on any frame where at least one train's top is at the scoring row

        return self.trains_o

# ----------------- train.v -----------------

class train:
    def __init__(self, idx):
        self.idx     = idx    # current train index (0=left, 1=middle, 2=right)
        self.train_o = False  # 1 => current pixel is on any active train
        self.score_o = False  # 1 when top of this train reaches row below slug

    def tick(self,  random,     # pseudo-random value for height and position calculation
                    x,          # current pixel x from VGA pipeline
                    y,          # current pixel y from VGA pipeline
                    cursor_y):  # vertical baseline (moves 1 px/frame)
        # Signed compare: y is 0..479; cast to signed to avoid unsigned wrap vs negative bounds.
        y_s = y
  
        # --------------------------- Train Height Generation ---------------------------
        # wire [5:0]  slice_0    = random[5 + idx -: 6];
        slice_0 = (random >> self.idx) & 0x3F        # For idx=0 → [5:0], idx=1 → [6:1], idx=2 → [7:2].  Max value = 6'b111111 (=63)
        # wire [5:0]  slice_1    = random[6 + idx -: 6];
        slice_1 = (random >> (1 + self.idx)) & 0x3F  # For idx=0 → [6:1], idx=1 → [7:2], idx=2 → [8:3].  Max value = 6'b111111 (=63)

        # ----------------------------- Train heights -----------------------------
        height_0 = MIN_TRAIN_V + slice_0   # Height of row-0 train (range 60..123)
        height_1 = MIN_TRAIN_V + slice_1   # Height of row-1 train (range 60..123)

        # Available vertical placement window for each row
        avail_0 = MAX_TRAIN_V - height_0   # Remaining free space above row-0 (0..63)
        avail_1 = MAX_TRAIN_V - height_1   # Remaining free space above row-1 (0..63)

        # Page 5: 23. When a train starts, it will pick a random length, wait a random amount of time,
        #   random_x * (avail_x + 1) produces a 12-bit number,
        #   where the upper 6 bits implement   floor( random_x * (avail+1) / 64 )
        # wire [11:0] prod0 = random[5:0] * (avail_0 + 6'd1);
        prod0 = (random & 0x3F)        * (avail_0 + 1)  # Random offset candidate for row-0 (0..63 scaled)
        # wire [11:0] prod1 = random[7:2] * (avail_1 + 6'd1);
        prod1 = ((random >> 2) & 0x3F) * (avail_1 + 1)  # Independent random offset candidate for row-1'
        
        # Page 5: 29. The random amount of wait time before descending is T frames where T is a randomly selected number between 0 and 127.
        # wire [5:0] off0 = prod0[11:6];
        off0  = (prod0 >> 6) & 0x3F      # Vertical offset for row-0 within its allowed range
        # wire [5:0] off1 = prod1[11:6]; 
        off1  = (prod1 >> 6) & 0x3F      # Vertical offset for row-1 within its allowed range

        # Page 5: 23 ... and then descend at one pixel per frame until it is completely off the screen.
        y0_0 = cursor_y - off0;                           # Bottom of row-0 rectangle, shifted downward by offset
        y0_1 = y0_0 - height_0;                           # Top of row-0 rectangle

        # Page 5: picking a random length and waiting a random time before descending.
        y1_0 = cursor_y - MAX_TRAIN_V - ROW_GAP - off1;   # Bottom of row-1 rectangle
        y1_1 = y1_0 - height_1;                           # Top of row-1 rectangle

        # Page 5: 26. The two trains continually move down their track, restarting each other until the game ends.
        row0 = (y_s >= y0_1) & (y_s <= y0_0);                          # Current pixel is inside row-0 train band
        row1 = (y_s >= y1_1) & (y_s <= y1_0);                          # Current pixel is inside row-1 train band

        # -------------------- Horizontal lane geometry (right 2/3) ---------------------
        HALF_TRAIN = TRACK_H >> 1;                                          # Half of the track width (60 >> 1 = 30)
        x0_0 = LEFT_LINE   - HALF_TRAIN
        x0_1 = LEFT_LINE   + HALF_TRAIN  # left lane edges
        x1_0 = MIDDLE_LINE - HALF_TRAIN
        x1_1 = MIDDLE_LINE + HALF_TRAIN  # middle lane edges
        x2_0 = RIGHT_LINE  - HALF_TRAIN
        x2_1 = RIGHT_LINE  + HALF_TRAIN  # right lane edges

        # -----------------------------------------------------------------------------
        # FSM 'psedo' pattern → 3-bit control used to decide which row each train uses
        # r[0] → controls train 0 (idx = 0)
        # r[1] → controls train 1 (idx = 1)
        # r[2] → controls train 2 (idx = 2)
        # -----------------------------------------------------------------------------
        # wire [2:0] r = random[2:0];
        r = random & 0x7 # Extract 3 least-significant bits from random
        
        # Handle edge cases where all bits are 0 (000) or all 1 (111)
        if   r == 0b000: fix_r = 0b100  # 000 → 100 (only train 3 uses row1)
        elif r == 0b111: fix_r = 0b001  # 111 → 001 (only train 1 uses row1)
        else:            fix_r = r      # 110, 101, 011  → Page 4. 20. Each track will have two trains.
                                        # or 100, 010, 001 → Page 4. 22. When a track is opened, its first train with start.
        
        # Determine whether this particular train instance uses row1
        # r[0]→train0, r[1]→train1, r[2]→train2 (Verilog-style)
        use_row1 = ((fix_r >> self.idx) & 1) != 0

        # Select the active vertical band (row0 or row1) based on the flag above.
        row_mask = row1 if use_row1 else row0;  # row_mask = 1 means the current pixel (x, y) is inside the visible band of whichever row this train occupies.

        # Select lane by idx: 0->left, 1->middle, else->right
        if self.idx == 0:
            self.train_o = (row_mask & (x > x0_0) & (x < x0_1))  # the current pixesl inside sprite for left-lane train
        elif self.idx == 1:
            self.train_o = (row_mask & (x > x1_0) & (x < x1_1))  # the current pixesl inside sprite for middle-lane train
        else:
             self.train_o = (row_mask & (x > x2_0) & (x < x2_1)) # the current pixesl inside sprite for right-lane train
                
        # Page 5: 27. When the top of the train reaches the row below the slug, a point is scored.
        train_top = y1_1 if use_row1 else y0_1
        self.score_o = (train_top == (SLUG_TOP_ROW + SLUG_SIZE))

        return self.train_o, self.score_o
    
# ----------------- rails.v ----------------

class rails:
    def __init__(self):
        self.rails_o = False  # High when (x,y) lies inside any rail region

    def tick(self, x, y):
        # Geometry constants for the rails
        RAIL_WIDTH = 1   # Width of each rail in pixels (1 pixel wide)
        RAIL_GAP   = 8   # Distance from track center to each rail
        TIE_WIDTH  = 4   # Width of each tie (crossbeam)
        TIE_GAP    = 10  # Vertical spacing between ties;

        # Track geometry
        HALF_TRAIN = TRACK_H >> 1          # Half of the track width; e.g., 60 >> 1 = 30
        margin     = HALF_TRAIN - RAIL_GAP # Horizontal offset from the track center to each rail line:

        # Compute X positions for left-side rails (one for each lane)
        x0 = LEFT_LINE   - margin    # X of the left rail in the left lane  (center minus margin)
        x1 = MIDDLE_LINE - margin    # X of the left rail in the middle lane
        x2 = RIGHT_LINE  - margin    # X of the left rail in the right lane

        # Compute X positions for right-side rails (one for each lane)
        x3 = LEFT_LINE   + margin    # X of the right rail in the left lane (center plus margin)
        x4 = MIDDLE_LINE + margin    # X of the right rail in the middle lane
        x5 = RIGHT_LINE  + margin    # X of the right rail in the right lane
  
        # ---------------- Rails (vertical) ----------------
        rails_only = (
            ((x >= x0) & (x <= x0 + RAIL_WIDTH)) |  # left lane, left rail
            ((x >= x1) & (x <= x1 + RAIL_WIDTH)) |  # middle lane, left rail
            ((x >= x2) & (x <= x2 + RAIL_WIDTH)) |  # right lane, left rail
            ((x >= x3 - RAIL_WIDTH) & (x <= x3)) |  # left lane, right rail
            ((x >= x4 - RAIL_WIDTH) & (x <= x4)) |  # middle lane, right rail
            ((x >= x5 - RAIL_WIDTH) & (x <= x5))    # right lane, right rail
        )

        # ---------------- Ties (horizontal) ----------------
        # Horizontal span of each track (between the two vertical rails)
        left   = ((x >= (x0 - RAIL_GAP)) & (x <= (x3 + RAIL_GAP)))   # Inside left track horizontal region
        middle = ((x >= (x1 - RAIL_GAP)) & (x <= (x4 + RAIL_GAP)))   # Inside middle track horizontal region
        right  = ((x >= (x2 - RAIL_GAP)) & (x <= (x5 + RAIL_GAP)))   # Inside right track horizontal region

        # Ties appear whenever: y modulo TIE_GAP is less than TIE_WIDTH (creates repeating horizontal bars)
        ties_on = ((left | middle | right) &     # Inside any track horizontally
                   (y % TIE_GAP < TIE_WIDTH))    # Inside the TIE_WIDTH-tall repeating sleeper

        self.rails_o = rails_only | ties_on      # Combine rails + ties

        return self.rails_o

# ----------------- live.v ----------------

class live:
    def __init__(self):
        self.up        = False      # Page 9: set of lives for the player, loadable with btnL
        self.dw        = False      # Page 9: They lose a life when colliding with a train.
        self.has_lives = False      # High when lives > 0
        self.lives_o   = False      # High when (x,y) lies inside any life icon

        self._lives    = countUD16L(0)

    def tick(self, x, y):
        # ---------------- Constants ----------------

        # Maximum lives we care about in logic/drawing (0..3)
        MAX_LIVES = 3

        # Padding and spacing
        PAD   = 10;   # gap from border to first life
        SPACE = 10;   # gap between icons

        # ---------------- Geometry for life icons ----------------

        # Vertical placement (bottom row of icons)
        y0 = V_RES - BORDER - PAD               # bottom edge of icons
        y1 = y0 - SLUG_SIZE                     # top edge of icons (height = SLUG_SIZE)

        # X ranges for three life icons
        x0_0 = BORDER + PAD                     # left of life 1
        x0_1 = x0_0 + SLUG_SIZE                 # right of life 1

        x1_0 = x0_1 + SPACE;                    # left of life 2
        x1_1 = x1_0 + SLUG_SIZE                 # right of life 2

        x2_0 = x1_1 + SPACE                     # left of life 3
        x2_1 = x2_0 + SLUG_SIZE                 # right of life 3

        # ---------------- Lives counter (using countUD16L) ----------------

        if self.up and self._lives.Q_o < MAX_LIVES:
            self._lives.tick(up_i = True)
        elif self.dw and self._lives.Q_o > 0:
            self._lives.tick(dw_i = True)
        lives = self._lives.Q_o


        self.has_lives = lives != 0             # True when lives (0..3) is not zero

        # ---------------- Drawing: which pixels belong to life icons ----------------
        life1 = (lives >= 1) & (x >= x0_0) & (x < x0_1)      # First icon shown when lives >= 1
        life2 = (lives >= 2) & (x >= x1_0) & (x < x1_1)      # Second icon shown when lives >= 2
        life3 = (lives >= 3) & (x >= x2_0) & (x < x2_1)      # Third icon shown when lives >= 3

        self.lives_o = (((y >= y1) & (y < y0)) &    # Check if current pixel is inside vertical band for life icons
                         (life1 | life2 | life3))   # lives is high if we're in the vertical band and in any icon
        
        return self.lives_o

# -------------- Main loop --------------
def main():
    pygame.init()
    pygame.display.set_mode((H_RES, V_RES))
    clock = pygame.time.Clock()

    # Font (fallback if Consolas missing)
    try:
        font = pygame.font.SysFont("consolas", 16)
    except Exception:
        font = pygame.font.Font(None, 16)

    running = True

    pause_game = True             # Page 9: if the game pauses when a life is lost, then pressing btnC resumes game.
    game_over  = False            # Page 5: 32. When the game is over, pressing btnD will start a new game.
    game_started = False          # Page 5: 13. Once a transition has started it will continue unless the game ends (a crash occurs).

    btnL_edge = False             # Page 4: Pressing btnL starts the transition to the adjacent track on the left
    btnR_edge = False             # Page 4: Pressing btnR starts the transition to the adjacent track on the right
    hovering  = False             # Page 3: If the energy level is not 0 and the slug is in the middle, then the slug will hover while btnU is pressed.

    cheat     = False             # Page 3. Switch sw[3] (ALT) will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
    slug_pos = 0                  # current & next positions (signed 2-bit: -1 = 2'b11, 0 = 2'b00, +1 = 2'b01)

    crash_now = False             # Page 7: (h) The last piece is to instantiate the other two tracks, and provide a top level state machine to start the tracks, the slug, and end the game when there is a crash.
    flashing  = False             # Page 3. The slug should change color and flash while it is hovering.
    flash_cnt = 0                 # 5-bit modulo-30 counter driven by frame_tick (~60 Hz)
    score = 0
    

    # Page 6: (a) Implement a VGA controller that outputs the Hsync and Vsync signals, and provides the
    # pixel address and indicator for the active region while displaying a single color.
    _vga = vga_controller()

    # Page 4: The border along all 4 edges of the screen
    _area = area()

    # Page 7: (c) Display the player.
    # Page 9: The player looks like a slug
    _slug = slug()

    # Page 7: (d) Display the energy level bar.
    _energy = energy()

    # Page 7: (g) Next you should work on one track. Please make a separate module for a track.
    _track = track()

    # Page 5. train tracks are visible for each train  
    _rails = rails()

    # Page 9: In addition to satisfying all lab requirements described in the lab manual, add logic 
    # to your design that provides a set of lives for the player, loadable with btnL.
    _live = live()

    def isBool(val):
        if isinstance(val, np.ndarray):
            val = np.any(val)
        return val
    
    while running:        
        l_only, r_only = False, False

        for e in pygame.event.get():
            if e.type == pygame.KEYDOWN:
                if e.key == pygame.K_LEFT:
                    btnL_edge = True
                    l_only =  (game_started and not btnR_edge and not _slug.busy_o) # wire l_only = single & btnL_edge;
                elif e.key == pygame.K_RIGHT:
                    btnR_edge = True
                    r_only =  (game_started and not btnL_edge and not _slug.busy_o) # wire r_only = single & btnR_edge;
                elif e.key == pygame.K_UP:
                    hovering = (slug_pos == 0) # Page 3: If the energy level is not 0 and the slug is in the middle, then the slug will hover while btnU is pressed.
            elif e.type == pygame.KEYUP:
                if e.key == pygame.K_LEFT:
                    btnL_edge = False
                    if not game_started:
                        _live._lives.tick(up_i=True)
                elif e.key == pygame.K_RIGHT:
                    btnR_edge = False
                elif e.key == pygame.K_UP:
                    hovering = False
                elif e.key == pygame.K_ESCAPE:
                    running = False
                elif e.key == pygame.K_SPACE:
                    if not game_over and crash_now: # after crash
                        _track.next_live = True
                        _track.tick(x, y)
                    game_started = True
                    pause_game = not pause_game
                elif e.key == pygame.K_r:
                    main()
                elif e.key in (pygame.K_LALT, pygame.K_RALT):
                    cheat = not cheat

        freeze = not game_started or pause_game or game_over; # Freeze the game
        _slug.freeze   = freeze
        _energy.freeze = freeze
        _track.freeze  = freeze

        # next state: -1 ↔ 0 ↔ +1 with single-step moves
        if game_over:
            next_pos = slug_pos     # Page 5: 30. A crash occurs whenever the slug is not hovering and it overlaps any train by at least 1 pixel.
        elif r_only and not l_only and slug_pos < 1:
            next_pos = slug_pos + 1 # Page 4: 10. Pressing btnR starts the transition to the adjacent track on the right (unless the slug is on the rightmost track).
        elif l_only and not r_only and slug_pos > -1:
            next_pos = slug_pos - 1 # Page 4: 11. Pressing btnL starts the transition to the adjacent track on the left (unless the slug is on the leftmost track).
        else:
            next_pos = slug_pos # no movement or invalid combination, stay where you are
        slug_pos = next_pos

        # --- render (vectorized via shared geometry) ---
        fb = _vga.fb = np.zeros((V_RES, H_RES, 3), dtype=np.uint8) # NumPy framebuffer: shape (V_RES, H_RES, 3)

        if SHOW_SECTION:
            draw_section_borders_fb(fb, _track.cursor_y0, _track.cursor_y1)
        
        _energy.hovering = hovering

        while _vga.isActive():
            x, y = _vga.tick()

            border_on = _area.tick(x, y)
            rails_on  = _rails.tick(x, y)
            lives_on  = _live.tick(x, y)
            energy_on = _energy.tick(x, y)
            trains_on = _track.tick(x, y)
            slug_on   = _slug.tick(x, y, slug_pos)

            if _track.end_train_o:
                score += 1

            # ---------------- collision mask: rails ∧ trains ----------------
            rails_train  = rails_on & trains_on      # pixels where train and rail overlap
            rails_only   = rails_on & ~rails_train   # rails where there is NO train

            hovering = _energy.hovering_o

            # ---------------- collision mask: rails ∧ trains ----------------

            # Page 7: (h) The last piece is to instantiate the other two tracks, and provide a top level state machine 
            # to start the tracks, the slug, and end the game when there is a crash.
            crash_now = (isBool(slug_on &              # Page 9: They lose a life when colliding with a train.
                          trains_on)                   # Page 3: A collision with a train ends the game
                         and not hovering              # Page 3: A crash occurs if the slug is not hovering and overlaps a train.
                         and not cheat)                # Page 3. Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.

            if crash_now and not pause_game:
                _live._lives.tick(dw_i=True)
                pause_game = True
            
            if not game_over:
                game_over = isBool(crash_now) and not _live.has_lives

            if flash_cnt >= 8:   # Counts 0 → 8, then wraps to 0. One full cycle ~0.2 seconds.
                flash_cnt = 0    # restart count
                flashing  = (hovering or game_over) and not flashing
            flash_cnt += 1       # otherwise increment

            slug_Red  = (0  if flashing else           # While slug NOT on a train, turn off (black background flash)
                        255 if hovering else           # Page 5. 16. The slug changes color while it is hovering.
                        255 if cheat    else           # Page 3. Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
                                       255)            # slug → yellow  (R = 255)  Page 4: The slug is a 16 by 16 pixel yellow square
            
            slug_Green = (0  if flashing else           # While slug NOT on a train, turn off (black background flash)
                         68  if hovering else           # Page 5. 16. The slug changes color while it is hovering.
                         255 if cheat    else           # Page 3. Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
                                         255)           # slug → yellow  (G = 255)  Page 4: The slug is a 16 by 16 pixel yellow square
            
            slug_Blue  = (0  if flashing else           # While slug NOT on a train, turn off (black background flash)
                         255 if hovering else           # Page 5. 16. The slug changes color while it is hovering.
                         255 if cheat    else           # Page 3. Switch sw[3] will be a cheat switch that makes the slug immortal: it can go through trains without crashing.
                                           0)           # slug → yellow  (B = 0)  Page 4: The slug is a 16 by 16 pixel yellow square

            # Page 3: To control the monitor you must generate two control signals, Hsync and Vsync, as well as the 12
            # RGB data signals (vgaRed[3:0], vgaBlue[3:0], and vgaGreen[3:0]) for each of the screen's 640 x 480 pixels.
            #Priority drawing: border > energy > slug > lives > rails > trains_on > background (reverse)
            _vga.draw(trains_on, TRAIN_RGB)

            # rails: normal rails in RAILS1_RGB, collisions in RAILS2_RGB
            _vga.draw(rails_only,  RAILS1_RGB)
            _vga.draw(rails_train, RAILS2_RGB)
            
            _vga.draw(lives_on, LIVE_RGB)
            _vga.draw(slug_on, (slug_Red, slug_Green, slug_Blue))
            _vga.draw(energy_on, ENERGY_RGB)
            _vga.draw(border_on, AREA_RGB)

        surf = pygame.display.get_surface()  # This is what is really shown in the window. 
        frame_surface = pygame.surfarray.make_surface(
            np.transpose(fb, (1, 0, 2)).copy(order="C")  # (width, height, channels)
        )
        surf.blit(frame_surface, (0, 0))     # draw fb → frame_surface → window

        draw_text(surf, font, [
            f"cursor_y0: {_track.cursor_y0:4d}  cursor_y1: {_track.cursor_y1:4d}",
            f"Score: {score:8d}  Time: {_track._start_delay.Q_o / 60:9.1f}",
            "Use LEFT/RIGHT/UP arrow keys",
            "SPACE | ALT | R reset | ESC quit",
        ])

        if game_over:
            draw_text(surf, font, ["GAME OVER!"], y=250, x=120)

        pygame.display.flip()
        pygame.display.set_caption(f"Verilog → Python Trains | {'CHEAT | ' if cheat else ''} {'PAUSED' if freeze else 'RUNNING'}")
        clock.tick(FREQ_HZ)

    pygame.quit()

# --- Section borders (draw the two actual bands per section; WITH GAP) ---
def draw_section_borders_fb(fb, cursor_y0, cursor_y1):
    half = TRACK_H // 2

    # infer width/height from framebuffer
    Rh, Rw, _ = fb.shape

    x0 = max(0, int(min(LEFT_LINE, RIGHT_LINE) - half)) - 1
    x1 = min(Rw - 1, int(max(LEFT_LINE, RIGHT_LINE) + half)) + 1

    def rects_for_section_and_draw(fb, cursor_y, color, x0, x1, Rh):
        # compute
        top0 = int(cursor_y - MAX_TRAIN_V)
        bot0 = int(cursor_y + 1)
        top1 = int(cursor_y - ROW_GAP - MAX_TRAIN_V * 2)
        bot1 = int(cursor_y - ROW_GAP - MAX_TRAIN_V + 1)

        # clamp
        top0 = max(0, min(Rh - 1, top0)); bot0 = max(0, min(Rh - 1, bot0))
        top1 = max(0, min(Rh - 1, top1)); bot1 = max(0, min(Rh - 1, bot1))

        # horizontal bands
        fb[top0, x0:x1] = fb[bot0, x0:x1] = fb[top1, x0:x1] = fb[bot1, x0:x1] = color

        # vertical lines (optional)
        fb[top0:bot0, x0] = fb[top0:bot0, x1] = fb[top1:bot1, x0] = fb[top1:bot1, x1] = color
    
    rects_for_section_and_draw(fb, cursor_y0, BORDER_SEC0, x0, x1, Rh)
    rects_for_section_and_draw(fb, cursor_y1, BORDER_SEC1, x0, x1, Rh)

# ---------------- HUD helpers ----------------
def draw_text(surface, font, lines, x=8, y=360, padding=6, line_h=18):
    texts = [font.render(line, True, COLOR_HUD_TXT) for line in lines]
    if not texts:
        return
    w = max(t.get_width() for t in texts)
    h = len(texts) * line_h + padding * 2
    panel = pygame.Surface((w + padding * 2, h), pygame.SRCALPHA)
    surface.blit(panel, (x, y))
    yy = y + padding
    for t in texts:
        surface.blit(t, (x + padding, yy))
        yy += line_h

if __name__ == "__main__":
    main()
