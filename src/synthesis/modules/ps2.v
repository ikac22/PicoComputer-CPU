module ps2 (
    input           clk,
    input           rst_n,
    input           ps2_clk,
    input           ps2_data,
    output reg [15:0]  code 
);

reg tmp_cl;
reg [15:0] code_next;
wire n_ps2_clk_re;
wire [21:0] two_b_reg;
wire tmp_cnt;

red ps2_clk_red(
    .clk(clk),
    .rst_n(rst_n),
    .in(!ps2_clk),
    .out(n_ps2_clk_re)
);

register #(.DATA_WIDTH(22)) sh_reg(
    .clk(clk), 
    .rst_n(rst_n),
    .sl(n_ps2_clk_re),
    .il(ps2_data),
    .out(two_b_reg)
);

register #(.DATA_WIDTH(4)) cnt_reg(
    .clk(clk),
    .cl(tmp_cl),
    .rst_n(rst_n),
    .inc(n_ps2_clk_re),
    .out(tmp_cnt)
);

wire [1:0]  start  = {two_b_reg[11], two_b_reg[0]};
wire [1:0]  parity = {two_b_reg[20], two_b_reg[9]};
wire [1:0]  stop   = {two_b_reg[21], two_b_reg[10]};
wire        new_read = tmp_cnt == 'd11;

always @(*) begin
    if(new_read) begin
        code_next = {two_b_reg[19:12], two_b_reg[8:1]};
        tmp_cl = 1;
    end
    else begin
        code_next = code;
        tmp_cl = 0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        code <= 16'h0000;
    end
    else begin
        code <= code_next;
    end
end


endmodule