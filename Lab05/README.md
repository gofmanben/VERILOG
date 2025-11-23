# CSE100 Lab 5 – Dual-IR Sensor State Machine (Turkey Counter)

This project implements a **synchronous, structural Verilog** design on **BASYS3** that monitors **two IR-like sensors** (simulated with pushbuttons) to detect crossings **left→right** and **right→left**, keeps an **up/down difference counter** in 2’s complement **(−127…+127)**, drives the **two rightmost seven‑segment digits**, and animates an **LED “chaser”** indicating the direction of the **most recent successful crossing**. It follows the operator/use constraints from the lab handout and uses the provided **`qsec_clks`** helper for 0.25 s timing. 

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
   - Select `cse100_lab5_bgofman.xpr` from the extracted directory.

3. **Generate Required Directories and Files**  
   Once the project is opened, Vivado will automatically generate all necessary build directories (such as `.runs`, `.sim`, `.cache`, etc.) on first synthesis or implementation.

---

## 🧠 Design Overview

- **Turkey Counter (Up/Down 8‑bit counter)** — holds the **difference** L→R minus R→L in 2’s complement (range **−127…+127**). Display its **magnitude** on the two rightmost 7‑seg digits; when negative, **light the minus sign** (`seg[6]` on AN2) and show the magnitude. 
- **LED Shifter (8‑bit)** — repeatedly lights `led[7:0]` from **left→right** if last crossing was L→R, or **right→left** if last crossing was R→L, stepping **every 0.25 s** using `qsec`. All eight must be **off before the first crossing** and **off during an in‑progress crossing**. On an aborted attempt, resume the prior pattern. 

### Signals & Indicators
- **Sensor Display**: Mirror the (inverted) pushbuttons to **LED15** (left sensor) and **LED8** (right sensor), because true IR sensors are **normally high** and go **low when blocked**, while pushbuttons are normally low. 
- **Seven‑Segment**: Use an existing ring‑counter scanner (driven by `digsel`) for multiplexing the two rightmost digits. Show magnitude in hex or decimal per your course convention; ensure minus sign control on negative values. 
- **Clocking**: **Everything is synchronous to the system clock**; `qsec` and `digsel` are **enables**, not clocks.

### Module Breakdown (suggested file names)
- `fsm.v` — the state machine that classifies **L→R** / **R→L** crossings and detects **indecisive** motions until completion. 
- `led_shifter.v` — 8‑bit shifter with **dir**, **step** (use `qsec`), and **clear** controls.
- `qsec_clks.v` — provided divider that generates `clk`, `digsel`, and `qsec`. 
- `top_lab5.v` — ties it all together and maps board I/O (BASYS3 constraints file required).

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
