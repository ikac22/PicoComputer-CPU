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
    output reg [DATA_WIDTH-1:0] out
);
    reg [DATA_WIDTH-1:0] out_next;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) 
            out <= 0;
        else
            out <= out_next;
    end

    always @(*) begin
        out_next = out;
        if(cl == 1'b1) begin
            out_next = {DATA_WIDTH{1'b0}};
        end
        else if (ld == 1'b1) begin
            out_next = in;
        end
        else if (inc == 1'b1) begin
            out_next = out + 1;
        end
        else if (dec == 1'b1) begin
            out_next = out - {{(DATA_WIDTH-1){1'b0}}, 1'b1};
        end
        else if (sr == 1'b1) begin
            out_next = {ir, {(DATA_WIDTH-1){1'b0}}} | (out >> 1);
        end
        else if (sl == 1'b1) begin
            out_next = {{(DATA_WIDTH-1){1'b0}}, il} | (out << 1);
        end
        else begin
            out_next = out;
        end
    end

endmodule