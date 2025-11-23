
# CSE100 Lab 3 – Vivado Project

This repository contains the source files for **CSE100 Lab 3**. Follow the steps below to set up your environment and open the project in **Xilinx Vivado 2025.1**.

---

## 📦 Prerequisites

Before you begin, ensure the following software is installed on your system:

- **Vivado Design Suite 2025.1**  
  Download the latest version here:  
  👉 [Vivado™ Edition - 2025.1  Full Product Installation](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html)

---

## 🚀 Getting Started

1. **Download and Install Vivado**  
   Follow the instructions on the Xilinx website to install Vivado **2025.1** or later.

2. **Open the Project in Vivado**  
   Launch Vivado and open the provided project file:
   - Go to **File → Open Project...**
   - Select `cse100_lab3_bgofman.xpr` from the extracted directory.

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

In this lab, you will implement and integrate the following modules:

- **4-bit Counter (`countUD4L`)** – A loadable up/down counter with terminal count detection.  
- **16-bit Counter** – Built by cascading four `countUD4L` modules.  
- **Selector** – Chooses one of four 4-bit segments from a 16-bit bus for display.  
- **Ring Counter** – Cycles control signals for digit selection on the 7-segment display.  
- **Edge Detector** – Generates single-cycle pulses on button presses.  
- **Top Module** – Integrates all components and connects them to FPGA I/O.

The system behavior:

- **btnU**: Increment the 16-bit counter by 1  
- **btnD**: Decrement the counter by 1  
- **btnC**: Continuously count up (except from `0xFFFC`–`0xFFFF`)  
- **btnL**: Load counter with the value from switches `sw[15:0]`  
- **led[15]**: Lit when the counter = `0xFFFF`  
- **led[0]**: Lit when the counter = `0x0000`  

Counter wraps around (incrementing at `0xFFFF` → `0x0000`, decrementing at `0x0000` → `0xFFFF`).

---


## 📚 Support

For Vivado documentation and tutorials, visit the official Xilinx support site:  
🔗 [https://www.xilinx.com/support.html](https://www.xilinx.com/support.html)
