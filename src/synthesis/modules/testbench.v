// OPERATION CODES FOR TESTING
`define MOV                 'h00
`define MOV_IND             'h01
`define MOV_IND_2           'h02

`define MOV_IMM             'h03
`define MOV_IMM_IND         'h04

`define IN                  'h10
`define IN_IND              'h11

`define OUT                 'h20
`define OUT_IND             'h21

`define ALU                 'h30
`define ALU_IND             'h31
`define ALU_IND_2           'h32
`define ALU_IND_3           'h33

`define STOP                'h40

`define STOP_1              'h50
`define STOP_1_IND          'h51

`define STOP_2              'h60
`define STOP_2_IND          'h61
`define STOP_2_IND_2        'h62

`define STOP_3              'h70
`define STOP_3_IND          'h71
`define STOP_3_IND_2        'h72
`define STOP_3_IND_3        'h73

// NUM OF CLOCKS IT TAKES FOR INSTRUCTION
`define RESET_CLK           1

`define MOV_CLK             6
`define MOV_IND_CLK         7
`define MOV_IND_2_CLK       8

`define MOV_IMM_CLK         6
`define MOV_IMM_IND_CLK     7

`define OUT_CLK             5
`define OUT_IND_CLK         6

`define ALU_CLK             7
`define ALU_IND_CLK         8
`define ALU_IND_2_CLK       9
`define ALU_IND_3_CLK       10

`define STOP_CLK            4

`define STOP_1_CLK          6        
`define STOP_1_IND_CLK      7 

`define STOP_2_CLK          8
`define STOP_2_IND_CLK      9
`define STOP_2_IND_2_CLK    10

`define STOP_3_CLK          10
`define STOP_3_IND_CLK      11
`define STOP_3_IND_2_CLK    12
`define STOP_3_IND_3_CLK    13

`define IN_CLK_PRE          2
`define IN_IND_CLK_PRE      2

`define IN_CLK_AFTER        3
`define IN_IND_CLK_AFTER    4

`define WAIT_CLK(clks)      DIVISOR*CLK_TIME*2*clks                  

module testbench;

localparam CLK_TIME = 5,
           DIVISOR  = 10;


reg clk;
reg rst_n;

always #(CLK_TIME) clk=~clk;

reg  [2:0] btn;
reg  [8:0] sw;
wire [9:0] led;
wire [27:0] hex;
`ifdef PHASE_3
    reg  ps2_clk;
    wire ps2_data;
    wire [13:0] kbd;
`endif

// FOR READING FILES
integer read_op;
integer file;
integer stop_loop;


top #(
    .DIVISOR(DIVISOR),
    .FILE_NAME("mem_init.hex")
) u_top( 
    .clk(clk),
    .rst_n(rst_n),
    .btn(btn),
    .sw(sw), 
    .led(led),
    .hex(hex) 
);


initial begin
    file = $fopen("code.follow", "r");

    if(file) $display("Code follow file opened successfully.");
    else     $display("Code follow file failed to open.");
    stop_loop = 0;
    btn <= 0;
    sw <= 0;
    #1 rst_n<=1'bx; clk<=1'bx;
    #2 rst_n<=1;
    #(CLK_TIME - 3) rst_n<=0;clk<=0;
    #(CLK_TIME - 2) rst_n<=1;
    
    // FIRST RESET STATE
    #(2);
    sw <= 8;

    // FOR LOOP FOR INSTRUCTIONS 
    while(!stop_loop) begin
        $fscanf(file, "%h", read_op);
        case(read_op)
            `MOV           :   begin 
                #(`WAIT_CLK(`MOV_CLK));
                sw = 1;
            end
            `MOV_IND       :    #(`WAIT_CLK(`MOV_IND_CLK));
            `MOV_IND_2     :    #(`WAIT_CLK(`MOV_IND_2_CLK));  

            `MOV_IMM       :  begin  
                #(`WAIT_CLK(`MOV_IMM_CLK));
                sw = 1;
            end
            `MOV_IMM_IND   :    #(`WAIT_CLK(`MOV_IMM_IND_CLK));  

            `IN            :
            begin
                #(`WAIT_CLK(`IN_CLK_PRE) - 10); 
                $fscanf(file, "%h", sw);
                btn[0] = 1'b1;
                #(`WAIT_CLK(`IN_CLK_AFTER) + 10);
                btn[0] = 1'b0;
                sw = 4;
            end
            
            `IN_IND        :
            begin
                #(`WAIT_CLK(`IN_IND_CLK_PRE) - 10);
                $fscanf(file, "%h", sw);
                btn[0] = 1'b1;
                #(`WAIT_CLK(`IN_IND_CLK_AFTER) + 10)
                btn[0] = 1'b0;
                sw = 4;
            end

            `OUT           :  
            begin
              #(`WAIT_CLK(`OUT_CLK));    
                sw <= 'h2;
            end
            `OUT_IND       :      
            begin
              #(`WAIT_CLK(`OUT_IND_CLK));    
                sw <= 'h2;
            end

            `ALU           :  
            begin
              #(`WAIT_CLK(`ALU_CLK));
                sw <= 'h3;
            end
            `ALU_IND       :    
            begin
              #(`WAIT_CLK(`ALU_IND_CLK));
                sw <= 'h3;
            end
            `ALU_IND_2     :    
            begin
              #(`WAIT_CLK(`ALU_IND_2_CLK));
                sw <= 'h3;
            end
            `ALU_IND_3     :    
            begin
              #(`WAIT_CLK(`ALU_IND_3_CLK));
                sw <= 'h3;
            end

            `STOP          :    #(`WAIT_CLK(`STOP_CLK));

            `STOP_1        :    #(`WAIT_CLK(`STOP_1_CLK));
            `STOP_1_IND    :    #(`WAIT_CLK(`STOP_1_IND_CLK));

            `STOP_2        :    #(`WAIT_CLK(`STOP_2_CLK));
            `STOP_2_IND    :    #(`WAIT_CLK(`STOP_2_IND_CLK));
            `STOP_2_IND_2  :    #(`WAIT_CLK(`STOP_2_IND_2_CLK));

            `STOP_3        :    #(`WAIT_CLK(`STOP_3_CLK));
            `STOP_3_IND    :    #(`WAIT_CLK(`STOP_3_IND_CLK));
            `STOP_3_IND_2  :    #(`WAIT_CLK(`STOP_3_IND_2_CLK));
            `STOP_3_IND_3  :    #(`WAIT_CLK(`STOP_3_IND_3_CLK));
        endcase


        case(read_op)
             `STOP, `STOP_1, `STOP_1_IND,
             `STOP_2, `STOP_2_IND, `STOP_2_IND_2,
             `STOP_3, `STOP_3_IND, `STOP_3_IND_2, `STOP_3_IND_3:
             stop_loop = 1;
         endcase

        $display("%h", read_op);
    end
    $fclose(file);
    #(DIVISOR*CLK_TIME*2) $finish;
end

// always @(clk) begin
//     $display("clk change");
// end

always @(led) begin
    $display("---LED---\n%b\n---------", led);
end

always @(hex) begin
    $display("---HEX---\n");
    
    case(~hex[27:21])
        7'h3F: $display("%h", 4'b0000);
        7'h06: $display("%h", 4'b0001);
        7'h5B: $display("%h", 4'b0010);
        7'h4F: $display("%h", 4'b0011);
        7'h66: $display("%h", 4'b0100);
        7'h6D: $display("%h", 4'b0101);
        7'h7D: $display("%h", 4'b0110);
        7'h07: $display("%h", 4'b0111);
        7'h7F: $display("%h", 4'b1000);
        7'h6F: $display("%h", 4'b1001);
        7'h77: $display("%h", 4'b1010);
        7'h7C: $display("%h", 4'b1011);
        7'h39: $display("%h", 4'b1100);
        7'h5E: $display("%h", 4'b1101);
        7'h79: $display("%h", 4'b1110);
        7'h71: $display("%h", 4'b1111);
    endcase

    case(~hex[20:14])
        7'h3F: $display("%h", 4'b0000);
        7'h06: $display("%h", 4'b0001);
        7'h5B: $display("%h", 4'b0010);
        7'h4F: $display("%h", 4'b0011);
        7'h66: $display("%h", 4'b0100);
        7'h6D: $display("%h", 4'b0101);
        7'h7D: $display("%h", 4'b0110);
        7'h07: $display("%h", 4'b0111);
        7'h7F: $display("%h", 4'b1000);
        7'h6F: $display("%h", 4'b1001);
        7'h77: $display("%h", 4'b1010);
        7'h7C: $display("%h", 4'b1011);
        7'h39: $display("%h", 4'b1100);
        7'h5E: $display("%h", 4'b1101);
        7'h79: $display("%h", 4'b1110);
        7'h71: $display("%h", 4'b1111);
    endcase

    case(~hex[13:7])
        7'h3F: $display("%h", 4'b0000);
        7'h06: $display("%h", 4'b0001);
        7'h5B: $display("%h", 4'b0010);
        7'h4F: $display("%h", 4'b0011);
        7'h66: $display("%h", 4'b0100);
        7'h6D: $display("%h", 4'b0101);
        7'h7D: $display("%h", 4'b0110);
        7'h07: $display("%h", 4'b0111);
        7'h7F: $display("%h", 4'b1000);
        7'h6F: $display("%h", 4'b1001);
        7'h77: $display("%h", 4'b1010);
        7'h7C: $display("%h", 4'b1011);
        7'h39: $display("%h", 4'b1100);
        7'h5E: $display("%h", 4'b1101);
        7'h79: $display("%h", 4'b1110);
        7'h71: $display("%h", 4'b1111);
    endcase

    case(~hex[6:0])
        7'h3F: $display("%h", 4'b0000);
        7'h06: $display("%h", 4'b0001);
        7'h5B: $display("%h", 4'b0010);
        7'h4F: $display("%h", 4'b0011);
        7'h66: $display("%h", 4'b0100);
        7'h6D: $display("%h", 4'b0101);
        7'h7D: $display("%h", 4'b0110);
        7'h07: $display("%h", 4'b0111);
        7'h7F: $display("%h", 4'b1000);
        7'h6F: $display("%h", 4'b1001);
        7'h77: $display("%h", 4'b1010);
        7'h7C: $display("%h", 4'b1011);
        7'h39: $display("%h", 4'b1100);
        7'h5E: $display("%h", 4'b1101);
        7'h79: $display("%h", 4'b1110);
        7'h71: $display("%h", 4'b1111);
    endcase

    // if ((~hex[13:7] == 7'h06) && (~hex[6:0] == 7'h06)) begin
    //     #(100); 
    //     btn[0] <= 1;
    //     #(30) btn[0] <= 0;
    // end

    $display("\n---------");
end

endmodule
`default_nettype wire