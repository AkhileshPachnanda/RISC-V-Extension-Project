`timescale 1ns/1ps
module riscv_tb;

    reg clk = 0;
    reg rst = 1;

    // 50 MHz clock
    always #10 clk = ~clk;

    // ------------------------------------------------------------------
    // DUT instantiation — matches your current riscv_top.v ports
    // ------------------------------------------------------------------
    riscv_top uut (
        .clk(clk),
        .rst(rst)      // ← active-high reset, exactly as in your top
    );

    // ------------------------------------------------------------------
    // Cycle counter
    // ------------------------------------------------------------------
    integer cycle = 0;
    always @(posedge clk) begin
        if (rst) cycle <= 0;
        else     cycle <= cycle + 1;
    end

    // ------------------------------------------------------------------
    // Completion detection — software writes anything to 0x00000010
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst && uut.mem_valid && uut.mem_addr == 32'h00000010 && |uut.mem_wstrb) begin
            $display(""); 
            $display("================================================================");
            $display("===        SHA-256 BASELINE FINISHED SUCCESSFULLY           ====");
            $display("=== Value written to 0x10 : 0x%h", uut.mem_wdata);
            $display("=== Cycles taken          : %0d", cycle);
            $display("================================================================");
            $display("");
            $finish;
        end
    end

    // ------------------------------------------------------------------
    // Trap / illegal instruction detection
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (uut.trap) begin
            $display("*** ERROR: TRAP at cycle %0d (PC = 0x%h)", cycle, uut.cpu_core.reg_pc);
            $finish;
        end
    end

    // ------------------------------------------------------------------
    // Timeout (safety)
    // ------------------------------------------------------------------
    initial begin
        #20_000_000;  // 20 million ns ≈ 1 million cycles
        $display("*** TIMEOUT — no write to 0x10 after %0d cycles", cycle);
        $finish;
    end

    // ------------------------------------------------------------------
    // Reset sequence
    // ------------------------------------------------------------------
    initial begin
        $display("Starting simulation...");
        #47 rst = 0;
        $display("Reset released — CPU running");
    end

endmodule