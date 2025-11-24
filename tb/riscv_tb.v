`timescale 1ns/1ps

module riscv_tb;

    reg clk = 0;
    reg rst = 1;

    // Instantiate top-level system
    riscv_top uut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generator: 100 MHz
    always #5 clk = ~clk;

    // Reset pulse
    initial begin
        rst = 1;
        #50;
        rst = 0;
    end

    // Cycle counter
    integer cycle_count = 0;
    always @(posedge clk) begin
        if (rst) cycle_count <= 0;
        else     cycle_count <= cycle_count + 1;
    end

    // -----------------------------------------------------
    // DEBUG: Instruction Fetch Monitor
    // When mem_instr==1 and mem_valid==1, this is a FETCH.
    // mem_addr is the PC. mem_rdata is the fetched instruction.
    // -----------------------------------------------------
    always @(posedge clk) begin
        if (!rst && uut.mem_valid && uut.mem_instr) begin
            $display("FETCH  cycle=%0d  PC=0x%08h  instr=0x%08h  ready=%0d",
                     cycle_count, uut.mem_addr, uut.mem_rdata, uut.mem_ready);
        end
    end

    // -----------------------------------------------------
    // DEBUG: Print ALL memory operations (data & code)
    // -----------------------------------------------------
    always @(posedge clk) begin
        if (!rst && uut.mem_valid) begin
            $display("MEM    cycle=%0d addr=0x%08h wstrb=0x%0h wdata=0x%08h rdata=0x%08h instr=%0d ready=%0d",
                cycle_count,
                uut.mem_addr,
                uut.mem_wstrb,
                uut.mem_wdata,
                uut.mem_rdata,
                uut.mem_instr,
                uut.mem_ready);
        end
    end

    // -----------------------------------------------------
    // Program completion: store to address 0x10
    // -----------------------------------------------------
    reg done = 0;
    always @(posedge clk) begin
        if (!rst && !done) begin
            if (uut.mem_valid && (|uut.mem_wstrb) && uut.mem_addr == 32'h00000010) begin

                $display("=======================================================");
                $display(" PROGRAM FINISHED ");
                $display(" Cycle count = %0d", cycle_count);
                $display(" Write data  = 0x%08h", uut.mem_wdata);
                $display("=======================================================");

                done = 1;
                #50;
                $finish;
            end
        end
    end

    // Large timeout for SHA baseline
    initial begin
        #300000000;  // 300 ms simulation time
        $display("TIMEOUT! Simulation ended with no completion signal.");
        $finish;
    end

endmodule
