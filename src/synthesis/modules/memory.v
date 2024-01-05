module memory #(
	parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input                     clk,
    input                     we,
    input                     rst_n,
    input  [ADDR_WIDTH - 1:0] addr,
    input  [DATA_WIDTH - 1:0] data,
    output [DATA_WIDTH - 1:0] out
);

    integer i;

	(* ram_init_file = FILE_NAME *) reg [DATA_WIDTH - 1:0] mem [2**ADDR_WIDTH - 1:0];

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0; i < 8; i = i + 1)
                mem[i] <= 16'd0;
        end
        else begin
            if (we) 
                mem[addr] <= data;
            else 
                mem[addr] <= mem[addr]; 
        end
    end

    assign out = mem[addr];

endmodule
