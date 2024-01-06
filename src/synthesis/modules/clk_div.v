module clk_div #(
    parameter DIVISOR = 50_000_000
) (
    input clk,
    input rst_n,
    output out
);
    
    integer cnt_reg, cnt_next;
    reg out_reg, out_next;

    assign out = out_reg;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            cnt_reg <= 0;
            out_reg <= 1'b0;
        end
        else begin
            cnt_reg <= cnt_next;
            out_reg <= out_next;
        end

    end

    always @(*) begin
        out_next = out_reg;
        cnt_next = cnt_reg;
        if (cnt_reg == DIVISOR-1) 
            cnt_next = 0;
        else 
            cnt_next = cnt_reg + 1;
        out_next = (cnt_reg < DIVISOR/2) ? 1'b1:1'b0;
    end

endmodule