module memory (
    input                     clk,
    input                     we,
    input  [5:0] addr,
    input  [7:0] data,
    output [7:0] out
);
    
    reg [7:0] mem [2**6 - 1:0];
     

    // integer i;

    always @(posedge clk) begin
        if(we) 
            mem[addr] <= data;
        else 
            mem[addr] <= mem[addr];
    end
    

    assign out = mem[addr];

endmodule
