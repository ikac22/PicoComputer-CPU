// Aritmethical Logical Unit
module alu #(
    parameter DATA_WIDTH = 16
)(
    input [2:0] oc,
    input [DATA_WIDTH-1:0] a,
    input [DATA_WIDTH-1:0] b,
    output reg [DATA_WIDTH-1:0] f
);

always @(oc, a, b) begin
    case (oc)
        // ADD
        3'b000: f = a + b;
        // SUB
        3'b001: f = a - b;
        // MUL
        3'b010: f = a * b;
        // DIV
        3'b011: f = a / b;
        // NOT
        3'b100: f = ~a;
        // XOR
        3'b101: f = a ^ b;
        // OR
        3'b110: f = a | b;
        // AND
        3'b111: f = a & b; 
    endcase
end
    

endmodule