# CSE100 Lab 6 – Subway Slugging (VGA Game + Python Simulator)

This project implements the **Subway Slugging VGA game** from Lab 6 using a **synchronous, structural Verilog** design on the **BASYS3** board, plus a matching **Python/pygame simulator** that mirrors the Verilog geometry and behavior.

For a deeper dive into the implementation, including module descriptions and code-referenced links, see [Overview.md](Overview.md)

## 🎬 Python simulator animation
![Demo Animation](Recording.gif)

#### Controls (keyboard):
- LEFT / RIGHT arrow keys – Move slug between tracks.
- UP arrow – Hover (when in middle track and energy > 0).
- SPACE – Start / pause / resume the game.
- ALT – Toggle cheat (slug becomes immortal; can pass through trains).
- R – Reset by restarting the Python script.
- ESC – Quit.

---

The design drives a 640×480 VGA display with:

- **slug** that can switch between three tracks or hover above the middle track  
- **Trains** descending on three tracks in the right 2/3 of the screen  
- **green energy bar** on the left, tracking hover energy  
- **border**, **rail** and a **lives** with crashes and game-over

All logic follows the constraints and behavior described in the [Lab 6 PDF file](cse100_lab_6.pdf).

## 📦 Prerequisites

Before you begin, ensure the following software is installed on your system:

- **Vivado Design Suite 2025.1**  
  Download the latest version here:  
  👉 [Vivado™ Edition - 2025.1 Full Product Installation](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html)

---

## 🚀 Getting Started

1. **Download and Install Vivado**  
   Follow the instructions on the Xilinx website to install Vivado **2025.1** or later.

2. **Open the Project in Vivado**  
   Launch Vivado and open the provided project file:
   - Go to **File → Open Project...**
   - Select `cse100_lab6_bgofman.xpr` from the extracted directory.

3. **Generate Required Directories and Files**  
   Once the project is opened, Vivado will automatically generate all necessary build directories (such as `.runs`, `.sim`, `.cache`, etc.) on first synthesis or implementation.

---

## Python simulator

- **Python 3.9+**
- Python packages:
  ```bash
  pip install pygame numpy

  python simulator.py
   ```
---

## 🧠 Design Overview

Generates proper **VGA timing** for a 640×480 @ ~60 Hz display (25 MHz pixel clock).

Draws:

- An **8-pixel white border** on all four edges.
- Three **vertical tracks** in the right 2/3 of the screen (60 px wide, 10 px gaps).
- Maximum **two trains** per track, falling at 1 pixel per frame, with:
   - Random lengths between **60 and 123 pixels**
   - Random **wait times** between train starts
- A **16×16 slug** whose top edge is fixed at row **360**.
- A **20-pixel wide** energy bar near the left border, with max length **192 pixels**.
- A **lives** indicator made of slug-sized yellow boxes near the bottom left.

---

## 🔧 Module Breakdown

Typical modules in the Verilog design (exact names may vary with your code):
- lab6Top.v – Top-level wrapper for BASYS3 I/O and module instantiation.
- vga_controller.v – Generates Hsync/Vsync and provides (x, y) pixel addresses plus frame tick.
- area.v – Detects border region.
- slug.v – Implements slug position, track transitions, and hover animation.
- energy.v – Handles the energy level up/down behavior and bar drawing.
- track.v – Per-track logic: start delay, train sequencing, scoring.
- train.v – Geometry for an individual train instance (height, row assignment, scoring row).
- rails.v – Draws rails and ties on all three tracks.
- lfsr.v – 8-bit LFSR for pseudo-random height and delay generation.
- countUD16L.v – 16-bit up/down/loadable counter reused for timing and positions.
- live.v – Lives counter and on-screen life icons.

---

## 📚 Support

For Vivado documentation and tutorials, visit the official Xilinx support site:  
🔗 [https://www.xilinx.com/support.html](https://www.xilinx.com/support.html)