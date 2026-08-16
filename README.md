# RISC-V Multi-Gateway FPGA

A RISC-V based multi-gateway embedded SoC implemented and evaluated on a
Xilinx Artix-7 FPGA using Xilinx Vivado.

![RISC-V](https://img.shields.io/badge/CPU-RV32IM-blue)
![FPGA](https://img.shields.io/badge/FPGA-Artix--7-orange)
![HDL](https://img.shields.io/badge/HDL-Verilog-green)
![Tool](https://img.shields.io/badge/Tool-Vivado-red)

------------------------------------------------------------------------

## Overview

This project explores a RISC-V based multi-gateway embedded system
implemented on a Digilent Arty-7 FPGA.

The design is based on the open-source UltraEmbedded RISC-V SoC platform
and was used to study and evaluate:

-   RISC-V processor integration
-   AXI4 and AXI4-Lite communication
-   DDR3 memory integration using Xilinx MIG
-   Clock-domain crossing
-   FPGA clock generation
-   Peripheral integration
-   Hardware verification
-   FPGA synthesis and implementation

The platform combines a RISC-V RV32IM processor with a DDR3 memory
subsystem and an AXI4-Lite peripheral fabric for embedded gateway
applications.

------------------------------------------------------------------------

## System Architecture

The system integrates a RISC-V processor with memory, AXI
infrastructure, clock-domain crossing logic, and multiple peripheral
interfaces.

``` text
                         +----------------------+
                         |     RISC-V RV32IM    |
                         |       Processor      |
                         +----------+-----------+
                                    |
                                  AXI4
                                    |
                    +---------------+---------------+
                    |                               |
              +-----v-----+                   +-----v-----+
              | DDR3 / MIG|                   | AXI Fabric|
              |  Memory   |                   |           |
              +-----------+                   +-----+-----+
                                                    |
                              +---------------------+-------------------+
                              |          AXI4-Lite Peripheral Fabric  |
                              |                                         |
                         +----v----+ +------+ +------+ +------+ +------+
                         |  UART   | | SPI  | | GPIO | |Timer | | IRQ  |
                         +---------+ +------+ +------+ +------+ +------+
                                                    |
                                              +-----v-----+
                                              |   Debug   |
                                              |  Bridge   |
                                              +-----------+

                         Clock domains connected
                           through AXI CDC logic
```

------------------------------------------------------------------------

## Main Features

### RISC-V Processor

-   32-bit RISC-V RV32IM processor
-   RISC-V based embedded SoC architecture
-   Processor integrated with the SoC peripheral and memory
    infrastructure

### Memory Subsystem

-   DDR3 external memory interface
-   Xilinx 7-Series Memory Interface Generator (MIG)
-   AXI4 memory interface
-   AXI clock-domain crossing infrastructure

### Peripheral Fabric

The AXI4-Lite peripheral subsystem includes:

-   UART
-   SPI
-   GPIO
-   Timer
-   Interrupt controller
-   Debug bridge

### Clocking

The FPGA implementation includes dedicated clock-generation
infrastructure using Artix-7 clocking resources.

------------------------------------------------------------------------

## FPGA Platform

  Parameter          Configuration
  ------------------ --------------------
  Board              Digilent Arty-7
  FPGA Family        Xilinx Artix-7
  Device             XC7A35T-1CSG324-1L
  HDL                Verilog HDL
  FPGA Tool          Xilinx Vivado
  Processor          RISC-V RV32IM
  External Memory    DDR3
  Bus Architecture   AXI4 / AXI4-Lite

------------------------------------------------------------------------

## Verification

A project-level Verilog testbench is included in:

``` text
testbench/top_tb.v
```

The testbench was used for system-level functional verification.

The verification environment includes mechanisms for exercising:

-   Clock generation
-   Reset generation
-   Instruction bus activity
-   Data bus activity
-   Processor execution
-   UART activity
-   Memory transactions
-   DDR3-side interface connectivity
-   Peripheral activity

The simulation environment uses response stubs for parts of the DDR3
interface to make system-level simulation practical while checking the
connectivity and behavior of the memory interface.

> The DDR3-side verification does not represent a complete physical DDR3
> timing model. Sustained high-throughput DDR3 operation and worst-case
> memory timing were not characterized in the reported evaluation.

------------------------------------------------------------------------

## FPGA Implementation

Following simulation, the design was taken through:

``` text
RTL
 |
 +--> Simulation
 |
 +--> Synthesis
 |
 +--> Placement
 |
 +--> Routing
 |
 +--> Resource Analysis
 |
 +--> Power Estimation
```

The complete FPGA implementation flow was performed using Xilinx Vivado
targeting the Artix-7 XC7A35T-1CSG324-1L device.

------------------------------------------------------------------------

## Post-Implementation Results

### Resource Utilization

  Resource           Used   Utilization
  -------------- -------- -------------
  LUTs             13,191        63.42%
  Flip-Flops        9,998        24.03%
  Block RAM             5        10.00%
  DSP48 Slices          4         4.44%
  BUFG                  3           ---
  MMCM                  1           ---
  PLL                   2           ---

The LUT utilization is primarily associated with the processor datapath,
AXI infrastructure, peripheral control logic, and associated
sequential/combinational logic.

BRAM and DSP utilization remain comparatively low, leaving potential
FPGA resources for future hardware accelerators and additional
buffering.

------------------------------------------------------------------------

## Power and Thermal Results

### Estimated Power

``` text
Estimated on-chip power: 0.786 W
```

### Thermal Margin

``` text
Reported thermal margin: 71.2 °C
```

The power value is a post-implementation Vivado estimate and should not
be interpreted as a board-level measured power value.

------------------------------------------------------------------------

## Resource Analysis

The implementation demonstrates that a complete gateway-capable RISC-V
platform can be realized on a relatively modest Artix-7 FPGA.

The major resource consumption is concentrated in LUTs and flip-flops,
while BRAM and DSP usage remains comparatively low.

This provides potential room for future additions such as:

-   Hardware accelerators
-   Signal-processing blocks
-   Cryptographic accelerators
-   Lightweight AI inference
-   Additional memory buffering
-   Additional communication peripherals

------------------------------------------------------------------------

## Project Structure

``` text
RISC-V-MultiGateway-FPGA/
│
├── constraints/
│   └── arty_revb.xdc
│
├── fpga/
│   └── arty/
│       ├── artix7_pll.v
│       ├── arty_ddr.v
│       ├── axi4_cdc.v
│       ├── dbg_bridge.v
│       ├── dbg_bridge_fifo.v
│       ├── dbg_bridge_uart.v
│       ├── fpga_top.v
│       └── top.v
│
├── ip/
│   ├── axi_cdc_buffer/
│   │   └── axi_cdc_buffer.xci
│   │
│   └── mig_axis/
│       └── mig_axis.xci
│
├── testbench/
│   └── top_tb.v
│
├── vivado/
│   └── block_design/
│       └── design_1.bd
│
├── upstream/
│   └── riscv_soc/
│
├── images/
│
├── results/
│
├── .gitignore
├── .gitmodules
└── README.md
```

------------------------------------------------------------------------

## Directory Description

### `constraints/`

Contains FPGA pin and timing constraints.

``` text
constraints/
└── arty_revb.xdc
```

The constraint file targets the Arty-7 board and defines the required
FPGA pin assignments and clock constraints.

### `fpga/`

Contains the FPGA-specific Verilog implementation.

Important modules include:

``` text
artix7_pll.v
arty_ddr.v
axi4_cdc.v
dbg_bridge.v
dbg_bridge_fifo.v
dbg_bridge_uart.v
fpga_top.v
top.v
```

These modules provide FPGA-level clocking, DDR interface integration,
AXI CDC infrastructure, debug connectivity, and top-level integration.

### `ip/`

Contains the Xilinx Vivado IP configuration files.

``` text
ip/
├── axi_cdc_buffer/
│   └── axi_cdc_buffer.xci
└── mig_axis/
    └── mig_axis.xci
```

The `.xci` files contain the configuration information required to
recreate the corresponding Vivado IP.

Generated IP implementation artifacts are intentionally excluded from
the repository.

### `testbench/`

Contains the project-level simulation testbench.

``` text
testbench/
└── top_tb.v
```

### `vivado/`

Contains the Vivado block-design source used by the project.

``` text
vivado/
└── block_design/
    └── design_1.bd
```

### `upstream/`

Contains the upstream RISC-V SoC project as a Git submodule.

This is intentionally kept separate from the project-specific FPGA
integration.

------------------------------------------------------------------------

## Upstream Project and Attribution

This project builds upon the open-source UltraEmbedded RISC-V and
`riscv_soc` projects.

The upstream SoC is included as a Git submodule:

``` text
upstream/riscv_soc/
```

The repository therefore does **not** claim ownership of the original
UltraEmbedded RISC-V processor or SoC implementation.

The upstream source, license information, and copyright notices remain
associated with the original project.

The project-specific work focuses on the FPGA integration,
gateway-oriented system configuration, memory and peripheral
integration, verification environment, and implementation evaluation.

------------------------------------------------------------------------

## What This Project Demonstrates

### Computer Architecture

-   RISC-V ISA
-   RV32IM processor architecture
-   CPU and SoC integration
-   Memory subsystem integration
-   Peripheral architecture

### FPGA Design

-   Verilog HDL
-   Xilinx Artix-7
-   Digilent Arty-7
-   FPGA synthesis
-   Placement and routing
-   Resource utilization analysis
-   Power estimation
-   Timing constraints

### Interconnects

-   AXI4
-   AXI4-Lite
-   Clock-domain crossing
-   AXI clock conversion
-   Peripheral register interfaces

### Embedded Interfaces

-   UART
-   SPI
-   GPIO
-   Timer
-   Interrupt controller
-   Debug interface

### Memory

-   DDR3
-   Xilinx MIG
-   AXI-based memory access

### Verification

-   Verilog testbench
-   System-level simulation
-   Processor execution verification
-   Peripheral verification
-   Memory-interface connectivity verification

------------------------------------------------------------------------

## Reproducibility

### Requirements

The project requires:

-   Xilinx Vivado
-   A compatible Vivado version supporting the target Artix-7 device and
    included IP
-   Verilog simulation support
-   Digilent Arty-7 board for hardware deployment

### Clone the Repository

``` bash
git clone https://github.com/BarathKumarMS/RISC-V-MultiGateway-FPGA.git
cd RISC-V-MultiGateway-FPGA
```

Initialize the upstream submodule:

``` bash
git submodule update --init --recursive
```

The repository uses a Git submodule so that the upstream RISC-V SoC
source remains separately identifiable.

------------------------------------------------------------------------

## Vivado Flow

The general implementation flow is:

``` text
1. Clone repository
        |
        v
2. Initialize Git submodules
        |
        v
3. Open / recreate Vivado project
        |
        v
4. Add RTL and Xilinx IP
        |
        v
5. Apply Arty-7 constraints
        |
        v
6. Run simulation
        |
        v
7. Run synthesis
        |
        v
8. Run implementation
        |
        v
9. Review timing/resource reports
        |
        v
10. Generate FPGA programming output
```

Generated Vivado directories and build artifacts are intentionally
excluded from version control.

------------------------------------------------------------------------

## Current Limitations

The reported evaluation should be considered a feasibility and
implementation baseline rather than a complete hardware qualification.

### DDR3 Verification

The DDR3-side simulation uses response stubs rather than a complete
physical DDR3 timing model.

Therefore, the current results do not establish:

-   Sustained high-throughput DDR3 operation
-   Worst-case DDR3 timing behavior
-   Long-duration DDR3 stress performance
-   Full memory calibration behavior under all operating conditions

### Power

The reported `0.786 W` is a Vivado post-implementation estimate.

It is not a bench-measured power value from the physical Arty-7 board.

### Peripheral Stress Testing

The current verification does not constitute a complete concurrent
stress test of:

-   SPI
-   Timer
-   Interrupt
-   UART
-   Memory subsystem

under maximum sustained system load.

### Hardware Qualification

Extended hardware-in-the-loop testing and long-duration soak testing
remain future work.

------------------------------------------------------------------------

## Future Scope

### Communication Interfaces

-   Ethernet
-   CAN
-   USB
-   Wi-Fi
-   Bluetooth

### Hardware Acceleration

-   DSP accelerators
-   Cryptographic accelerators
-   Signal-processing accelerators
-   Lightweight AI inference accelerators

### Processor Architecture

-   Multi-core RISC-V
-   Alternative RISC-V cores
-   Minimal operating-system support
-   More advanced memory subsystems

### Verification

-   Hardware-in-the-loop DDR3 testing
-   Sustained memory traffic testing
-   Board-level power measurement
-   Long-duration soak testing
-   Concurrent peripheral stress testing

------------------------------------------------------------------------

## Technologies

### Hardware

-   Digilent Arty-7
-   Xilinx Artix-7
-   DDR3

### HDL

-   Verilog HDL

### FPGA Tools

-   Xilinx Vivado
-   Xilinx MIG
-   Xilinx AXI IP

### Processor

-   RISC-V
-   RV32IM

### Interfaces

-   AXI4
-   AXI4-Lite
-   UART
-   SPI
-   GPIO
-   DDR3

### Version Control

-   Git
-   GitHub
-   Git Submodules

------------------------------------------------------------------------

## Project Status

``` text
RTL Design              ✓
System Integration      ✓
Simulation              ✓
Synthesis               ✓
Implementation           ✓
Resource Analysis       ✓
Power Estimation        ✓
GitHub Documentation    ✓
Hardware Stress Testing Planned
```

------------------------------------------------------------------------

## Author

**Barath Kumar M**

M.E. VLSI Design and Embedded Systems\
Anna University -- MIT Campus

GitHub:\
https://github.com/BarathKumarMS

------------------------------------------------------------------------

## Disclaimer

This repository contains project-specific FPGA integration,
verification, configuration, and documentation built around an
open-source RISC-V SoC platform.

The original RISC-V processor and upstream SoC components remain subject
to their respective upstream licenses and copyrights.

Please refer to the upstream repository and its license before
redistributing or modifying upstream components.
