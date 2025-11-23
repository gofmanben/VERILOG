# CSE100 Labs in Verilog for the Basys3 FPGA using Xilinx Vivado

This top-level README provides an overview of **CSE100 laboratory projects**, along with direct links to each project's detailed README file.  
Each lab builds foundational digital design skills using **Verilog**, **Vivado**, **state machines**, **counters**, and ultimately a full **VGA game**.

---

# 📘 Lab Summaries & Links

---

## 🔹 **Lab 1 – Introduction to Vivado Projects**
Basic Vivado project setup, exploring RTL structure, constraints, and synthesis flow.  
➡ **[Open Lab 1 README](Lab01/README.md)**

---

## 🔹 **Lab 2 – Counters and Seven‑Segment Display**
Implements a 16‑bit up/down counter using cascaded 4‑bit modules, connected to switches, buttons, LEDs, and a multiplexed 7‑segment display.  
➡ **[Open Lab 2 README](Lab02/README.md)**

---

## 🔹 **Lab 3 – Hierarchical Counters & Display Logic**
Designs a loadable 16‑bit counter, selector, ring counter, edge detector, and integrates them into a complete top module.  
➡ **[Open Lab 3 README](Lab03/README.md)**

---

## 🔹 **Lab 4 – FSM Design: Turkey Pattern Game**
Implements a full finite state machine with random pattern generation, LED display logic, and user interactions.  
➡ **[Open Lab 4 README](Lab04/README.md)**

---

## 🔹 **Lab 5 – Dual‑IR Sensor State Machine (Turkey Counter)**
Detects left→right and right→left crossings using a two‑sensor FSM. Includes up/down counter, LED animation, and seven‑segment output.  
➡ **[Open Lab 5 README](Lab05/README.md)**

---

## 🔹 **Lab 6 – Slug vs. Trains VGA Game + Python Simulator**
A full VGA video game project with synchronized Verilog modules, including slug movement, train tracks, collisions, scoring, lives, and a Python simulator mirroring VGA output.  
➡ **[Open Lab 6 README](Lab06/README.md)**

---

# 📚 Technology Used Across Labs
- **Vivado 2025.1**  
- **Structural & Behavioral Verilog**  
- **Finite State Machines (FSMs)**  
- **Counters, LFSRs, Debouncing & Edge Detection**  
- **7-Segment Display Drivers**  
- **VGA Timing Generation**  
- **Randomization via LFSR**  
- **Python + Pygame for hardware-accurate simulation**

---

# 🎯 Final Notes
This master README acts as a hub for navigation. Each lab folder contains:
- Source files  
- XDC constraints  
- Individual lab README  
- Build instructions