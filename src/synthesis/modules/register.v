module register #(
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst_n,
    input cl,
    input ld,
    input [DATA_WIDTH-1:0] in,
    input inc,
    input dec,
    input sr,
    input ir,
    input sl,
    input il,
    output [DATA_WIDTH-1:0] out
);
    reg [DATA_WIDTH-1:0] out_reg, out_next;

    assign out = out_reg;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) 
            out_reg <= {DATA_WIDTH{1'b0}};
        else
            out_reg <= out_next;
    end

    always @(*) begin
        casex ({cl, ld, inc, dec, sr, sl})
            6'b1xxxxx: out_next <= {DATA_WIDTH{1'b0}};
            6'b01xxxx: out_next <= in;
            6'b001xxx: out_next <= out + {{(DATA_WIDTH-1){1'b0}}, 1'b1};
            6'b0001xx: out_next <= out - {{(DATA_WIDTH-1){1'b0}}, 1'b1};
            6'b00001x: out_next <= {ir, {(DATA_WIDTH-1){1'b0}}} | (out >> 1);
            6'b000001: out_next <= {{(DATA_WIDTH-1){1'b0}}, il} | (out << 1);
            6'b000000: out_next <= out_reg;
        endcase
    end

endmodule