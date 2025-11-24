`timescale 1ns / 1ps

module ram_model #(
    parameter DATA_WIDTH = 32,               // word width returned on reads
    parameter ADDR_WIDTH = 20,               // number of address bits for word indexing
    parameter MEM_FILE   = "sim/program.mem" // $readmemh file (expected as byte tokens)
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     mem_valid,                   // request valid (word access)
    input  wire [3:0]               mem_wstrb,                   // per-byte write strobes
    input  wire [ADDR_WIDTH-1:0]    mem_addr,                    // WORD index (as used by riscv_top: mem_addr[31:2])
    input  wire [DATA_WIDTH-1:0]    mem_wdata,
    output reg  [DATA_WIDTH-1:0]    mem_rdata,
    output reg                      mem_ready
);

    // Total number of bytes = 2^(ADDR_WIDTH + 2)
    localparam BYTE_ADDR_WIDTH = ADDR_WIDTH + 2;
    localparam MEM_BYTES = (1 << (ADDR_WIDTH + 2));

    // Byte-addressable memory array
    reg [7:0] memory_bytes [0:MEM_BYTES-1];

    // Request latch to create a 1-cycle response delay
    reg req_valid;
    reg [ADDR_WIDTH-1:0] req_addr;
    reg [DATA_WIDTH-1:0] req_wdata;
    reg [3:0] req_wstrb;

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

    always @(posedge clk) begin
        if (rst) begin
            req_valid <= 1'b0;
            mem_ready <= 1'b0;
            mem_rdata <= {DATA_WIDTH{1'b0}};
        end else begin
            // Capture incoming request (word-indexed) if none pending
            if (mem_valid && !req_valid) begin
                req_valid <= 1'b1;
                req_addr  <= mem_addr;   // word index
                req_wdata <= mem_wdata;
                req_wstrb <= mem_wstrb;
                mem_ready <= 1'b0;
            end else if (req_valid) begin
                // Serve captured request this cycle (1-cycle delayed)
                mem_ready <= 1'b1;

                // compute base byte address from word index
                base = req_addr << 2; // multiply by 4

                if (|req_wstrb) begin
                    // write-bytes according to wstrb (wstrb[0] -> lowest byte)
                    if (req_wstrb[0]) memory_bytes[base + 0] <= req_wdata[7:0];
                    if (req_wstrb[1]) memory_bytes[base + 1] <= req_wdata[15:8];
                    if (req_wstrb[2]) memory_bytes[base + 2] <= req_wdata[23:16];
                    if (req_wstrb[3]) memory_bytes[base + 3] <= req_wdata[31:24];

                    mem_rdata <= req_wdata; // echo write
                    // $display("RAM_W  @%0t ns CYCLE=%0d ADDR=0x%0h WDATA=0x%08h WSTRB=0x%0h",
                    //$time, $time/10, req_addr, req_wdata, req_wstrb);
                end else begin
                    // read 32-bit little-endian word assembled from 4 bytes
                    mem_rdata <= read_word_le(base);
                    // $display("RAM_R  @%0t ns CYCLE=%0d ADDR=0x%0h RDATA=0x%08h",
                    //         $time, $time/10, req_addr, read_word_le(base));
                end

                req_valid <= 1'b0;
            end else begin
                mem_ready <= 1'b0;
            end
        end
    end

endmodule
