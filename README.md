\# RISC-V Multi-Gateway FPGA



\## Overview



This project explores a RISC-V based multi-gateway embedded system implemented on an Artix-7 FPGA.



The project is based on the open-source UltraEmbedded RISC-V SoC platform and was used to study and understand RISC-V SoC integration, AXI-based communication, FPGA clocking, DDR3/MIG integration, clock-domain crossing, peripheral interfaces, and FPGA implementation using Xilinx Vivado.



\## Architecture



The system integrates:



\- RISC-V RV32IM processor

\- AXI4 / AXI4-Lite based interconnect

\- DDR3 memory through Xilinx MIG

\- AXI clock-domain crossing

\- UART

\- SPI

\- GPIO

\- Timer

\- Interrupt controller

\- FPGA clocking / PLL

\- Debug infrastructure



\## FPGA Platform



\- Board: Digilent Arty-7

\- FPGA: Xilinx Artix-7

\- Device: XC7A35T-1CSG324-1L

\- Tool: Xilinx Vivado



\## Verification



A project-level Verilog testbench is included under `testbench/`.



The testbench provides:



\- Clock and reset generation

\- Instruction and data bus response

\- Firmware initialization

\- Instruction-fetch monitoring

\- UART transmission monitoring

\- DDR3-side response stubs

\- QSPI-related signal stubs



The testbench was used to study and verify the integrated SoC behavior during project development.



\## Repository Structure



```text

RISC-V-MultiGateway-FPGA/

├── constraints/

│   └── arty\_revb.xdc

├── fpga/

│   └── arty/

├── ip/

│   ├── axi\_cdc\_buffer/

│   └── mig\_axis/

├── testbench/

│   └── top\_tb.v

├── vivado/

│   └── block\_design/

├── upstream/

│   └── riscv\_soc/

├── images/

├── results/

├── .gitignore

├── .gitmodules

└── README.md

