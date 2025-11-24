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
    // PCPI (co-processor) interface wires
    // ============================================
    wire        pcpi_valid;
    wire [31:0] pcpi_insn;
    wire [31:0] pcpi_rs1;
    wire [31:0] pcpi_rs2;
    wire        pcpi_wr;
    wire [31:0] pcpi_rd;
    wire        pcpi_ready;

    // ============================================
    // Instantiate PicoRV32 Core (connect PCPI)
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

        // PCPI interface
        .pcpi_valid  (pcpi_valid),
        .pcpi_insn   (pcpi_insn),
        .pcpi_rs1    (pcpi_rs1),
        .pcpi_rs2    (pcpi_rs2),
        .pcpi_wr     (),         // picorv32 may expose these as outputs when using pcpi, keep them unconnected
        .pcpi_rd     (), 
        .pcpi_ready  (),

        .trap        ()
    );

    // ============================================
    // Instantiate RAM Model (use relative path to program.mem)
    // ============================================
    ram_model #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (12),
        .MEM_FILE   ("sim/program.mem")
    ) ram_inst (
        .clk        (clk),
        .rst        (rst),
        .mem_valid  (mem_valid),
        .mem_wstrb  (mem_wstrb),          // pass full byte strobe
        .mem_addr   (mem_addr[13:2]),     // Word addressing (ignore low 2 bits)
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .mem_ready  (mem_ready)
    );

    // ============================================
    // Connect PCPI ports to the SHA accelerator
    // NOTE: picorv32's PCPI signals are outputs/inputs defined above.
    // We use wires named exactly as picorv32 ports in the instantiation.
    // ============================================
    // Instantiate SHA PCPI coprocessor
    pcpi_sha sha_coproc (
        .clk        (clk),
        .resetn     (~rst),
        .pcpi_valid (pcpi_valid),
        .pcpi_insn  (pcpi_insn),
        .pcpi_rs1   (pcpi_rs1),
        .pcpi_rs2   (pcpi_rs2),
        .pcpi_wr    (pcpi_wr),
        .pcpi_rd    (pcpi_rd),
        .pcpi_ready (pcpi_ready)
    );

endmodule
