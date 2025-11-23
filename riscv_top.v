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
    // Instantiate PicoRV32 Core (no parameter overrides)
    // (Assumes picorv32.v is compatible with these port names.)
    // ============================================
    picorv32 cpu_core (
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
    // Instantiate RAM Model (larger address space)
    // mem_addr[17:2] -> byte address bits [17:2] => word index for 2^16 words
    // ============================================
    ram_model #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (16),
        .MEM_FILE   ("D:/RISC-V-Extension-Project/sim/program.mem")
    ) ram_inst (
        .clk        (clk),
        .rst        (rst),
        .mem_valid  (mem_valid),
        .mem_wstrb  (mem_wstrb),
        .mem_addr   (mem_addr[17:2]),
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .mem_ready  (mem_ready)
    );

endmodule
