# Library Self-Checkout & Fine Management System — RTL Design & UVM Verification (SystemVerilog)

A complete **FSM-based digital library management system** implemented in **SystemVerilog RTL**, supporting book issue/return operations, late fine calculation, maintenance configuration, and transaction logging.

The project focuses on designing a **modular, synthesizable RTL architecture** and verifying it using a **reusable UVM (Universal Verification Methodology) testbench** with directed and constrained-random verification.

---

## Key Features

- **Moore FSM-based control logic**
- Modular **control–datapath architecture**
- **Book availability and due-date tracking**
- Automatic **late fine calculation**
- **Configurable fine rate and borrow duration**
- Dedicated **maintenance mode for runtime configuration**
- **Circular buffer-based transaction logging**
- Robust **error handling mechanism**
- Fully **synthesizable RTL design**
- Verified using a **UVM-based verification environment**

---

## RTL Design Architecture

The RTL design is organized into modular components:

### FSM Controller (`library_fsm`)
- Implements Moore FSM for system control
- Handles issue, return, maintenance, fine calculation, and error states

### Book Database (`book_db`)
- Maintains book availability and due-date information
- Supports issue, return, and maintenance operations

### Fine Calculation (`fine_calc`)
- Computes fine based on overdue days
- Uses configurable fine rate

### Configuration Registers (`config_regs`)
- Stores borrow duration and fine rate
- Supports runtime updates during maintenance mode

### Transaction Logger (`txn_logger`)
- Implements circular buffer for transaction history
- Records book ID, operation type, and fine amount

### Top-Level Module (`top`)
- Integrates all RTL submodules
- Provides system-level interface

---

# UVM Verification Architecture

The RTL is verified using a reusable **UVM testbench** consisting of:

- UVM Test
- UVM Environment
- UVM Agent
- UVM Sequencer
- UVM Driver
- UVM Monitor
- UVM Scoreboard
- Sequence Items
- Directed and Constrained-Random Sequences
- Functional Coverage

The verification environment follows the standard UVM layered architecture, enabling scalability and reuse.

---

## Verification Methodology

The UVM environment performs:

- Transaction-level stimulus generation
- Driver-based DUT interface communication
- Passive monitoring of DUT transactions
- Scoreboard-based functional checking
- Functional coverage collection
- Directed and constrained-random verification
- Waveform-based debugging

Simulation is performed using **Vivado XSIM**.

---

## Verification Scenarios

The verification environment covers:

1. Reset Initialization
   - Verifies proper reset behavior and FSM initialization

2. Maintenance Mode Configuration
   - Updates fine rate and borrow duration
   - Verifies configuration register updates

3. Book Issue Operation
   - Verifies successful issue transaction
   - Checks database updates

4. Book Return (No Fine)
   - Verifies return within due period
   - Confirms zero fine generation

5. Late Return with Fine
   - Verifies overdue fine calculation
   - Checks fine amount correctness

6. Invalid Transactions
   - Attempts invalid issue/return operations
   - Verifies error handling

7. Maintenance Mode Stress Testing
   - Performs multiple configuration updates
   - Verifies stable operation

---

## Key Design Insights

- Modular control–datapath separation improves scalability and synthesis efficiency.
- Reusable UVM components enable verification environment portability.
- Scoreboard-based checking simplifies functional validation.
- Functional coverage helps measure verification completeness.
- Configurable registers improve RTL flexibility without code modification.

---

## Skills Demonstrated

### RTL Design
- FSM-based RTL Design
- Modular SystemVerilog Design
- Control–Datapath Separation
- Parameterized Hardware Design
- Synthesizable RTL

### Verification
- UVM Verification Methodology
- Testbench Development
- Driver, Monitor, Sequencer & Scoreboard
- Functional Coverage
- Directed & Constrained-Random Verification
- Transaction-Level Verification
- Waveform Debugging

---

## Technologies

- SystemVerilog
- UVM (Universal Verification Methodology)
- RTL Design
- Digital Design Verification
- Vivado (XSIM)

---

