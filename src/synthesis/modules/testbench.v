module testbench;
reg clk;
reg rst_n;

always #(5) clk=~clk;

reg  [2:0] btn;
reg  [8:0] sw;
wire [9:0] led;
wire [27:0] hex;

top #(
    .DIVISOR(10),
    .FILE_NAME("mem_init.hex")
) u_top( 
    .clk(clk),
    .rst_n(rst_n),
    .btn(btn),
    .sw(sw), 
    .led(led),
    .hex(hex) 
);

initial begin
    btn <= 0;
    sw <= 8;
    #1 rst_n<=1'bx; clk<=1'bx;
    #(30) rst_n<=1;
    #(30) rst_n<=0;clk<=0;
    
    #(50) rst_n<=1;
    #(10) btn[0]<=1;

    #(30000) $finish;
end

// always @(clk) begin
//     $display("clk change");
// end

always @(led) begin
    $display("---LED---\n%b\n---------", led);
end

always @(hex) begin
    $display("---HEX---\n");

    case(~hex[27:21])
        7'h3F: $display("%h", 4'b0000);
        7'h06: $display("%h", 4'b0001);
        7'h5B: $display("%h", 4'b0010);
        7'h4F: $display("%h", 4'b0011);
        7'h66: $display("%h", 4'b0100);
        7'h6D: $display("%h", 4'b0101);
        7'h7D: $display("%h", 4'b0110);
        7'h07: $display("%h", 4'b0111);
        7'h7F: $display("%h", 4'b1000);
        7'h6F: $display("%h", 4'b1001);
        7'h77: $display("%h", 4'b1010);
        7'h7C: $display("%h", 4'b1011);
        7'h39: $display("%h", 4'b1100);
        7'h5E: $display("%h", 4'b1101);
        7'h79: $display("%h", 4'b1110);
        7'h71: $display("%h", 4'b1111);
    endcase

    case(~hex[20:14])
        7'h3F: $display("%h", 4'b0000);
        7'h06: $display("%h", 4'b0001);
        7'h5B: $display("%h", 4'b0010);
        7'h4F: $display("%h", 4'b0011);
        7'h66: $display("%h", 4'b0100);
        7'h6D: $display("%h", 4'b0101);
        7'h7D: $display("%h", 4'b0110);
        7'h07: $display("%h", 4'b0111);
        7'h7F: $display("%h", 4'b1000);
        7'h6F: $display("%h", 4'b1001);
        7'h77: $display("%h", 4'b1010);
        7'h7C: $display("%h", 4'b1011);
        7'h39: $display("%h", 4'b1100);
        7'h5E: $display("%h", 4'b1101);
        7'h79: $display("%h", 4'b1110);
        7'h71: $display("%h", 4'b1111);
    endcase

    case(~hex[13:7])
        7'h3F: $display("%h", 4'b0000);
        7'h06: $display("%h", 4'b0001);
        7'h5B: $display("%h", 4'b0010);
        7'h4F: $display("%h", 4'b0011);
        7'h66: $display("%h", 4'b0100);
        7'h6D: $display("%h", 4'b0101);
        7'h7D: $display("%h", 4'b0110);
        7'h07: $display("%h", 4'b0111);
        7'h7F: $display("%h", 4'b1000);
        7'h6F: $display("%h", 4'b1001);
        7'h77: $display("%h", 4'b1010);
        7'h7C: $display("%h", 4'b1011);
        7'h39: $display("%h", 4'b1100);
        7'h5E: $display("%h", 4'b1101);
        7'h79: $display("%h", 4'b1110);
        7'h71: $display("%h", 4'b1111);
    endcase

    case(~hex[6:0])
        7'h3F: $display("%h", 4'b0000);
        7'h06: $display("%h", 4'b0001);
        7'h5B: $display("%h", 4'b0010);
        7'h4F: $display("%h", 4'b0011);
        7'h66: $display("%h", 4'b0100);
        7'h6D: $display("%h", 4'b0101);
        7'h7D: $display("%h", 4'b0110);
        7'h07: $display("%h", 4'b0111);
        7'h7F: $display("%h", 4'b1000);
        7'h6F: $display("%h", 4'b1001);
        7'h77: $display("%h", 4'b1010);
        7'h7C: $display("%h", 4'b1011);
        7'h39: $display("%h", 4'b1100);
        7'h5E: $display("%h", 4'b1101);
        7'h79: $display("%h", 4'b1110);
        7'h71: $display("%h", 4'b1111);
    endcase

    $display("\n---------");
end

endmodule
`default_nettype wire