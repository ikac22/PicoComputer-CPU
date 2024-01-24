module tb;
    reg clk;
    reg [5:0] addr;
    reg [15:0] data;
    wire [15:0] out;
    reg we;
    
    always #5 clk = ~clk;
    
    dut u_dut(
        .clk(clk),
        .we(we),
        .addr(addr),
        .data(data),
        .out(out)
    );

    integer i;

    initial begin
        clk = 1'b0; we = 1'b0;
        #10;
        for(i = 0; i < 2**6; i = i + 1) begin
            we = 1;
            addr = i;
            data = {$random} % 2**16;
            #10;
        end
        #10;
        we = 0;
        #10;
        $stop;
        for(i = 0; i < 100; i = i + 1) begin
            #10;
            addr = {$random} % 2**6;
            //$display("Addr: %3d Output: %5d", addr, out);
        end
        $finish;
    end


    always @(posedge clk) begin

        $strobe("---MEM---\nTIME: %4d, we: %1d, addr: %3d, data: %5d, output: %5d\n---------", 
                $time, we, addr, data, out);

    end
endmodule