`timescale 1ns / 1ps

module riscv_tb;

    reg clk;
    reg rst;

    // Instantiate top
    riscv_top uut (
        .clk (clk),
        .rst (rst)
    );

    // cycle counter
    reg [31:0] cycle_count;
    initial begin
        cycle_count = 0;
    end

    // clock
    initial begin
        clk = 0;
        forever #50 clk = ~clk; // 100ns period => 10 MHz sim-clock scale; adjust if desired
    end

    // reset
    initial begin
        rst = 1;
        #95;
        rst = 0;
    end

    // cycle counter increment
    always @(posedge clk) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // detect program completion: CPU writes to address 0x10
    reg done;
    initial done = 0;

always @(posedge clk) begin
    if (uut.mem_valid && uut.mem_ready && uut.mem_addr == 32'h00000010 && uut.mem_wdata != 0) 
        $display("DONE signal written: %h at cycle %d", uut.mem_wdata, $time);
    if (uut.cpu_core.pcpi_valid) 
        $display("PCPI triggered: insn=%h, rs1=%h", uut.cpu_core.pcpi_insn, uut.cpu_core.pcpi_rs1);
end

    always @(posedge clk) begin
        if (!rst && !done) begin
            // check write to address 0x10 — use top's wires through hierarchical access
            // mem_valid + write strobes + address match
            if (uut.mem_valid && (|uut.mem_wstrb) && (uut.mem_addr == 32'h00000010)) begin
                $display("=======================================================");
                $display(" PROGRAM FINISHED ");
                $display(" Cycle count  = %0d", cycle_count);
                $display(" Write data   = 0x%08h", uut.mem_wdata);
                $display("=======================================================");

                done = 1;
                #20;
                $finish;
            end
        end
    end

    // safety timeout (long enough)
    initial begin
        #500000000;   // simulated time units (depends on clock scaling)
        $display("TIMEOUT! Simulation ended with no completion signal.");
        $finish;
    end

endmodule
