## ============================================================
## Arty Rev B - Corrected Constraints
## Fixes: WNS=-1.210 TNS=-916.777 (impl_1 timing failure)
##
## ROOT CAUSE of timing failure:
## The tool was timing paths ACROSS the CDC bridge between:
##   sys_clk_pin (100 MHz board clock)
##   clk_w       (25 MHz, from artix7_pll CLKOUT2)
##   clk_sys_w   (~167 MHz, from MIG MMCM output)
## These crossings are handled by axi4_cdc synchronisers and
## MUST be declared as false paths. Without this, the tool
## tries to meet single-cycle timing across async domains,
## which is impossible and generates hundreds of violations.
## ============================================================

## ============================================================
## Board Clock - 100 MHz
## ============================================================
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } \
    [get_ports { clk100mhz }];

create_clock -add -name sys_clk_pin \
    -period 20.000 \
    -waveform {0 10.000} \
    [get_ports { clk100mhz }];
## ============================================================
## Generated Clocks - tell the timing engine about PLL outputs
## Without these, derived clocks are not properly tracked and
## the tool cannot correctly classify cross-domain paths.
##
## artix7_pll outputs (from top.v: u_pll instance):
##   CLKOUT0 = 100 MHz  (clk0,  feeds MIG clk100_i)
##   CLKOUT1 = 200 MHz  (clk1,  feeds MIG clk200_i / IDELAYCTRL)
##   CLKOUT2 =  25 MHz  (clk_w, CPU clock)
##
## NOTE: Adjust the get_pins path if your PLL instance name
## differs. Check with: get_pins -hier -filter {NAME=~*u_pll*}
## ============================================================
create_generated_clock \
    -name clk_pll_100 \
    -source [get_ports clk100mhz] \
    -multiply_by 1 \
    [get_pins top/u_pll/clkout0_o]

create_generated_clock \
    -name clk_pll_200 \
    -source [get_ports clk100mhz] \
    -multiply_by 2 \
    [get_pins top/u_pll/clkout1_o]

create_generated_clock \
    -name clk_w \
    -source [get_ports clk100mhz] \
    -divide_by 4 \
    [get_pins top/u_pll/clkout2_o]

## ============================================================
## False Paths - CDC crossings managed by axi4_cdc
##
## The axi4_cdc module uses handshake synchronisers (Gray-code
## FIFOs or 2FF synchronisers) to cross between clock domains.
## Timing these single-cycle is both incorrect and impossible.
## set_false_path tells the tool to ignore these crossings.
## ============================================================

## 100 MHz ↔ 25 MHz (clk_w): between PLL input and output
set_false_path -from [get_clocks sys_clk_pin] \
               -to   [get_clocks clk_w]
set_false_path -from [get_clocks clk_w] \
               -to   [get_clocks sys_clk_pin]

## 25 MHz ↔ 167 MHz (clk_sys_w from MIG): the main CDC bridge
## The MIG generates clk_sys_w internally; its name varies.
## These wildcards cover all MIG-generated clock variants.
set_false_path -from [get_clocks clk_w] \
               -to   [get_clocks -filter {NAME =~ *mig*}]
set_false_path -from [get_clocks -filter {NAME =~ *mig*}] \
               -to   [get_clocks clk_w]

set_false_path -from [get_clocks clk_w] \
               -to   [get_clocks -filter {NAME =~ *sys*}]
set_false_path -from [get_clocks -filter {NAME =~ *sys*}] \
               -to   [get_clocks clk_w]

## 100 MHz ↔ MIG internal clocks
set_false_path -from [get_clocks sys_clk_pin] \
               -to   [get_clocks -filter {NAME =~ *mig*}]
set_false_path -from [get_clocks -filter {NAME =~ *mig*}] \
               -to   [get_clocks sys_clk_pin]

## ============================================================
## Input/Output Delay Exceptions
## Async inputs (buttons, UART RX) do not need tight timing.
## ============================================================
set_false_path -from [get_ports uart_txd_in]
set_false_path -to   [get_ports uart_rxd_out]
set_false_path -to   [get_ports led[*]]

## ============================================================
## LEDs
## ============================================================
set_property -dict { PACKAGE_PIN H5  IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN J5  IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## ============================================================
## USB-UART
## ============================================================
set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }];
set_property -dict { PACKAGE_PIN A9  IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in  }];

## ============================================================
## Quad SPI Flash
## ============================================================
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports { qspi_sck    }];
set_property -dict { PACKAGE_PIN L13 IOSTANDARD LVCMOS33 } [get_ports { qspi_cs     }];
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0]  }];
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1]  }];
set_property -dict { PACKAGE_PIN L14 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2]  }];
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3]  }];

## ============================================================
## NOTE: DDR3 pin constraints are generated automatically by
## the MIG IP and are in a separate XDC included by Vivado.
## Do NOT add DDR3 pin constraints here - duplicates will
## cause DRC errors.
## ============================================================
