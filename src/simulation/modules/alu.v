// Aritmethical Logical Unit
module alu (
    input [2:0] oc,
    input [3:0] a,
    input [3:0] b,
    output [3:0] f
);

reg [3:0] result;

assign f = result;

always @(oc, a, b) begin
    case (oc)
        // ADD
        3'b000: result = a + b;
        // SUB
        3'b001: result = a - b;
        // MUL
        3'b010: result = a * b;
        // DIV
        3'b011: result = a / b;
        // NOT
        3'b100: result = ~a;
        // XOR
        3'b101: result = a ^ b;
        // OR
        3'b110: result = a | b;
        // AND
        3'b111: result = a & b; 
    endcase
end
    

endmodule