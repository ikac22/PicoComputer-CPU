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
            out_reg <= 0;
        else
            out_reg <= out_next;
    end

    always @(*) begin
        if(cl == 1'b1) begin
            //$display("CL");  
            out_next <= {DATA_WIDTH{1'b0}};
        end
        else if (ld == 1'b1) begin
            //$display("LD");
            out_next <= in;
        end
        else if (inc == 1'b1) begin
            //$display("INC");
            out_next <= out + 1;
        end
        else if (dec == 1'b1) begin
            //$display("DEC");
            out_next <= out - {{(DATA_WIDTH-1){1'b0}}, 1'b1};
        end
        else if (sr == 1'b1) begin
            out_next <= {ir, {(DATA_WIDTH-1){1'b0}}} | (out >> 1);
        end
        else if (sl == 1'b1) begin
            out_next <= {{(DATA_WIDTH-1){1'b0}}, il} | (out << 1);
        end
        else begin
            out_next <= out_reg;
        end
    end

endmodule