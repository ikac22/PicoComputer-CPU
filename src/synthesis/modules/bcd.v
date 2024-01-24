module bcd (
    input [5:0] in,
    output reg [3:0]  ones,
    output reg [3:0] tens
);
    // get two digits(ones and tens) of a decimal represented by binary number(in)

    reg [5:0] bin;
    integer i; 

    // DOUBLE DABBLE
    always @(in) begin
        {tens, ones, bin} = {4'h0, 4'h0, in};
    
        for(i = 0; i < 6; i = i + 1) begin
            // Every shift will be checked except last
            if(tens > 4)
                tens = tens + 4'd3;
            else
                tens = tens;

            if(ones > 4)
                ones = ones + 4'd3;    
            else
                ones = ones;
            
            {tens, ones, bin} = {tens, ones, bin} << 1;
        end
    end

endmodule