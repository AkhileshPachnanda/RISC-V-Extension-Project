`timescale 1ns / 1ps

module riscv_top (
    input wire clk,
    input wire rst          // ACTIVE-HIGH reset from testbench
);

    // CPU <-> memory bus
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    // Unified instruction/data memory
    assign mem_instr = mem_valid;

    // Lookahead (unused)
    wire        mem_la_read  = 1'b0;
    wire        mem_la_write = 1'b0;
    wire [31:0] mem_la_addr  = 32'b0;
    wire [31:0] mem_la_wdata = 32'b0;
    wire [3:0]  mem_la_wstrb = 4'b0;

    // PCPI interface
    wire        pcpi_valid, pcpi_wr, pcpi_wait, pcpi_ready;
    wire [31:0] pcpi_insn, pcpi_rs1, pcpi_rs2, pcpi_rd;

    // Unused CPU outputs
    wire        trap;
    wire [31:0] eoi;
    wire        trace_valid;
    wire [35:0] trace_data;

    // ---------------------- CPU core ----------------------
    picorv32 #(
        .ENABLE_PCPI(1),
        .ENABLE_MUL(1),
        .ENABLE_DIV(1),
        .ENABLE_IRQ(0),
        .ENABLE_TRACE(0),
        .ENABLE_REGS_DUALPORT(1),
        .ENABLE_REGS_16_31(1),
        .LATCHED_MEM_RDATA(0),
        .PROGADDR_RESET(32'h00000000),
        .PROGADDR_IRQ(   32'h00000010),
        .STACKADDR(      32'h00100000)
    ) cpu_core (
        .clk        (clk),
        .resetn     (~rst),     // ACTIVE-LOW reset INTO CPU

        .mem_valid  (mem_valid),
        .mem_instr  (mem_instr),
        .mem_ready  (mem_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata),

        .mem_la_read(mem_la_read),
        .mem_la_write(mem_la_write),
        .mem_la_addr(mem_la_addr),
        .mem_la_wdata(mem_la_wdata),
        .mem_la_wstrb(mem_la_wstrb),

        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
        .pcpi_rs2(pcpi_rs2),
        .pcpi_wr(pcpi_wr),
        .pcpi_rd(pcpi_rd),
        .pcpi_wait(pcpi_wait),
        .pcpi_ready(pcpi_ready),

        .irq(32'b0),
        .eoi(eoi),
        .trace_valid(trace_valid),
        .trace_data(trace_data),
        .trap(trap)
    );

    // ---------------------- PCPI SHA ----------------------
    pcpi_sha sha_accel (
        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
        .pcpi_rs2(pcpi_rs2),
        .pcpi_wr(pcpi_wr),
        .pcpi_rd(pcpi_rd),
        .pcpi_wait(pcpi_wait),
        .pcpi_ready(pcpi_ready)
    );

    // ---------------------- RAM ----------------------
    ram_model #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (20),
        .MEM_FILE   ("C:/Users/devan/Documents/GitHub/RISC-V/RISC-V-Extension-Project/sim/program.mem")
    ) ram_inst (
        .clk       (clk),
        .resetn    (~rst),      // SAME reset polarity as CPU
        .mem_valid (mem_valid),
        .mem_wstrb (mem_wstrb),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_rdata (mem_rdata),
        .mem_ready (mem_ready)
    );

endmodule
