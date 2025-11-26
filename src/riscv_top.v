`timescale 1ns/1ps

// src/riscv_top.v
// Minimal top: pico core + RAM + PCPI SHA accelerator
module riscv_top (
    input wire clk,
    input wire rst
);

    // PicoRV32 <-> Memory Bus Signals
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    // "look-ahead" ports (tie to 0 if not used)
    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [3:0]  mem_la_wstrb;

    // PCPI interface
    wire        pcpi_valid;
    wire [31:0] pcpi_insn;
    wire [31:0] pcpi_rs1;
    wire [31:0] pcpi_rs2;
    wire        pcpi_wr;
    wire [31:0] pcpi_rd;
    wire        pcpi_wait;
    wire        pcpi_ready;

    // Unused output ports from PicoRV32
    wire        trap;
    wire [31:0] eoi;
    wire        trace_valid;
    wire [35:0] trace_data;

    // Tie off unused signals
    assign mem_la_read  = 1'b0;
    assign mem_la_write = 1'b0;
    assign mem_la_addr  = 32'b0;
    assign mem_la_wdata = 32'b0;
    assign mem_la_wstrb = 4'b0;

    // Instantiate PicoRV32 with parameters to disable unused features
    picorv32 #(
        .ENABLE_PCPI(0),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_TRACE(0)
    ) cpu_core (
        .clk           (clk),
        .resetn        (~rst),

        .mem_valid     (mem_valid),
        .mem_instr     (mem_instr),
        .mem_ready     (mem_ready),

        .mem_addr      (mem_addr),
        .mem_wdata     (mem_wdata),
        .mem_wstrb     (mem_wstrb),
        .mem_rdata     (mem_rdata),

        // optional lookahead ports (tied above)
        .mem_la_read   (mem_la_read),
        .mem_la_write  (mem_la_write),
        .mem_la_addr   (mem_la_addr),
        .mem_la_wdata  (mem_la_wdata),
        .mem_la_wstrb  (mem_la_wstrb),

        // PCPI interface
        .pcpi_valid    (pcpi_valid),
        .pcpi_insn     (pcpi_insn),
        .pcpi_rs1      (pcpi_rs1),
        .pcpi_rs2      (pcpi_rs2),
        .pcpi_wr       (pcpi_wr),
        .pcpi_rd       (pcpi_rd),
        .pcpi_wait     (pcpi_wait),
        .pcpi_ready    (pcpi_ready),

        // Tie IRQ input; connect unused outputs to wires
        .irq           (32'b0),
        .eoi           (eoi),
        .trace_valid   (trace_valid),
        .trace_data    (trace_data),
        .trap          (trap)
    );

    // Instantiate PCPI SHA (connect pcpi signals; assuming combinational, no clk/rst)
    pcpi_sha sha_accel (
        .pcpi_valid  (pcpi_valid),
        .pcpi_insn   (pcpi_insn),
        .pcpi_rs1    (pcpi_rs1),
        .pcpi_rs2    (pcpi_rs2),
        .pcpi_wr     (pcpi_wr),
        .pcpi_rd     (pcpi_rd),
        .pcpi_wait   (pcpi_wait),
        .pcpi_ready  (pcpi_ready)
    );

    // Instantiate RAM model
    // Adjust ADDR_WIDTH to match your model (here we use 12 -> 4K words = 16KB)
    // MEM_FILE must be an absolute or relative path to sim/program.mem
    ram_model #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (12),
        .MEM_FILE   ("sim/program.mem")
    ) ram_inst (
        .clk        (clk),
        .rst        (rst),
        .mem_valid  (mem_valid),
        .mem_wstrb  (mem_wstrb),
        .mem_addr   (mem_addr[13:2]), // word address (drop lower 2 bits for byte addr)
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .mem_ready  (mem_ready)
    );

endmodule