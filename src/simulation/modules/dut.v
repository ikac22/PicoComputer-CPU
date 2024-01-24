module dut (
    input clk,
    input we,
    input   [5:0] addr,
    input   [15:0] data,
    output  [15:0] out
);

memory mem_lower(
    .clk(clk),
    .we(we),
    .addr(addr),
    .data(data[7:0]),
    .out(out[7:0])
);

memory mem_higher(
    .clk(clk),
    .we(we),
    .addr(addr),
    .data(data[15:8]),
    .out(out[15:8])
);
    
endmodule