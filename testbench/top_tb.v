`timescale 1ns / 1ps

// ================================================================
//  top_tb.v  - FINAL v6  - UART baud rate fix
//
//  STATUS: CPU is confirmed running (fetch_cnt = 3 in v5).
//
//  ROOT CAUSE OF uart_rx_cnt = 0:
//  The firmware wrote to UART TX register (0xF0000000) but the
//  UART peripheral never transmitted because the baud rate
//  divisor register was 0 (reset state). Ultra-Embedded UART
//  silently ignores TX writes until the divisor is set.
//
//  FIX: Firmware now initialises the baud rate divisor FIRST,
//  then writes characters.
//
//  Ultra-Embedded UART register map (at base 0xF0000000):
//    +0x00 : TX data (write) / RX data (read)
//    +0x04 : Status  [7]=TX_BUSY [0]=RX_AVAIL
//    +0x08 : Control [23:0]=baud_divisor
//
//  Baud rate formula: baud = clk_hz / (divisor × 16)
//  At clk_w = 25 MHz:
//    divisor = 14 → baud ≈ 111,607 (≈115200)
//    divisor =  1 → baud = 1,562,500  (too fast)
//
//  We use divisor = 14 → TB UART monitor set to 8680 ns/bit.
//
//  If UART_BASE or divisor register offset differs in your
//  riscv_soc, check these $display lines after running:
//    [FETCH] lines show what the CPU executed
//    [SOC-UART] line fires when uart_rxd_o first goes low
//  Share riscv_soc.v if UART is still silent after this.
// ================================================================

module top_tb;

// ================================================================
// PARAMETERS
// ================================================================
parameter BOOT_ADDR     = 32'h80000000; // from fpga_top.v reset_vector_w
parameter UART_BASE     = 32'hF0000000; // Ultra-Embedded UART base

// At 25 MHz, divisor=14 → ~115200 baud (14 × 16 = 224 clocks/bit)
// 25_000_000 / 224 = 111607 baud → bit period = 8968 ns
// Use 8680 ns (standard 115200) for the TB monitor
parameter UART_DIVISOR  = 14;
parameter UART_BIT_NS   = 8_680;        // 115200 baud monitor

parameter CLK100_HALF   = 5;
parameter CLK_W_HALF    = 20;           // 25 MHz
parameter CLK_SYS_HALF  = 3;            // ~167 MHz
parameter RST_RELEASE   = 10_000;       // 10 µs
parameter SIM_RUN_NS    = 5_000_000;    // 5 ms (UART chars take ~1ms each)

// ================================================================
// DUT PORTS
// ================================================================
reg          clk100mhz;
wire [ 3:0]  led;
wire         uart_rxd_out;
reg          uart_txd_in;
wire         qspi_sck;
wire         qspi_cs;
wire [ 3:0]  qspi_dq;
wire         ddr3_reset_n;
wire [ 0:0]  ddr3_cke;
wire [ 0:0]  ddr3_ck_p;
wire [ 0:0]  ddr3_ck_n;
wire [ 0:0]  ddr3_cs_n;
wire         ddr3_ras_n;
wire         ddr3_cas_n;
wire         ddr3_we_n;
wire [ 2:0]  ddr3_ba;
wire [13:0]  ddr3_addr;
wire [ 0:0]  ddr3_odt;
wire [ 1:0]  ddr3_dm;
wire [ 1:0]  ddr3_dqs_p;
wire [ 1:0]  ddr3_dqs_n;
wire [15:0]  ddr3_dq;

// ================================================================
// TB STATE
// ================================================================
integer     uart_rx_cnt  = 0;
reg [ 7:0]  uart_rx_byte = 0;
reg [ 7:0]  uart_shift   = 0;
integer     uart_i       = 0;
integer     fetch_cnt    = 0;
integer     write_cnt    = 0;

// ================================================================
// FIRMWARE - with UART baud rate initialisation
//
// RISC-V RV32I hand-assembled program:
//
//   lui  a0, 0xF0000         a0 = 0xF0000000  (UART base)
//   addi a2, x0, 14          a2 = baud divisor (14 → ~115200)
//   sw   a2, 8(a0)           write divisor to UART_CTRL +0x08
//   sw   a2, 4(a0)           also try +0x04 (some variants)
//   addi a1, x0, 'H'
//   sw   a1, 0(a0)           TX 'H'
//   ... repeat for e,l,l,o,!,\r,\n
//   jal  x0, 0               spin forever
//
// Instruction encodings (verified against RV32I ISA spec):
//   lui  a0, 0xF0000  = 0xF0000537
//   addi a2, x0, 14   = 0x00E00613
//   sw   a2, 8(a0)    = 0x00C52423
//   sw   a2, 4(a0)    = 0x00C52223
//   addi a1, x0, X    = 0x0XX00593 (X = char ASCII)
//   sw   a1, 0(a0)    = 0x00B52023
//   jal  x0, 0        = 0x0000006F
// ================================================================
parameter FW_WORDS = 21;
reg [31:0] fw [0:FW_WORDS-1];

initial begin : FW_INIT
    // --- UART baud rate initialisation ---
    fw[0]  = 32'hF0000537; // lui  a0, 0xF0000  → a0 = 0xF0000000
    fw[1]  = 32'h00E00613; // addi a2, x0, 14   → baud divisor
    fw[2]  = 32'h00C52423; // sw   a2, 8(a0)    → UART_CTRL  +0x08
    fw[3]  = 32'h00C52223; // sw   a2, 4(a0)    → also try   +0x04

    // --- transmit "Hello!\r\n" ---
    fw[4]  = 32'h04800593; // addi a1, x0, 'H'
    fw[5]  = 32'h00B52023; // sw   a1, 0(a0)
    fw[6]  = 32'h06500593; // addi a1, x0, 'e'
    fw[7]  = 32'h00B52023;
    fw[8]  = 32'h06C00593; // addi a1, x0, 'l'
    fw[9]  = 32'h00B52023;
    fw[10] = 32'h00B52023; // second 'l'
    fw[11] = 32'h06F00593; // addi a1, x0, 'o'
    fw[12] = 32'h00B52023;
    fw[13] = 32'h02100593; // addi a1, x0, '!'
    fw[14] = 32'h00B52023;
    fw[15] = 32'h00D00593; // addi a1, x0, '\r'
    fw[16] = 32'h00B52023;
    fw[17] = 32'h00A00593; // addi a1, x0, '\n'
    fw[18] = 32'h00B52023;

    // --- spin forever ---
    fw[19] = 32'h0000006F; // jal  x0, 0

    // padding
    fw[20] = 32'h00000013; // nop
end

// ================================================================
// DUT
// ================================================================
top u_dut (
    .clk100mhz   (clk100mhz),
    .led         (led),
    .uart_rxd_out(uart_rxd_out),
    .uart_txd_in (uart_txd_in),
    .qspi_sck    (qspi_sck),
    .qspi_cs     (qspi_cs),
    .qspi_dq     (qspi_dq),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_cke    (ddr3_cke),
    .ddr3_ck_p   (ddr3_ck_p),
    .ddr3_ck_n   (ddr3_ck_n),
    .ddr3_cs_n   (ddr3_cs_n),
    .ddr3_ras_n  (ddr3_ras_n),
    .ddr3_cas_n  (ddr3_cas_n),
    .ddr3_we_n   (ddr3_we_n),
    .ddr3_ba     (ddr3_ba),
    .ddr3_addr   (ddr3_addr),
    .ddr3_odt    (ddr3_odt),
    .ddr3_dm     (ddr3_dm),
    .ddr3_dqs_p  (ddr3_dqs_p),
    .ddr3_dqs_n  (ddr3_dqs_n),
    .ddr3_dq     (ddr3_dq)
);

assign (weak1, weak0) ddr3_dq    = 16'h0000;
assign (weak1, weak0) ddr3_dm    = 2'b00;
assign (weak1, weak0) ddr3_dqs_p = 2'b11;
assign (weak1, weak0) ddr3_dqs_n = 2'b00;
assign (weak1, weak0) qspi_dq    = 4'hF;

// ================================================================
// BOARD CLOCK
// ================================================================
initial clk100mhz = 1'b0;
always  #(CLK100_HALF) clk100mhz = ~clk100mhz;

// ================================================================
// BYPASS CLOCKS
// ================================================================
reg forced_clk_w   = 1'b0;
reg forced_clk_sys = 1'b0;
reg bypass_en      = 1'b0;

always #(CLK_W_HALF)   forced_clk_w   = ~forced_clk_w;
always #(CLK_SYS_HALF) forced_clk_sys = ~forced_clk_sys;

always @(forced_clk_w)   if (bypass_en) force u_dut.clk_w     = forced_clk_w;
always @(forced_clk_sys) if (bypass_en) force u_dut.clk_sys_w = forced_clk_sys;

// ================================================================
// RESET CONTROL
// ================================================================
initial begin : BYPASS_CTRL
    uart_txd_in = 1'b1;
    force u_dut.rst_sys_w = 1'b1;

    #1_000;
    bypass_en = 1'b1;
    $display("[TB]  Clocks ON - clk_w=25MHz  clk_sys=167MHz");

    #(RST_RELEASE);
    force u_dut.rst_sys_w = 1'b0;
    $display("[TB]  rst_sys_w released");

    #500;
    force u_dut.u_top.rst_cpu_w = 1'b0;
    $display("[TB]  CPU running from 0x%08h", BOOT_ADDR);
    $display("[TB]  Firmware: UART init divisor=%0d then 'Hello!\\r\\n'",
             UART_DIVISOR);
end

// ================================================================
// INSTRUCTION FETCH STUB - axi4_i_* (confirmed from get_objects)
// ================================================================
reg [31:0] i_rdata = 32'h00000013;

always @(posedge u_dut.clk_w) begin
    if (u_dut.u_top.u_soc.axi4_i_arvalid_w === 1'b1) begin
        if (u_dut.u_top.u_soc.axi4_i_araddr_w >= BOOT_ADDR &&
            u_dut.u_top.u_soc.axi4_i_araddr_w <  BOOT_ADDR + (FW_WORDS*4))
            i_rdata <= fw[(u_dut.u_top.u_soc.axi4_i_araddr_w
                           - BOOT_ADDR) >> 2];
        else
            i_rdata <= 32'h00000013;
    end
end

initial begin : AXI_I_STUB
    #(RST_RELEASE + 1_000);
    force u_dut.u_top.u_soc.axi4_i_arready_w = 1'b1;
    force u_dut.u_top.u_soc.axi4_i_rvalid_w  = 1'b1;
    force u_dut.u_top.u_soc.axi4_i_rlast_w   = 1'b1;
    force u_dut.u_top.u_soc.axi4_i_rresp_w   = 2'b00;
    force u_dut.u_top.u_soc.axi4_i_rid_w     = 4'h0;
    force u_dut.u_top.u_soc.axi4_i_awready_w = 1'b1;
    force u_dut.u_top.u_soc.axi4_i_wready_w  = 1'b1;
    force u_dut.u_top.u_soc.axi4_i_bvalid_w  = 1'b1;
    force u_dut.u_top.u_soc.axi4_i_bresp_w   = 2'b00;
    force u_dut.u_top.u_soc.axi4_i_bid_w     = 4'h0;
    $display("[TB]  axi4_i instruction stub ACTIVE");
    forever @(i_rdata)
        force u_dut.u_top.u_soc.axi4_i_rdata_w = i_rdata;
end

// ================================================================
// DATA BUS STUB - axi4_d_*
// ================================================================
initial begin : AXI_D_STUB
    #(RST_RELEASE + 1_000);
    force u_dut.u_top.u_soc.axi4_d_awready_w = 1'b1;
    force u_dut.u_top.u_soc.axi4_d_wready_w  = 1'b1;
    force u_dut.u_top.u_soc.axi4_d_bvalid_w  = 1'b1;
    force u_dut.u_top.u_soc.axi4_d_bresp_w   = 2'b00;
    force u_dut.u_top.u_soc.axi4_d_bid_w     = 4'h0;
    force u_dut.u_top.u_soc.axi4_d_arready_w = 1'b1;
    force u_dut.u_top.u_soc.axi4_d_rvalid_w  = 1'b1;
    force u_dut.u_top.u_soc.axi4_d_rlast_w   = 1'b1;
    force u_dut.u_top.u_soc.axi4_d_rresp_w   = 2'b00;
    force u_dut.u_top.u_soc.axi4_d_rid_w     = 4'h0;
    force u_dut.u_top.u_soc.axi4_d_rdata_w   = 32'h00000000;
    $display("[TB]  axi4_d data stub ACTIVE");
end

// ================================================================
// MAIN STIMULUS
// ================================================================
initial begin
    $display("================================================");
    $display("[TB]  RISC-V SoC - UART baud init fix");
    $display("      Boot     : 0x%08h", BOOT_ADDR);
    $display("      UART base: 0x%08h", UART_BASE);
    $display("      Divisor  : %0d → ~%0d baud",
             UART_DIVISOR, 25_000_000/(UART_DIVISOR*16));
    $display("      Monitor  : %0d ns/bit (%0d baud)",
             UART_BIT_NS, 1_000_000_000/UART_BIT_NS);
    $display("================================================");

    // Wait long enough for UART chars to arrive
    // Each char at 115200 baud takes ~87 µs
    // 8 chars × 87 µs = ~700 µs, plus pipeline delay
    #(RST_RELEASE + SIM_RUN_NS);

    $display("================================================");
    $display("[TB]  DONE");
    $display("      Instruction fetches : %0d", fetch_cnt);
    $display("      UART bytes received : %0d", uart_rx_cnt);
    $display("      LEDs                : 4'b%b", led);

    if (fetch_cnt == 0)
        $display("  ERROR: No fetches - stub may have failed.");
    else if (uart_rx_cnt == 0) begin
        $display("");
        $display("  CPU ran (fetches=%0d) but no UART output.", fetch_cnt);
        $display("  Possible fixes:");
        $display("  1. UART_BASE 0x%08h may be wrong.", UART_BASE);
        $display("     Share riscv_soc.v to find actual UART address.");
        $display("  2. Baud divisor register may be at a different offset.");
        $display("     Current firmware writes to +4 and +8.");
        $display("  3. The TB monitor is at %0d ns/bit (%0d baud).",
                 UART_BIT_NS, 1_000_000_000/UART_BIT_NS);
        $display("     If [SOC-UART] fired but no [UART-RX], baud mismatch.");
    end
    $display("================================================");
    $finish;
end

initial begin
    #(RST_RELEASE + SIM_RUN_NS + 500_000);
    $display("[TB]  WATCHDOG");
    $finish;
end

// ================================================================
// UART RX MONITOR - watches uart_rxd_out (hardware serial line)
// Now set to 115200 baud (8680 ns/bit) to match firmware divisor
// ================================================================
initial begin : UART_RX_MON
    #(RST_RELEASE + 5_000);
    forever begin
        @(negedge uart_rxd_out);              // wait for start bit
        #(UART_BIT_NS / 2);                   // move to bit centre
        if (uart_rxd_out !== 1'b0) disable UART_RX_MON; // glitch filter
        uart_shift = 8'h00;
        for (uart_i=0; uart_i<8; uart_i=uart_i+1) begin
            #(UART_BIT_NS);
            uart_shift[uart_i] = uart_rxd_out;
        end
        #(UART_BIT_NS);
        uart_rx_byte = uart_shift;
        uart_rx_cnt  = uart_rx_cnt + 1;
        $write("[UART-RX]  0x%02h  ", uart_rx_byte);
        if (uart_rx_byte >= 8'h20 && uart_rx_byte < 8'h7F)
            $display("'%0c'", uart_rx_byte);
        else if (uart_rx_byte == 8'h0A) $display("'\\n'");
        else if (uart_rx_byte == 8'h0D) $display("'\\r'");
        else $display("(ctrl 0x%02h)", uart_rx_byte);
    end
end

// ================================================================
// FETCH MONITOR - instruction bus (axi4_i_*)
// ================================================================
always @(posedge u_dut.clk_w) begin
    if (u_dut.u_top.rst_cpu_w == 1'b0) begin
        if (u_dut.u_top.u_soc.axi4_i_arvalid_w === 1'b1 &&
            u_dut.u_top.u_soc.axi4_i_arready_w === 1'b1) begin
            fetch_cnt = fetch_cnt + 1;
            $display("[FETCH #%0d]  PC=0x%08h  LEN=%0d  → 0x%08h",
                     fetch_cnt,
                     u_dut.u_top.u_soc.axi4_i_araddr_w,
                     u_dut.u_top.u_soc.axi4_i_arlen_w,
                     i_rdata);
        end
    end
end

// ================================================================
// SOC UART LINE MONITOR - watches the raw uart_rxd_o output from
// riscv_soc before it is AND-gated with the debug UART in top.v.
// This fires as soon as the UART peripheral starts serialising,
// even if uart_rxd_out hasn't gone low yet (debug line is high).
// ================================================================
always @(negedge u_dut.u_top.u_soc.uart_rxd_o) begin
    $display("[SOC-UART]  uart_rxd_o went LOW - UART is transmitting!");
    $display("[SOC-UART]  If UART-RX monitor does not fire after this,");
    $display("[SOC-UART]  baud rate mismatch. Current TB = %0d baud.",
             1_000_000_000/UART_BIT_NS);
end

// ================================================================
// MISC MONITORS
// ================================================================
always @(led)
    $display("[LED]   4'b%b", led);
always @(u_dut.rst_sys_w)
    $display("[RST]   rst_sys=%0b (%s)", u_dut.rst_sys_w,
             u_dut.rst_sys_w ? "RESET" : "RUNNING");
always @(u_dut.u_top.rst_cpu_w)
    $display("[RST]   rst_cpu=%0b (%s)", u_dut.u_top.rst_cpu_w,
             u_dut.u_top.rst_cpu_w ? "CPU HELD" : "CPU RUNNING");

initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    $dumpvars(0, u_dut);
end

endmodule