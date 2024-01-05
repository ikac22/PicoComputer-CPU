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

    reg                   inPC;
    reg                   ldPC;
    reg                   incPC;

    register #(.DATA_WIDTH(6)) u_pc(
        .clk(clk),
        .ld(ldPC),
        .in(inPC),
        .inc(incPC),
        .out(pc)
    );

    reg                   ldSP;
    register #(.DATA_WIDTH(6)) u_sp(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldSP),
        .in(),
        .out(sp)
    );

    wire [31:0] ir;
    reg  [31:0] inIR;
    reg         ldIR;
    register #(.DATA_WIDTH(32)) u_ir(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldIR),
        .in(inIR),
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
    register #(.DATA_WIDTH(16)) u_acc(
        .clk(clk),
        .rst_n(rst_n),
        .in(inA),
        .ld(ldA),
        .out(acc)
    );

    wire [DATA_WIDTH-1:0] alu_out;
    reg  [2:0]            alu_oc;
    alu #(.DATA_WIDTH(16)) u_alu(
        .oc(ir[30:28]),
        .a(acc),
        .b(mem_data),
        .f(alu_out)
    );

    reg [3:0] fsm_state;
    reg [3:0] fsm_state_next;

    integer opInd, opEnd, bitInd;

    wire [3:0] opCode;
    wire [2:0] opAddr1, opAddr2, opAddr3;
    reg  [2:0] currOpAddr;
    reg  [1:0] currOp;
    reg        currOpMode;

    assign opAddr1 = ir[26:24];
    assign opAddr2 = ir[22:20];
    assign opAddr3 = ir[18:16];
    assign opCode  = ir[31:28];

    always @(*) begin
        ldPC = 0;
        inMAR = 0;
        ldMAR = 0;
        ldIR = 0;
        ldTMP1 = 0;
        // ldTMP2 = 0;
        ldA = 0;
        
        case(fsm_state)
            // RESET
            'd0: begin
                ldPC = 1;

                fsm_state_next = 'd1;
            end
            // IF
            'd1: begin
                inMAR = pc;
                ldMAR = 1'b1;
                incPC = 1'b1;
                fsm_state_next = 'd2;
            end
            'd2: begin
                inIR[31:16] = mem_data;
                inIR[15:0] = {16{1'b0}};
                ldIR = 1'b1;
                if (mem_data[15:12] == 4'd0 && mem_data[3:0] == 4'd8) begin
                    inMAR = pc;
                    ldMAR = 1'b1;
                    incPC = 1'b1;
                    fsm_state_next = 'd3;
                end
                else
                    fsm_state_next = 'd4;
            end
            'd3: begin
                inIR[15:0] = mem_data;
                ldIR = 1'b1;
                fsm_state_next = 'd4;
            end
            // ID            
            'd4: begin
                casex(opCode) 
                    // MOV
                    4'b0000:begin
                        if(ir[19:16] == 4'd0) begin
                            inA = ir[15:0];
                            ldA = 1'b1;
                            fsm_state_next = 'd6; //EXEC
                        end
                        else begin
                            if(currOp == 1) begin
                                inA = mem_data;
                                ldA = 1'b1;
                                fsm_state_next = 'd6; //EXEC
                                currOp = 2'd3;
                            end
                            else begin
                                currOp = currOp;
                            end
                        end
                    end
                    // IN
                    4'b0111: begin
                        inA = in;
                        ldA = 1'b1;
                        fsm_state_next = 'd6; //EXEC
                        currOp = 2'd3;
                    end
                    // OUT
                    4'b1000: begin
                        if(currOp == 1) begin
                            inA = mem_data;
                            ldA = 1'b1;
                            currOp = 2'd3;
                            fsm_state_next = 'd6; //EXEC
                        end
                        else
                            currOp = currOp;
                    end
                    // ALU
                    4'b00xx, 4'b0100: begin
                        if(currOp == 1) begin
                            inA = mem_data;
                            ldA = 1'b1;    
                        end
                        else
                        if(currOp == 2) begin
                            currOp = 3;
                            fsm_state_next = 'd6;
                        end
                        else 
                            currOp = currOp;
                    end
                    //STOP
                    4'b1111: begin
                        if(currOp == 'd0) begin
                            if(opAddr1 != 3'd0)
                                currOp = currOp;
                            else
                                currOp = currOp + 1;
                        end
                        else 
                            currOp = currOp;

                        if(currOp == 'd1) begin
                            if(opAddr1 != 3'd0) begin
                                inA = mem_data;
                                ldA = 1'b1;
                            end
                            else
                                inA = inA;

                            if(opAddr2 != 3'd0)
                                currOp = currOp;
                            else
                                currOp = currOp + 1;
                        end
                        else 
                            currOp = currOp;
                        
                        if(currOp == 'd2) begin
                            if(opAddr2 != 3'd0)
                                ldTMP1 = 1'b1;
                            else
                                ldTMP1 = 1'b0;
                            
                            if(opAddr3 != 3'd0)
                                currOp = currOp;
                            else
                                currOp = currOp + 1;
                        end
                        else 
                            currOp = currOp;
                        
                        if(currOp == 'd3) 
                            currOp = currOp;
                        else 
                            currOp = currOp;
                    end
                    default: begin
                        currOp = 2'd3;
                    end

                endcase


                case(currOp) 
                    2'd0: begin 
                        currOpAddr = opAddr1;
                        currOpMode = ir[27];
                    end
                    2'd1: begin 
                        currOpAddr = opAddr1;
                        currOpMode = ir[23];
                    end
                    2'd2: begin 
                        currOpAddr = opAddr1;
                        currOpMode = ir[19];
                    end
                    2'd3: currOpAddr = currOpAddr;
                endcase

                if(currOp != 3) begin
                    inMAR = {{3{1'b0}}, currOpAddr};
                    ldMAR = 1'b1;
                    if(currOpMode) begin
                        fsm_state_next = 'd5;
                    end
                    else begin
                        fsm_state_next = 'd4;
                    end
                    currOp = currOp + 1;
                end
                else
                    currOp = 0;
            end
            //OF
            'd5: begin
                inMAR = mem_data[5:0];
                ldMAR = 1'b1;
                fsm_state_next = 'd4;
            end
            // EX
            'd6: begin
                casex(ir[31:28]) 
                    // MOV
                    4'b0000:begin
                        if(ir[27] == 1'b0) begin 
                            inMDR = acc;
                            ldMDR = 1'b1;
                            inMAR = {{3{1'b0}}, ir[26:24]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd1;
                        end
                        else begin
                            inMAR = {{3{1'b0}}, ir[26:24]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd7;
                        end
                    end
                    // IN
                    4'b0111: begin
                        if(ir[27] == 1'b0) begin 
                            inMDR = acc;
                            ldMDR = 1'b1;
                            inMAR = {{3{1'b0}}, ir[26:24]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd1;
                        end
                        else begin
                            inMAR = {{3{1'b0}}, ir[26:24]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd7;
                        end
                    end
                    // OUT
                    4'b1000: begin
                        out = acc;
                        fsm_state_next = 'd1;
                    end
                    // ALU
                    4'b00xx, 4'b0100: begin
                        if(ir[27] == 1'b0) begin 
                            inA = alu_out;
                            ldA = 1'b1;
                            inMDR = alu_out;
                            ldMDR = 1'b1;
                            inMAR = {{3{1'b0}}, ir[26:24]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd1;
                        end
                        else begin
                            inA = alu_out;
                            ldA = 1'b1;
                            inMAR = {{3{1'b0}}, ir[26:24]};
                            ldMAR = 1'b1;
                            fsm_state_next = 'd7;
                        end
                    end
                    //STOP
                    4'b1111: begin
                        if(opAddr1 != 3'd0) begin
                            out = acc;
                            fsm_state_next = 'd8;
                        end
                        else if(opAddr2 != 3'd0) begin
                            out = tmp1;
                            fsm_state_next = 'd9;
                        end
                        else if(opAddr3 != 3'd0) begin
                            out = mem_data;
                            fsm_state_next = 'd10;
                        end
                        else begin
                            fsm_state_next = 'd10;
                        end
                    end
                    default: begin
                        fsm_state_next = 'd0;
                    end

                endcase
            end
            'd8: begin
                if(opAddr2 != 3'd0) begin
                    out = tmp1;
                    fsm_state_next = 'd9;
                end
                else if(opAddr3 != 3'd0) begin
                    out = mem_data;
                    fsm_state_next = 'd10;
                end
                else begin
                    fsm_state_next = 'd10;
                end
            end
            'd9: begin
                if(opAddr3 != 3'd0) begin
                    out = mem_data;
                    fsm_state_next = 'd10;
                end
                else begin
                    fsm_state_next = 'd10;
                end
            end
            'd7: begin
                inMDR = acc;
                ldMDR = 1'b1;
                inMAR = mem_data[5:0];
                ldMAR = 1'b1;
                fsm_state_next = 'd1;
            end
            // SPIN
            'd10: begin
                fsm_state_next = 'd10;
            end
        endcase
    end

    always @(posedge clk) begin
        if(!rst_n) begin
            fsm_state <= 0;
            currOp <= 0;
            out <= 0;
            mem_we <= 0;

        end
        else begin
            fsm_state <= fsm_state_next;
        end
    end

endmodule
