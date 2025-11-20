ram_model #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(12),
    .MEM_FILE("program.mem")
) ram_inst (
    .clk(clk),
    .rst(rst),
    .mem_valid(mem_valid),
    .mem_wstrb(mem_wstrb),
    .mem_addr(mem_addr[13:2]),  // word address (ignore lower 2 bits)
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_ready(mem_ready)
);

//heloo

