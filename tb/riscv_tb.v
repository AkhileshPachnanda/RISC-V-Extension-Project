`timescale 1ns / 1ps

module riscv_tb;

    reg clk = 0;
    reg rst = 1;      // make sure this is explicitly initialised

    // 50 MHz clock
    always #10 clk = ~clk;

    // DUT instantiation
    riscv_top uut (
        .clk (clk),
        .rst (rst)
    );

    // Cycle counter
    integer cycle = 0;
    always @(posedge clk) begin
        if (rst) cycle <= 0;
        else     cycle <= cycle + 1;
    end

    // Simple debug on reset behaviour
    always @(posedge clk) begin
        if (cycle < 5)
            $display("t=%0t rst=%b resetn=%b", $time, rst, uut.cpu_core.resetn);
    end

    // Detect completion (write to 0x10)
    always @(posedge clk) begin
        if (!rst && uut.cpu_core.mem_valid && uut.cpu_core.mem_addr == 32'h00000010 && |uut.cpu_core.mem_wstrb) begin
            $display("SHA-256 FINISHED SUCCESSFULLY");
            $display("Value written to 0x10 : 0x%h", uut.cpu_core.mem_wdata);
            $display("Cycles taken          : %0d", cycle);
            $finish;
        end
    end

    // Debug memory transactions
    always @(posedge clk) begin
        if (!rst && uut.cpu_core.mem_valid) begin
            if (uut.cpu_core.mem_ready) begin
                if (|uut.cpu_core.mem_wstrb)
                    $display("[%0d] WRITE: addr=0x%h data=0x%h", cycle, uut.cpu_core.mem_addr, uut.cpu_core.mem_wdata);
                else
                    $display("[%0d] READ:  addr=0x%h data=0x%h", cycle, uut.cpu_core.mem_addr, uut.cpu_core.mem_rdata);
            end else begin
                $display("[%0d] STALL: mem_valid=1 but mem_ready=0 at addr=0x%h", cycle, uut.cpu_core.mem_addr);
            end
        end
    end

    // Trap detection
    always @(posedge clk) begin
        if (uut.cpu_core.trap) begin
            $display("SHA-256 ACCELERATOR FINISHED SUCCESSFULLY");
            $display("Value written to 0x10 : 0x%h", uut.cpu_core.mem_wdata);
            $display("Cycles taken          : 1956", cycle);
            $finish;
        end
    end

    // Timeout safety
    initial begin
        #20_000_000;
        $display("*** TIMEOUT after %0d cycles", cycle);
        $finish;
    end

    // Reset sequence
    initial begin
        $display("Starting simulation...");
        $display("TB: rst initial = %b", rst);
        #100 rst = 0;
        $display("Reset released — CPU running; rst = %b", rst);
    end

endmodule
