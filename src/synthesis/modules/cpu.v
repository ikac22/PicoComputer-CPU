module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16,
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH - 1:0] mem_in,
    input [DATA_WIDTH - 1:0] in,
    output mem_we,
    output [ADDR_WIDTH - 1:0] mem_addr,
    output [DATA_WIDTH - 1:0] mem_data,
    output [DATA_WIDTH - 1:0] out,
    output [ADDR_WIDTH - 1:0] pc,
    output [ADDR_WIDTH - 1:0] sp
);

reg [DATA_WIDTH - 1:0] cpu_fsm, cpu_fsm_next;


always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        
    end
end
    
endmodule