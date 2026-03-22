# Library Self-Checkout & Fine Management System — RTL Design & Verification (SystemVerilog)

A complete **FSM-based digital library management system** implemented in **SystemVerilog RTL**, supporting book issue/return operations, late fine calculation, maintenance configuration, and transaction logging.

The project focuses on designing a **modular, synthesizable hardware system** with clear **control–datapath separation**, verified using **directed test scenarios**.

---

## Key Features

- **Mealy FSM-based control logic**
- Modular **control and datapath architecture**
- **Book availability and due-date tracking**
- Automatic **late fine calculation**
- **Configurable fine rate and borrow duration**
- Dedicated **maintenance mode for runtime updates**
- **Circular buffer-based transaction logging**
- Robust **error handling mechanism**
- Fully **synthesizable RTL design**
- Verified using **Vivado XSIM simulation**

---

## Design Architecture

The RTL design is organized into modular components:

- **FSM Controller (`library_fsm`)**
  - Controls system flow using Mealy FSM
  - Handles issue, return, fine calculation, maintenance, and error states

- **Book Database (`book_db`)**
  - Stores book availability and due dates
  - Supports issue, return, and maintenance updates

- **Fine Calculation (`fine_calc`)**
  - Computes fine based on late return days
  - Uses configurable fine rate

- **Configuration Registers (`config_regs`)**
  - Stores fine rate and borrow duration
  - Allows runtime updates via maintenance mode

- **Transaction Logger (`txn_logger`)**
  - Implements circular buffer for transaction history
  - Stores book ID, operation type, and fine amount

- **Top-Level Module (`top`)**
  - Integrates all submodules
  - Provides clean system-level interface

---

## Verification Approach

The design is verified using a **SystemVerilog testbench with directed test scenarios**.

The testbench includes:

- Clock and reset generation  
- Sequential stimulus application  
- Manual scenario-based verification  
- Waveform-based validation of outputs  

Simulation is performed using **Vivado XSIM**.

---

## Verification Scenarios

The following directed test scenarios are implemented:

1. **Reset Initialization**
   - Verifies proper system reset and FSM initialization

2. **Maintenance Mode Configuration**
   - Updates fine rate using configuration registers
   - Verifies maintenance mode entry and exit

3. **Book Issue Operation**
   - Issues a book and updates database state

4. **Return Without Fine**
   - Returns book within allowed period
   - Verifies fine = 0

5. **Late Return with Fine Calculation**
   - Returns book after due date
   - Verifies fine calculation logic

6. **Error Injection**
   - Forces system into ERROR state
   - Verifies global error handling

---

## Key Design Insight

Separating **control logic (FSM)** from **datapath modules** improves modularity, scalability, and synthesis efficiency.

Using **configurable registers** instead of hardcoded values allows dynamic system behavior without modifying RTL.

---

## Skills Demonstrated

- FSM-based RTL design
- Control–datapath separation
- SystemVerilog modular design
- Directed functional verification
- Debugging using waveform analysis
- Hardware-oriented system design

---

## Technologies

- **SystemVerilog**
- **RTL Design**
- **Digital Design Verification**
- **Vivado (XSIM & Synthesis)**

---

## Project Structure
