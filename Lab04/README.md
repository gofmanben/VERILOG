# CSE100 Lab 4 – Finite State Machines (FSM)

This repository contains the source files for **CSE100 Lab 4**. Follow the steps below to set up your environment and open the project in **Xilinx Vivado 2025.1**.

---

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
   - Select `cse100_lab4_bgofman.xpr` from the extracted directory.

3. **Generate Required Directories and Files**  
   Once the project is opened, Vivado will automatically generate all necessary build directories (such as `.runs`, `.sim`, `.cache`, etc.) on first synthesis or implementation.

---

## 🛠️ Build & Run

To build the project:

1. In the **Flow Navigator**, click on:
   - **Run Synthesis**
   - **Run Implementation**
   - **Generate Bitstream** (if applicable)

2. Optionally, you can simulate the design:
   - Go to **Flow Navigator → Simulation → Run Simulation → Run Behavioral Simulation**

---

## 🧠 Design Overview

In this lab, you will design and implement a **Finite State Machine (FSM)** that controls LED patterns based on the movement of “turkeys” across a crossing zone. The system uses button inputs to initiate, monitor, and display state transitions.

### Key Modules:

- **FSM Controller (`fsm.v`)** – Implements state transitions (IDLE, SHOW, CORR, WRONG, WIN, LOSE) controlling LED visibility and logic timing.  
- **Random Pattern Generator (`lfsr.v`)** – Uses a Linear Feedback Shift Register (LFSR) to generate pseudorandom LED patterns for each crossing.  
- **Edge Detector (`edge_detector.v`)** – Converts button presses into single-cycle pulses.  
- **Display Driver (`ring_counter.v, selector.v, hex7seg.v`)** – Controls the LED outputs to show patterns or indicate crossing activity.  
- **Top Module (`lab4_top.v`)** – Integrates the FSM, LFSR, and I/O handling for buttons, LEDs, and switches.

### Functional Behavior:

- **btnC**: Starts a turkey crossing (FSM transition from Idle → Crossing).  
- **btnU / btnD**: Optional manual step or reset actions depending on FSM implementation.  
- **LEDs**:
  - Eight LEDs (`led[7:0]`) display the random pattern after each crossing.
  - All LEDs remain **off** before the first crossing and while a crossing is in progress.
  - LEDs light up to indicate the “seed” pattern once a crossing completes.
- **Switches (`sw`)**: May set initial seed or mode configuration for the LFSR.

---

## 🧩 Verification & Simulation

You can verify the FSM logic using **behavioral simulation**:

1. Open **Simulation → Run Behavioral Simulation** in Vivado.  
2. Observe the **state transitions** and **LED output behavior** over time.  
3. Confirm that LEDs are off during crossings and only display after each successful completion.

---

## 📚 Support

For Vivado documentation and tutorials, visit the official Xilinx support site:  
🔗 [https://www.xilinx.com/support.html](https://www.xilinx.com/support.html)
