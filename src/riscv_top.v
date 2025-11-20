// ============================================================
// File: riscv_top.v
// Description: Top-level system integrating PicoRV32 core + RAM
// This is the DUT for simulation (connects CPU <-> Memory)
// ============================================================

`timescale 1ns / 1ps

module riscv_top (
    input wire clk,
    input wire rst
);

    // ============================================
    // PicoRV32 <-> Memory Bus Signals
    // ============================================

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    // ============================================
    // Instantiate PicoRV32 Core
    // ============================================
    picorv32 #(
        .ENABLE_COUNTERS(0),
        .ENABLE_COUNTERS64(0),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .TWO_STAGE_SHIFT(1),
        .BARREL_SHIFTER(0),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .COMPRESSED_ISA(0),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_IRQ_QREGS(0),
        .ENABLE_IRQ_TIMER(0),
        .LATCHED_MEM_RDATA(0),
        .TWO_STAGE_FETCH(0)
    ) cpu_core (
        .clk         (clk),
        .resetn      (~rst),
        .mem_valid   (mem_valid),
        .mem_instr   (mem_instr),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata),
        .trap        ()
    );

    // ============================================
    // Instantiate RAM Model
    // ============================================
    ram_model #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (12),
        .MEM_FILE   ("program.mem")
    ) ram_inst (
        .clk        (clk),
        .rst        (rst),
        .mem_valid  (mem_valid),
        .mem_wstrb  (|mem_wstrb),          // Write enable
        .mem_addr   (mem_addr[13:2]),      // Word addressing (ignore lower 2 bits)
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .mem_ready  (mem_ready)
    );

endmodule
