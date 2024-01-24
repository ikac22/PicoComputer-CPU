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
    `ifndef SIMUL
        (* ram_init_file = FILE_NAME *) reg [DATA_WIDTH - 1:0] mem [2**ADDR_WIDTH - 1:0];     
    `else
        reg [DATA_WIDTH - 1:0] mem [2**ADDR_WIDTH - 1:0];
        initial begin
            $readmemh(FILE_NAME, mem);
        end        
    `endif 

    // integer i;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            // mem[0] <= 0;
            // mem[1] <= 0;
            // mem[2] <= 0;
            // mem[3] <= 0;
            // mem[4] <= 0;
            // mem[5] <= 0;
            // mem[6] <= 0;
            // mem[7] <= 0;
        end
        else begin
            if(we) 
                mem[addr] <= data;
            else 
                mem[addr] <= mem[addr];
        end
    end
    

    assign out = mem[addr];

endmodule
