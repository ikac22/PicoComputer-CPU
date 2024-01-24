module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input  [2:0]  btn,
    input  [8:0]  sw, 
`ifdef PHASE_3
    input  [1:0]  kbd,
    output [13:0] mnt,
`endif
    output [9:0]  led,
    output [27:0] hex
);


//// TESTING WIRES ////
`ifdef TEST
    wire [6:0]            bcd1;
    wire [6:0]            bcd2;
    wire [4:0]            led1;   
    wire [3:0]            hex_digit1;
    wire [3:0]            hex_digit2;         
`endif
//// DEBOUNCED WIRES ////
wire [8:0]            swDeb;
wire [2:0]            btnDeb;
//// DIVIDED CLK ////
wire                  divClk;
//// WIRRES FOR CONNECTING ////
wire [DATA_WIDTH-1:0] in;
wire [DATA_WIDTH-1:0] out;
wire [DATA_WIDTH-1:0] mem_in;
wire [DATA_WIDTH-1:0] mem_data;
wire [ADDR_WIDTH-1:0] mem_addr;
wire                  mem_we;
wire [ADDR_WIDTH-1:0] pc;
wire [ADDR_WIDTH-1:0] sp;
wire [3:0]            pc_ones, pc_tens;
wire [3:0]            sp_ones, sp_tens;
wire                  control;

`ifndef SIMUL
    // if testing is done on the device then debouncers are needed
    genvar i;
    generate    
        for (i = 0; i < 9; i = i + 1) begin: sw_deb_gen 
            debouncer u_sw_deb(clk, rst_n, sw[i], swDeb[i]);
        end

        for (i = 0; i < 3; i = i + 1) begin: btn_deb_gen
            debouncer u_btn_deb(clk, rst_n, btn[i], btnDeb[i]);
        end
    endgenerate
`else
    // if running in simulation there is no need fo debouncers
    assign swDeb = sw;
    assign btnDeb = btn;
`endif

//// MAIN CLK DIVIDER ////
clk_div #(
    .DIVISOR(DIVISOR)
) u_div(
    .clk(clk),
    .rst_n(rst_n),
    .out(divClk)
);


//// INPUT //// 
`ifndef PHASE_3 
    // input with buttons and switches
    red u_control_red(
        .clk(divClk),
        .rst_n(rst_n),
        .in(btnDeb[0]),
        .out(control)
    );
`else
    // input with ps/2 keyboard
    wire        signal;
    wire [15:0] ps2_code;
    wire        ps2_clock;

    // needed because there is no schmit circ on ps/2 clk pin on Cyclone 3
    debouncer u_ps2_deb(clk, rst_n, kbd[0], ps2_clock);

    ps2 u_ps2(
        .clk(clk),
        .rst_n(rst_n),
        .ps2_clk(ps2_clock),
        .ps2_data(kbd[1]),
        .code(ps2_code)
    );

    scan_codes u_scan_codes(
        .clk(clk),
        .rst_n(rst_n),
        .code(ps2_code),
        .signal(signal),
        .control(control),
        .num(in[3:0])
    );
`endif

 //// OUTPUT ////
`ifndef TEST 
    // if no testing is done then use just 
    // 5 lower leds for first type of output
    assign led = {{4{1'b0}}, out[4:0]};
`else
    // if testing 5 higher pins are used for 
    // displaying defined signals on led1
    assign led[4:0] = out[4:0];
    assign led[9:5] = led1[4:0];
`endif

`ifdef PHASE_3
    // Second type of display is through the
    // vga monitor where color of left half of the screen
    // represents tens digit of output and
    // right half represents ones digit.
    wire [23:0] colors;
    wire        vga_div;

    color_codes u_color_codes(
        .num(out[5:0]),
        .code(colors)
    );

    vga u_vga(
        .clk(clk),
        .rst_n(rst_n),
        .code(colors),
        .hsync(mnt[13]),
        .vsync(mnt[12]),
        .red(mnt[11:8]),
        .green(mnt[7:4]),
        .blue(mnt[3:0])
    );
`endif

//// MEMORY ////
memory #( 
    .FILE_NAME(FILE_NAME),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) u_mem  (
    .clk(divClk),
    .we(mem_we),
    .rst_n(rst_n),
    .addr(mem_addr),
    .data(mem_in),
    .out(mem_data)
);

//// CPU ////
cpu #( 
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) u_cpu(
    .clk(divClk),
    .rst_n(rst_n),
    .mem_in(mem_data),
`ifndef PHASE_3 // type of input
    .in({{(DATA_WIDTH-4){1'b0}}, swDeb[3:0]}),
`else
    .in({{(DATA_WIDTH-4){1'b0}}, in[3:0]}),
    .signal(signal),
`endif    
    .control(control),
    .mem_we(mem_we),
    .mem_addr(mem_addr),
    .mem_data(mem_in),
    .out(out),
    .pc(pc),
    .sp(sp)
`ifdef TEST // signals that exist only while testing
    , .bcd1(bcd1),
    .bcd2(bcd2),
    .led1(led1),
    .hex_digit1(hex_digit1),
    .hex_digit2(hex_digit2)
`endif
);



`ifndef TEST
    // If not testing first two digits of the seven segment
    // stand for decimal rep of stack pointer, where other 
    // two stand for decimal rep of program counter.
    bcd u_bcd_pc(
        .in(pc),
        .ones(pc_ones),
        .tens(pc_tens)
    );

    bcd u_bcd_sp(
        .in(sp),
        .ones(sp_ones),
        .tens(sp_tens)
    );

    ssd u_ssd_pc_ones(
        .in(pc_ones),
        .out(hex[6:0])
    );

    ssd u_ssd_pc_tens(
        .in(pc_tens),
        .out(hex[13:7])
    );

    ssd u_ssd_sp_ones(
        .in(sp_ones),
        .out(hex[20:14])
    );

    ssd u_ssd_sp_tens(
        .in(sp_tens),
        .out(hex[27:21])
    );
`else
    // If testing seven segment is used for 
    // decimal representations of customly defined values: bcd1, bcd2

    bcd u_bcd_pc(
        .in(bcd1),
        .ones(pc_ones),
        .tens(pc_tens)
    );

    bcd u_bcd_sp(
        .in(bcd2),
        .ones(sp_ones),
        .tens(sp_tens)
    );


    `ifndef HEXTEST_1
        // If hextesting then each hex digit 
        // can be changed on differently defined values. 
        ssd u_ssd_pc_ones(
            .in(pc_ones),
            .out(hex[6:0])
        );

        ssd u_ssd_pc_tens(
            .in(pc_tens),
            .out(hex[13:7])
        );
    `else
        ssd u_ssd_pc_ones(
            .in(pc_ones),
            .out(hex[6:0])
        );

        ssd u_ssd_pc_tens(
            .in(pc_tens),
            .out(hex[13:7])
        );
    `endif

    `ifndef HEXTEST_2
        ssd u_ssd_sp_ones(
            .in(sp_ones),
            .out(hex[20:14])
        );

        ssd u_ssd_sp_tens(
            .in(sp_tens),
            .out(hex[27:21])
        );
    `else
        ssd u_ssd_sp_ones(
            .in(ps2_code[3:0]),
            .out(hex[20:14])
        );

        ssd u_ssd_sp_tens(
            .in(ps2_code[7:4]),
            .out(hex[27:21])
        );
    `endif
`endif

endmodule