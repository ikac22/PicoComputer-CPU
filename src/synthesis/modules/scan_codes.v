module scan_codes (
    input           clk,
    input           rst_n,
    input [15:0]    code,
    input           signal,
    output reg      control,
    output reg [3:0] num

);

reg [15:0] in_code, in_code_next;
reg control_next;
reg [3:0] num_next;
reg new_code;

always @(*) begin
    control_next = control;
    in_code_next = code;
    num_next = num;
    new_code = 1'b0;
    if(signal) begin
        case(code)
        //  1       2       3       4       5       6       7       8       9       0
            'hF016, 'hF01E, 'hF026, 'hF025, 'hF02E, 'hF036, 'hF03D, 'hF03E, 'hF046, 'hF045,
        //  A       B       C       D       E       F
            'hF01C, 'hF032, 'hF021, 'hF023, 'hF024, 'hF02B: new_code = code != in_code;
            default: new_code = 0;
        endcase

        if(control) begin
            control_next = control;
            num_next = num;
        end
        else begin
            if(new_code) begin
                control_next = 1'b1;
                case(code)
                    'hF045: num_next = 4'h0;
                    'hF016: num_next = 4'h1;
                    'hF01E: num_next = 4'h2;
                    'hF026: num_next = 4'h3;
                    'hF025: num_next = 4'h4;
                    'hF02E: num_next = 4'h5;
                    'hF036: num_next = 4'h6;
                    'hF03D: num_next = 4'h7;
                    'hF03E: num_next = 4'h8;
                    'hF046: num_next = 4'h9;
                    'hF01C: num_next = 4'hA;
                    'hF032: num_next = 4'hB;
                    'hF021: num_next = 4'hC;
                    'hF023: num_next = 4'hD;
                    'hF024: num_next = 4'hE;
                    'hF02B: num_next = 4'hF;
                    default: control_next = 1'b0;
                endcase
            end
            else begin
                control_next = 1'b0;
            end    
        end
    
    end
    else begin
        control_next = 0;
        num_next = 4'h0;
    end


end

always @(posedge clk, negedge rst_n) begin 
    if(!rst_n) begin
        in_code <= 16'h0000;
        control <= 1'b0;
        num <= 4'h0;
    end
    else begin
        in_code <= in_code_next;
        num <= num_next;
        control <= control_next;
    end

end
    
endmodule