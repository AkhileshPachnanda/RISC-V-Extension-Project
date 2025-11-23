`timescale 1ns / 1ps

module ram_model #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,            // number of word-address bits (2^ADDR_WIDTH words)
    parameter MEM_FILE   = "sim/program.mem"
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     mem_valid,
    input  wire [3:0]               mem_wstrb,
    input  wire [ADDR_WIDTH-1:0]    mem_addr,   // word-index address
    input  wire [DATA_WIDTH-1:0]    mem_wdata,
    output reg  [DATA_WIDTH-1:0]    mem_rdata,
    output reg                      mem_ready
);

    // Memory array
    reg [DATA_WIDTH-1:0] memory_array [0:(1 << ADDR_WIDTH)-1];

    // Load initial contents
    initial begin
        if (MEM_FILE != "") begin
            $display("Loading memory from %s", MEM_FILE);
            $readmemh(MEM_FILE, memory_array);
        end
    end

    // Read/write logic with debug prints
    always @(posedge clk) begin
        if (rst) begin
            mem_ready <= 0;
            mem_rdata <= 0;
        end else begin
            mem_ready <= 0;
            if (mem_valid && !mem_ready) begin
                mem_ready <= 1'b1;
                // Write
                if (|mem_wstrb) begin
                    memory_array[mem_addr] <= mem_wdata;
                    $display("RAM_W  @%0t ns CYCLE=%0d ADDR=0x%0h WDATA=0x%08h WSTRB=0x%0h",
                             $time, $time/10, mem_addr, mem_wdata, mem_wstrb);
                end else begin
                    $display("RAM_R  @%0t ns CYCLE=%0d ADDR=0x%0h RDATA=0x%08h",
                             $time, $time/10, mem_addr, memory_array[mem_addr]);
                end
                mem_rdata <= memory_array[mem_addr];
            end
        end
    end

endmodule

