module color_codes (
    input   [5:0]     num,
    output [23:0] code
);

wire [3:0] tens, ones;
reg  [11:0] code_ones;
reg  [11:0] code_tens;

assign code = {code_tens, code_ones};

bcd num_bcd(
    .in(num),
    .ones(ones),
    .tens(tens));

always @(tens, ones) begin
    case(ones)
        6'd0: code_ones = 12'hFFF; // WHITE 
        6'd1: code_ones = 12'hF00; // RED
        6'd2: code_ones = 12'h0F0; // GREEN
        6'd3: code_ones = 12'h00F; // BLUE
        6'd4: code_ones = 12'hE1F; // PINKISH
        6'd5: code_ones = 12'hFC0; // YELLOW
        6'd6: code_ones = 12'h940; // BROWNISH
        6'd7: code_ones = 12'h3DF; // SKY
        6'd8: code_ones = 12'h250; // DARK GREEN
        6'd9: code_ones = 12'h92E; // PURPLE
        default: code_ones = 12'h000; // BLACK
    endcase

    case(tens)
        6'd0: code_tens = 12'hFFF; // WHITE 
        6'd1: code_tens = 12'hF00; // RED
        6'd2: code_tens = 12'h0F0; // GREEN
        6'd3: code_tens = 12'h00F; // BLUE
        6'd4: code_tens = 12'hE1F; // PINKISH
        6'd5: code_tens = 12'hFC0; // YELLOW
        6'd6: code_tens = 12'h940; // BROWNISH
        6'd7: code_tens = 12'h3DF; // SKY
        6'd8: code_tens = 12'h250; // DARK GREEN
        6'd9: code_tens = 12'h92E; // PURPLE
        default: code_tens = 12'h000; // BLACK
    endcase
end

endmodule