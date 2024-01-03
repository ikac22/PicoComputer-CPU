module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input                   clk,
    input                   rst_n,
    input  [DATA_WIDTH-1:0] mem_in,

    input  [DATA_WIDTH-1:0] in,

    output                  mem_we,
    output [ADDR_WIDTH-1:0] mem_addr,
    output [DATA_WIDTH-1:0] mem_data,

    output [DATA_WIDTH-1:0] out,
    output [ADDR_WIDTH-1:0] pc,
    output [ADDR_WIDTH-1:0] sp
);

    wire [ADDR_WIDTH-1:0] pc;
    reg                   ldPC;
    reg                   incPC;

    register #(.DATA_WIDTH(6)) u_pc(
        .clk(clk),
        .ld(ldPC),
        .in(8),
        .inc(incPC),
        .out(pc)
    );

    wire [ADDR_WIDTH-1:0] sp;
    reg                   ldSP;
    register #(.DATA_WIDTH(6)) u_sp(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldSP),
        .in(),
        .out(sp)
    );

    wire [31:0] ir;
    reg         ldIR;
    register #(.DATA_WIDTH(32)) u_ir(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldIR),
        .in(mem_data),
        .out(ir)
    );

    reg [ADDR_WIDTH-1:0] inMAR;
    reg                  ldMAR;
    register #(.DATA_WIDTH(6)) u_mar(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldMAR),
        .in(inMAR),
        .out(mem_addr)
    );

    reg  [DATA_WIDTH-1:0] inMDR;
    reg                   ldMDR;
    wire [DATA_WIDTH-1:0] mdr;
    register #(.DATA_WIDTH(16)) u_mdr(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldMDR),
        .in(inMDR),
        .out(mdr)
    );

    register #(.DATA_WIDTH(16)) u_a(
        .clk(clk),
        .rst_n(rst_n),
        .in(inA),
        .out(a)
    );

    wire [DATA_WIDTH-1:0] tmp1;
    reg                   ldTMP1;
    register #(.DATA_WIDTH(16)) u_tmp1(
        .clk(clk),
        .rst_n(rst_n),
        .in(),
        .ld(ldTMP1),
        .out(tmp1)
    );

    wire [DATA_WIDTH-1:0] tmp2;
    reg                   ldTMP2;
    register #(.DATA_WIDTH(16)) u_tmp2(
        .clk(clk),
        .rst_n(rst_n),
        .in(),
        .ld(ldTMP2),
        .out(tmp2)
    );

    wire [DATA_WIDTH-1:0] alu_out;
    alu #(.DATA_WIDTH(16)) u_alu(
        .oc(),
        .a(tmp1),
        .b(tmp2),
        .f(alu_out)
    );

    reg [] fsm_state;
    reg [] fsm_state_next;

    always @(*) begin
        ldPC = 0;
        inMAR = 0;
        ldMAR = 0;
        ldIR = 0;

        case(fsm_state)
            // RESET
            'd0: begin
                ldPC = 1;

                fsm_state_next = 'd1;
            end
            // IF
            'd1: begin
                inMAR = pc;
                ldMAR = 1;

                incPC = 1;

                fsm_state_next = 'd2;
            end
            'd2: begin
                ldIR = 1;

                fsm_state_next = 'd3;
            end
            // ID
            'd2: begin

            end
            // EX
            'd3: begin

            end

        endcase
    end

    always @(posedge clk) begin
        if(!rst_n) begin
            fsm_state <= 0;
        end
        else begin
            case()

            endcase
        end
    end

endmodule
