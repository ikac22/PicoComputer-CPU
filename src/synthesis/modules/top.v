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
    output [9:0]  led,
    output [27:0] hex 
);


wire [8:0]            swDeb;
wire [2:0]            btnDeb;
wire                  divClk;
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

genvar i;
generate
    for (i = 0; i < 9; i = i + 1) begin: sw_deb_gen 
    	debouncer sw_deb(clk, rst_n, sw[i], swDeb[i]);
    end

    for (i = 0; i < 3; i = i + 1) begin: btn_deb_gen
        debouncer btn_deb(clk, rst_n, btn[i], btnDeb[i]);
    end
endgenerate
    


assign led = {{(DATA_WIDTH-4){1'b0}}, out[4:0]};

clk_div #(
    .DIVISOR(DIVISOR)
) u_div(
    .clk(clk),
    .rst_n(rst_n),
    .out(divClk)
);

register #(
    .DATA_WIDTH(DATA_WIDTH)
) in_register(
    .clk(clk),
    .rst_n(rst_n),
    .in({{(DATA_WIDTH-4){1'b0}}, sw[3:0]}),
    .ld(btn[0]),
    .out(in)
);

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

cpu #( 
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) u_cpu(
    .clk(divClk),
    .rst_n(rst_n),
    .mem_in(mem_in),
    .in(in),
    .mem_we(mem_we),
    .mem_addr(mem_addr),
    .mem_data(mem_data),
    .out(out),
    .pc(pc),
    .sp(sp)
);

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

// always @(divClk) begin
//     $display("divCLK");
// end

endmodule