// src/pcpi_sha.v
// Simple PCPI coprocessor for Sigma0: Sigma0(x) = ROTR(x,2) ^ ROTR(x,13) ^ ROTR(x,22)
// Detects CUSTOM_0 (opcode 0001011) with funct3==3'b000 and returns result in rd.
// Combinational ready (immediate response).

`timescale 1ns/1ps

module pcpi_sha (
    input  wire        clk,         // optional; not used for combinational path
    input  wire        resetn,      // optional
    input  wire        pcpi_valid,
    input  wire [31:0] pcpi_insn,
    input  wire [31:0] pcpi_rs1,
    input  wire [31:0] pcpi_rs2,

    output reg         pcpi_wr,
    output reg  [31:0] pcpi_rd,
    output reg         pcpi_ready
);

    // Instruction fields
    wire [6:0] opcode = pcpi_insn[6:0];
    wire [2:0] funct3 = pcpi_insn[14:12];

    // Custom-0 opcode = 7'b0001011
    localparam [6:0] OPC_CUSTOM0 = 7'b0001011;

    // rot right helper
    function [31:0] rotr;
        input [31:0] x;
        input integer n;
        begin
            rotr = (x >> n) | (x << (32-n));
        end
    endfunction

    always @(*) begin
        // defaults
        pcpi_wr    = 1'b0;
        pcpi_rd    = 32'b0;
        pcpi_ready = 1'b0;

        if (pcpi_valid) begin
            if ((opcode == OPC_CUSTOM0) && (funct3 == 3'b000)) begin
                // compute Sigma0(rs1)
                pcpi_rd = rotr(pcpi_rs1, 2) ^ rotr(pcpi_rs1, 13) ^ rotr(pcpi_rs1, 22);
                pcpi_wr = 1'b1;
                pcpi_ready = 1'b1;
            end
        end
    end

endmodule
