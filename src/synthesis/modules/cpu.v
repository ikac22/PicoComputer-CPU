module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input                   clk,
    input                   rst_n,
    input  [DATA_WIDTH-1:0] mem_in,

    input  [DATA_WIDTH-1:0] in,

    output reg              mem_we,
    output [ADDR_WIDTH-1:0] mem_addr,
    output [DATA_WIDTH-1:0] mem_data,

    output reg [DATA_WIDTH-1:0] out,
    output     [ADDR_WIDTH-1:0] pc,
    output     [ADDR_WIDTH-1:0] sp
);

    reg                   ldPC;
    reg                   incPC;

    register #(.DATA_WIDTH(ADDR_WIDTH)) u_pc(
        .clk(clk),
        .ld(ldPC),
        .in(6'd8),
        .inc(incPC),
        .out(pc)
    );

    reg                   ldSP;
    reg                   incSP;
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_sp(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldSP),
        .in(),
        .out(sp),
        .inc(incSp)
    );

    wire [DATA_WIDTH*2-1:0] ir;
    reg  [DATA_WIDTH*2-1:0] inIR;
    reg                     ldIR;
    register #(.DATA_WIDTH(DATA_WIDTH*2)) u_ir(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldIR),
        .in(inIR),
        .out(ir)
    );

    reg [ADDR_WIDTH-1:0] inMAR;
    reg                  ldMAR;
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_mar(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldMAR),
        .in(inMAR),
        .out(mem_addr)
    );

    reg  [DATA_WIDTH-1:0] inMDR;
    reg                   ldMDR;
    wire [DATA_WIDTH-1:0] mdr;
    register #(.DATA_WIDTH(DATA_WIDTH)) u_mdr(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldMDR),
        .in(inMDR),
        .out(mem_in)
    );

    wire [DATA_WIDTH-1:0] tmp1;
    reg                   ldTMP1;
    register #(.DATA_WIDTH(DATA_WIDTH)) u_tmp1(
        .clk(clk),
        .rst_n(rst_n),
        .in(mem_data),
        .ld(ldTMP1),
        .out(tmp1)
    );

    // wire [DATA_WIDTH-1:0] tmp2;
    // reg                   ldTMP2;
    // register #(.DATA_WIDTH(16)) u_tmp2(
    //     .clk(clk),
    //     .rst_n(rst_n),
    //     .in(mem_data),
    //     .ld(ldTMP2),
    //     .out(tmp2)
    // );

    wire [DATA_WIDTH-1:0] acc;
    reg                   ldA;
    reg  [DATA_WIDTH-1:0] inA;
    register #(.DATA_WIDTH(DATA_WIDTH)) u_acc(
        .clk(clk),
        .rst_n(rst_n),
        .in(inA),
        .ld(ldA),
        .out(acc)
    );

    wire [DATA_WIDTH-1:0] alu_out;
    reg  [2:0]            alu_oc;
    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu(
        .oc(ir[30:28] - 3'd1),
        .a(acc),
        .b(mem_data),
        .f(alu_out)
    );


    reg [3:0]             fsm_state;
    reg [3:0]             fsm_state_next;
    reg [DATA_WIDTH-1:0]  out_next;
    reg [1:0]             currOp_next;

    wire [3:0] opCode;
    wire [2:0] opAddr1, opAddr2, opAddr3;
    reg  [2:0] currOpAddr;
    reg  [1:0] currOp;
    reg        currOpMode;
    

    assign opAddr1 = ir[DATA_WIDTH+10:DATA_WIDTH+8];
    assign opAddr2 = ir[DATA_WIDTH+6:DATA_WIDTH+4];
    assign opAddr3 = ir[DATA_WIDTH+2:DATA_WIDTH];
    assign opCode  = ir[DATA_WIDTH*2-1:DATA_WIDTH*2-4];

    always @(*) begin
        incPC = 'd0;
        inIR = 'd0;
        ldPC = 'd0;
        ldIR = 'd0;
        ldTMP1 = 'd0;
        inA = 'd0;
        ldA = 'd0;
        incSP = 'd0;

        inMAR = 'd0;
        ldMAR = 'd0;
        ldMDR = 'd0;
        inMDR = 'd0;
        mem_we = 'd0;
    
        currOp_next = currOp;
        currOpMode = 'd0;
        currOpAddr = 'd0;
        
        out_next = out;
        fsm_state_next = fsm_state;

        case(fsm_state)
            // RESET
            'd0: begin
                ldPC = 1;
                // $display("start");
                fsm_state_next = 'd1;
            end
            // IF0 (MEMORY ACCESS)
            'd1: begin
                // $display("IF0");
                inMAR = pc;
                ldMAR = 1'b1;
                incPC = 1'b1;
                fsm_state_next = 'd2;
            end
            // IF1
            'd2: begin
                // $display("IF1");
                inIR[DATA_WIDTH*2-1:DATA_WIDTH] = mem_data;
                inIR[DATA_WIDTH-1:0] = {DATA_WIDTH{1'b0}};
                ldIR = 1'b1;
                if (mem_data[DATA_WIDTH-1:DATA_WIDTH-4] == 4'd0 && mem_data[3:0] == 4'd8) begin
                    inMAR = pc;
                    ldMAR = 1'b1;
                    incPC = 1'b1;
                    fsm_state_next = 'd3; // IF2
                end
                else
                    fsm_state_next = 'd4; // ID
            end
            // IF2
            'd3: begin
                // $display("IF2");
                inIR[DATA_WIDTH*2-1:DATA_WIDTH] = ir[DATA_WIDTH*2-1:DATA_WIDTH];
                inIR[DATA_WIDTH-1:0] = mem_data;
                ldIR = 1'b1;
                fsm_state_next = 'd4; // ID
            end
            // ID0            
            'd4: begin
                // $display("ID0");
                casex(opCode) 
                    // MOV
                    4'b0000:begin
                        // $display("MOV");
                        if(ir[DATA_WIDTH+3:DATA_WIDTH] == 4'd8) begin
                            inA = ir[DATA_WIDTH-1:0];
                            ldA = 1'b1;
                            currOp_next = 2'd3;
                            fsm_state_next = 'd6; //EXEC
                        end
                        else begin
                            if(currOp == 0) 
                                currOp_next = 1;
                            else if(currOp == 2) begin
                                inA = mem_data;
                                ldA = 1'b1;
                                fsm_state_next = 'd6; //EXEC
                                currOp_next = 2'd3;
                            end
                            else begin
                                currOp_next = currOp;
                            end
                        end
                    end
                    // IN
                    4'b0111: begin
                        // $display("IN");
                        inA = in;
                        ldA = 1'b1;
                        fsm_state_next = 'd6; //EXEC
                        currOp_next = 2'd3;
                    end
                    // OUT
                    4'b1000: begin
                        // $display("OUT");
                        if(currOp == 1) begin
                            inA = mem_data;
                            ldA = 1'b1;
                            currOp_next = 2'd3;
                            fsm_state_next = 'd6; //EXEC
                        end
                        else
                            currOp_next = currOp;
                    end
                    // ALU
                    4'b00xx, 4'b0100: begin
                        // $display("ALU");
                        if(currOp == 0) begin 
                            currOp_next = 1;
                        end
                        else
                        if(currOp == 2) begin
                            inA = mem_data;
                            ldA = 1'b1;    
                        end
                        else
                        if(currOp == 3) begin
                            currOp_next = 3;
                            fsm_state_next = 'd6; //EXEC
                        end
                        else 
                            currOp_next = currOp;
                    end
                    // STOP
                    4'b1111: begin
                        // $display("STOP");
                        if(currOp_next == 'd0) begin
                            if(opAddr1 != 3'd0)
                                currOp_next = currOp_next;
                            else
                                currOp_next = currOp_next + 1;
                        end
                        else 
                            currOp_next = currOp_next;

                        if(currOp_next == 'd1) begin
                            if(opAddr1 != 3'd0) begin
                                inA = mem_data;
                                ldA = 1'b1;
                            end
                            else
                                inA = inA;

                            if(opAddr2 != 3'd0)
                                currOp_next = currOp_next;
                            else
                                currOp_next = currOp_next + 1;
                        end
                        else 
                            currOp_next = currOp_next;
                        
                        if(currOp_next == 'd2) begin
                            if(opAddr2 != 3'd0)
                                ldTMP1 = 1'b1;
                            else
                                ldTMP1 = 1'b0;
                            
                            if(opAddr3 != 3'd0)
                                currOp_next = currOp_next;
                            else
                                currOp_next = currOp_next + 1;
                        end
                        else 
                            currOp_next = currOp_next;

                        if(currOp_next == 'd3) begin
                            fsm_state_next = 'd6; // EXEC
                        end
                        else begin
                            currOp_next = currOp_next;
                        end
                    end
                    default: begin
                        currOp_next = 2'd3;
                    end

                endcase


                case(currOp_next) 
                    2'd0: begin 
                        currOpAddr = opAddr1;
                        currOpMode = ir[DATA_WIDTH+11];
                    end
                    2'd1: begin 
                        currOpAddr = opAddr2;
                        currOpMode = ir[DATA_WIDTH+7];
                    end
                    2'd2: begin 
                        currOpAddr = opAddr3;
                        currOpMode = ir[DATA_WIDTH+3];
                    end
                    2'd3: currOpAddr = currOpAddr;
                endcase

                if(currOp_next != 3) begin
                    inMAR = {{(ADDR_WIDTH-3){1'b0}}, currOpAddr};
                    ldMAR = 1'b1;
                    if(currOpMode) begin
                        fsm_state_next = 'd5; // ID1
                    end
                    else begin
                        fsm_state_next = 'd4; // ID0
                    end
                    
                    currOp_next = currOp_next + 1;
                end
                else
                    currOp_next = 0;
            end
            // ID1 (INDIRECT ADDR OPERAND FETCH)
            'd5: begin
                // $display("ID1");
                inMAR = mem_data[ADDR_WIDTH-1:0];
                ldMAR = 1'b1;
                fsm_state_next = 'd4; // ID
            end
            // EXEC0
            'd6: begin
                // $display("EXEC0");
                casex(opCode) 
                    // MOV
                    4'b0000:begin
                        // $display("MOV");
                        if(ir[DATA_WIDTH+11] == 1'b0) begin 
                            inMDR = acc;
                            ldMDR = 1'b1;
                            inMAR = {{(ADDR_WIDTH-3){1'b0}}, ir[DATA_WIDTH+10:DATA_WIDTH+8]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd11; // EXEC2
                        end
                        else begin
                            inMAR = {{(ADDR_WIDTH-3){1'b0}}, ir[DATA_WIDTH+10:DATA_WIDTH+8]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd7; // EXEC1
                        end
                    end
                    // IN
                    4'b0111: begin
                        // $display("IN");
                        if(ir[DATA_WIDTH+11] == 1'b0) begin 
                            inMDR = acc;
                            ldMDR = 1'b1;
                            inMAR = {{(ADDR_WIDTH-3){1'b0}}, ir[DATA_WIDTH+10:DATA_WIDTH+8]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd11; // EXEC2
                        end
                        else begin
                            inMAR = {{(ADDR_WIDTH-3){1'b0}}, ir[DATA_WIDTH+10:DATA_WIDTH+8]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd7; // EXEC1
                        end
                    end
                    // OUT
                    4'b1000: begin
                        // $display("OUT");
                        out_next = acc;
                        fsm_state_next = 'd1; // IF
                    end
                    // ALU
                    4'b00xx, 4'b0100: begin
                        // $display("ALU");
                        if(ir[DATA_WIDTH+11] == 1'b0) begin 
                            inA = alu_out;
                            ldA = 1'b1;
                            inMDR = alu_out;
                            ldMDR = 1'b1;
                            inMAR = {{(ADDR_WIDTH-3){1'b0}}, ir[DATA_WIDTH+10:DATA_WIDTH+8]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd11; // EXEC2
                        end
                        else begin
                            inA = alu_out;
                            ldA = 1'b1;
                            inMAR = {{(ADDR_WIDTH-3){1'b0}}, ir[DATA_WIDTH+10:DATA_WIDTH+8]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd7; // EXEC1
                        end
                    end
                    // STOP0
                    4'b1111: begin
                        // $display("STOP0");
                        if(opAddr1 != 3'd0) begin
                            out_next = acc;
                            fsm_state_next = 'd8; // STOP1
                        end
                        else if(opAddr2 != 3'd0) begin
                            out_next = tmp1;
                            fsm_state_next = 'd9; // STOP2
                        end
                        else if(opAddr3 != 3'd0) begin
                            out_next = mem_data;
                            fsm_state_next = 'd10; // SPIN
                        end
                        else begin
                            fsm_state_next = 'd10; // SPIN
                        end
                    end
                    default: begin
                        fsm_state_next = 'd0; // RESET
                    end

                endcase
            end
            // STOP1
            'd8: begin
                // $display("STOP1");
                if(opAddr2 != 3'd0) begin
                    out_next = tmp1;
                    fsm_state_next = 'd9; // STOP2
                end
                else if(opAddr3 != 3'd0) begin
                    out_next = mem_data;
                    fsm_state_next = 'd10; // SPIN
                end
                else begin
                    fsm_state_next = 'd10; // SPIN
                end
            end
            // STOP2
            'd9: begin
                // $display("STOP2");
                if(opAddr3 != 3'd0) begin
                    out_next = mem_data;
                    fsm_state_next = 'd10; // SPIN
                end
                else begin
                    fsm_state_next = 'd10; // SPIN
                end
            end
            // EXEC1 (DEST ADDR FETCH)
            'd7: begin
                // $display("EXEC1");
                inMDR = acc;
                ldMDR = 1'b1;
                inMAR = mem_data[ADDR_WIDTH-1:0];
                ldMAR = 1'b1;
                fsm_state_next = 'd11; // WRITE MEM
            end
            // SPIN
            'd10: begin
                // $display("SPIN");
                fsm_state_next = 'd10; // SPIN
            end
            // EXEC2 (WRITE MEM)
            'd11: begin
                // $display("EXEC2");
                mem_we = 1'b1;
                fsm_state_next = 'd1;
            end
            default: begin
                // $display("default");
                fsm_state_next = 'd0;
            end
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        // // $display("CLK");
        if(!rst_n) begin
            // $display("RST");
            fsm_state <= 0;
            currOp <= 0;
            out <= 0;
        end
        else begin
            fsm_state <= fsm_state_next;
            // $display("fsm_state_next: %d", fsm_state_next);
            out <= out_next;
            currOp <= currOp_next;
        end
    end

endmodule
