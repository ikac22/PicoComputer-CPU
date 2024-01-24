module ps2 (
    input           clk,
    input           rst_n,
    input           ps2_clk,
    input           ps2_data,
    output reg [15:0]  code 
);

reg [9:0] sh_reg; // shifter 
reg [3:0] cnt_reg; // counter
reg [7:0] tmp; // for testing

// this could lead to the Clock Domain Crossing(CDC) if cpu clk is faster
// but because cpu clk is 1HZ it is unlikely to happen

// TO FIX THIS code reg must be updated on posedge "clk" and not "ps2_clk" negedge 
// or it could stay this way and implement good synchronization in "scan_codes" module
always @(negedge ps2_clk, negedge rst_n) begin
    if(!rst_n)begin
        code <= 0;
        sh_reg <= 0;
        cnt_reg <= 0;
        tmp <= 0;
    end
    else
    begin
        if(cnt_reg == 4'b1010) begin
            cnt_reg <= 0;
            code <= {code[7:0], sh_reg[8:1]};
            sh_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_reg + 1;
            sh_reg <= {ps2_data, sh_reg[9:1]};
        end
    end
end


endmodule