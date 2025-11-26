`timescale 1ns / 1ps

module ram_model #(
    parameter DATA_WIDTH = 32,               // word width returned on reads
    parameter ADDR_WIDTH = 20,               // increased to 20 for 1MB to cover high addresses
    parameter MEM_FILE   = "sim/program.mem" // $readmemh file (expected as byte tokens)
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     mem_valid,                   // request valid (word access)
    input  wire [3:0]               mem_wstrb,                   // per-byte write strobes
    input  wire [ADDR_WIDTH-1:0]    mem_addr,                    // WORD index (as used by riscv_top: mem_addr[31:2])
    input  wire [DATA_WIDTH-1:0]    mem_wdata,
    output reg  [DATA_WIDTH-1:0]    mem_rdata,
    output wire                     mem_ready                    // changed to wire for combinational
);

    // Total number of bytes = 2^(ADDR_WIDTH + 2)
    localparam BYTE_ADDR_WIDTH = ADDR_WIDTH + 2;
    localparam MEM_BYTES = (1 << (ADDR_WIDTH + 2));

    // Byte-addressable memory array
    reg [7:0] memory_bytes [0:MEM_BYTES-1];

    // integers (declared at module scope for ModelSim)
    integer i;
    integer base;

    // For $readmemh which produces byte tokens (from objcopy -O verilog)
    initial begin
        // init to zero
        for (i = 0; i < MEM_BYTES; i = i + 1) memory_bytes[i] = 8'h00;

        if (MEM_FILE != "") begin
            $display("Loading memory (byte-wise) from %s", MEM_FILE);
            // readmemh will fill sequential memory locations starting at 0
            $readmemh(MEM_FILE, memory_bytes);
        end
    end

    // Helper to assemble little-endian 32-bit word from 4 bytes at base byte index
    function [31:0] read_word_le;
        input integer base_byte_index;
        begin
            // little-endian: byte0 is LSB
            read_word_le = { memory_bytes[base_byte_index + 3],
                             memory_bytes[base_byte_index + 2],
                             memory_bytes[base_byte_index + 1],
                             memory_bytes[base_byte_index + 0] };
        end
    endfunction

    // Combinational logic for immediate response (no 1-cycle delay)
    assign mem_ready = mem_valid;  // Assert ready immediately when valid

    always @* begin
        if (rst) begin
            mem_rdata = {DATA_WIDTH{1'b0}};
        end else if (mem_valid) begin
            // compute base byte address from word index
            base = mem_addr << 2; // multiply by 4

            if (base >= MEM_BYTES) begin
                mem_rdata = 32'h00000000;  // Return illegal instruction for out-of-bounds to trigger trap
                $display("Out-of-bounds memory access at addr %h (base %d > %d)", mem_addr, base, MEM_BYTES);
            end else begin
                if (|mem_wstrb) begin
                    // write-bytes according to wstrb (wstrb[0] -> lowest byte)
                    if (mem_wstrb[0]) memory_bytes[base + 0] = mem_wdata[7:0];
                    if (mem_wstrb[1]) memory_bytes[base + 1] = mem_wdata[15:8];
                    if (mem_wstrb[2]) memory_bytes[base + 2] = mem_wdata[23:16];
                    if (mem_wstrb[3]) memory_bytes[base + 3] = mem_wdata[31:24];

                    mem_rdata = mem_wdata; // echo write
                    // $display("RAM_W ADDR=0x%0h WDATA=0x%08h WSTRB=0x%0h", mem_addr, mem_wdata, mem_wstrb);
                end else begin
                    // read 32-bit little-endian word assembled from 4 bytes
                    mem_rdata = read_word_le(base);
                    // $display("RAM_R ADDR=0x%0h RDATA=0x%08h", mem_addr, read_word_le(base));
                end
            end
        end else begin
            mem_rdata = {DATA_WIDTH{1'b0}};
        end
    end

endmodule