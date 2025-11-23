
# CSE100 Lab 1 – Vivado Project

This repository contains the source files for **CSE100 Lab 1**. Follow the steps below to set up your environment and open the project in **Xilinx Vivado 2025.1**.

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
   - Select `cse100_lab1_bgofman.xpr` from the extracted directory.

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

## 📁 Project Structure

```
cse100_lab1_bgofman/
├─ cse100_lab1_bgofman.xpr             # Vivado project file
├─ cse100_lab1_bgofman.srcs/sources_1  # HDL source files
├─ cse100_lab1_bgofman.srcs/constrs_1  # XDC constraint files
```

---

## 🧪 Notes

- Make sure to use **Vivado 2025.1** or a compatible version — older versions may not support the project files.
- All required directories and intermediate files will be generated automatically when you open the project and run the synthesis/implementation flow.

---

## 📚 Support

For Vivado documentation and tutorials, visit the official Xilinx support site:  
🔗 [https://www.xilinx.com/support.html](https://www.xilinx.com/support.html)
