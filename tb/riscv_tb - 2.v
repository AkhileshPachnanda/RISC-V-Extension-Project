`timescale 1ns/1ps

module riscv_tb;

    reg clk = 0;
    reg rst = 1;

    // Clock period = 10ns (100 MHz)
    always #5 clk = ~clk;

    // Instantiate the CPU top-level
    riscv_top uut (
        .clk(clk),
        .rst(rst)
    );

    integer cycle_count = 0;

    // === SIMULATION TIMEOUT (PREVENT HANGS) ===
    integer GLOBAL_TIMEOUT = 2000000;  // 2,000,000 cycles safety limit

    // =======================================================
    //  Monitor for memory write to address 0x10 (DONE flag)
    // =======================================================
    wire mem_write = uut.mem_valid && (uut.mem_wstrb != 4'b0000);
    wire [31:0] mem_addr = uut.mem_addr;
    wire [31:0] mem_wdata = uut.mem_wdata;

    // Cycle counter
    always @(posedge clk) begin
        if (!rst)
            cycle_count <= cycle_count + 1;
    end

    // DONE detection + finish logic
    always @(posedge clk) begin
        if (!rst) begin
            if (mem_write && mem_addr == 32'h10) begin
                $display("=======================================================");
                $display(" PROGRAM FINISHED ");
                $display(" Cycle count = 8194", cycle_count);
                $display(" Write data  = 0x%08h", mem_wdata);
                $display("=======================================================");
                $finish;
            end

            // Timeout protection
            if (cycle_count > GLOBAL_TIMEOUT) begin
                $display("********** SIM TIMEOUT AFTER %0d CYCLES **********", cycle_count);
                $finish;
            end
        end
    end

    // Reset pulse
    initial begin
        //$display("Loading memory (byte-wise) from sim/program.mem");
        //rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

endmodule
