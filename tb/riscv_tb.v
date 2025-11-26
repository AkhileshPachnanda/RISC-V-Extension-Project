`timescale 1ns / 1ps

module riscv_tb_diag2;

    // Signals
    reg clk = 0;
    reg rst = 1;
    reg [31:0] cycle_count = 0;

    // Instantiate the Unit Under Test (UUT)
    riscv_top uut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation (100 MHz -> 10 ns period)
    always #5 clk = ~clk;  // Toggle every 5 ns

    // Cycle counter
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count <= cycle_count + 1;
        end
    end

    // Initial reset sequence
    initial begin
        rst = 1;
        #20;  // Hold reset for 20 ns
        rst = 0;
    end

    // Timeout mechanism (reduced to 1 ms for faster testing)
    initial begin
        #1000000;  // 1 ms (in ps units: 1e6 ns)
        $display("TIMEOUT! Simulation ended with no completion signal after %d cycles.", cycle_count);
        $finish;
    end

    // Debug monitoring: Print all memory accesses from start
    always @(posedge clk) begin
        if (!rst && uut.mem_valid) begin
            if (^uut.mem_addr === 1'bx || ^uut.mem_rdata === 1'bx) begin
                $display("@%0t: <unknown> - PC: %h, mem_addr: %h, mem_rdata: %h (possible stall or garbage fetch)", 
                         $time, uut.cpu_core.reg_pc, uut.mem_addr, uut.mem_rdata);
            end else begin
                $display("@%0t: Cycle %d - PC: %h, mem_valid: %b, mem_instr: %b, mem_addr: %h, mem_rdata: %h, mem_wdata: %h, mem_wstrb: %h",
                         $time, cycle_count, uut.cpu_core.reg_pc, uut.mem_valid, uut.mem_instr, uut.mem_addr, uut.mem_rdata, uut.mem_wdata, uut.mem_wstrb);
            end
        end
    end

    // Completion detection: Monitor write to DONE_ADDR (0x00000010)
    always @(posedge clk) begin
        if (!rst && uut.mem_valid && uut.mem_addr == 32'h00000010 && |uut.mem_wstrb && uut.mem_wdata != 0) begin
            $display("Completion signal detected! Value written to DONE_ADDR: %h after %d cycles.", uut.mem_wdata, cycle_count);
            $finish;
        end
    end

    // Trap monitor
    always @(posedge clk) begin
        if (uut.cpu_core.trap) begin
            $display("TRAP asserted at cycle %d! Possible illegal instruction or exception. PC: %h", cycle_count, uut.cpu_core.reg_pc);
        end
    end

endmodule