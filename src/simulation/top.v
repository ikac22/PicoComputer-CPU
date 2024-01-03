module top;

reg clk, rst_n, cl, ld, inc, dec, sr, sl, ir, il;
reg [2:0] oc;
reg [3:0] a, b, in;
wire [3:0] out_reg, out_alu;
integer i, j, k;

alu alu_unit(.oc(oc), .a(a), .b(b), .f(out_alu));
register reg_unit( .clk(clk), .rst_n(rst_n), .cl(cl), 
                   .ld(ld), .inc(inc), .dec(dec), 
                   .sr(sr), .sl(sl), .ir(ir), .il(il), .in(in), .out(out_reg));

initial begin
    // register init
    rst_n = 1'b0; clk = 1'b0; 
    cl = 1'b0; ld = 1'b0; inc = 1'b0; dec = 1'b0; 
    sr = 1'b0; sl = 1'b0; ir = 1'b0; il = 1'b0;
    in = 4'h0;
    // alu init
    oc = 3'b000; a = 4'h0; b = 4'h0; 
    #2 rst_n = 1'b1;

    #5;
    for(i = 0; i < 8; i = i + 1) begin
        for(j = 0; j < 16; j = j + 1) begin
            for(k = 0; k < 16; k = k + 1) begin
                a = a + 4'h1;
                #5;
            end
            b = b + 4'h1;
            #5;
        end
        oc = oc + 4'h1;
        #5;
    end

    $stop;
    #9000;
    repeat (1000) begin
        cl = {$random} % 2;
        ld = {$random} % 2;
        inc = {$random} % 2;
        dec = {$random} % 2;
        sr = {$random} % 2;
        sl = {$random} % 2;
        ir = {$random} % 2;
        il = {$random} % 2;
        in = {$random} % 16;
        #10;
    end

    #10 $finish;
end

always @(out_reg) begin

    $display("---REG---\nTIME: %4d, cl: %b, ld: %b, inc: %b, dec: %b\nsr: %b, sl: %b, ir: %b, il: %b, in: %b\nout: %b\n---------", 
             $time, cl, ld, inc, dec, sr, sl, ir, il, in, out_reg);

end

always @(out_alu) begin

    $display("---ALU---\nTIME: %4d, oc: %b, a: %b, b: %b, out: %b\n---------", 
             $time, oc, a, b, out_alu);

end

always #5 clk = ~clk;

endmodule