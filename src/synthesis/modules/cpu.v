//// INSTRUCTION SEGMENTS ////
`define INS_CODE_W  DATA_WIDTH-1:DATA_WIDTH-4
`define IMM_IND_W   3:0     

`define IMM_IND     DATA_WIDTH+3:DATA_WIDTH
`define INS_CODE    DATA_WIDTH*2-1:DATA_WIDTH*2-4
`define OP0         DATA_WIDTH+10:DATA_WIDTH+8
`define OP1         DATA_WIDTH+6:DATA_WIDTH+4
`define OP2         DATA_WIDTH+2:DATA_WIDTH
`define OP0_MODE    DATA_WIDTH+11
`define OP1_MODE    DATA_WIDTH+7
`define OP2_MODE    DATA_WIDTH+3
`define WORD1       DATA_WIDTH*2-1:DATA_WIDTH
`define WORD2       DATA_WIDTH-1:0

`define OP_IND(i)   

module cpu #(
    parameter                   ADDR_WIDTH = 6,
    parameter                   DATA_WIDTH = 16
) (
    /// CLK AND RESET WIRES //// 
    input                       clk,
    input                       rst_n,
    
    //// INPUT WIRES
    input      [DATA_WIDTH-1:0] in,
    input                       control,
    
    //// SIGNAL WIRE ////
`ifdef PHASE_3
    output reg                  signal,
`endif
    
    //// MEMORY WIRES
    output reg                  mem_we,
    output     [ADDR_WIDTH-1:0] mem_addr,
    output     [DATA_WIDTH-1:0] mem_data,
    input      [DATA_WIDTH-1:0] mem_in,
    
    //// OUTPUT WIRES ////
    output reg [DATA_WIDTH-1:0] out,
    output     [ADDR_WIDTH-1:0] pc,
    output     [ADDR_WIDTH-1:0] sp

    //// TESTING WIRES ////
`ifdef TEST
   ,output     [5:0]            bcd1,
    output     [5:0]            bcd2,
    output     [4:0]            led1,
    output     [3:0]            hex_digit1,
    output     [3:0]            hex_digit2      
`endif
);

//////// MODULES ////////

    //// PC REGISTER ////
    reg                     ldPC;
    reg                     incPC;
    `ifdef TEST
        wire [ADDR_WIDTH-1:0] toutPC;
    `endif
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_pc(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldPC),
        .in(6'd8),
        .inc(incPC),
        .out(pc)
    `ifdef TEST
      , .tout(toutPC)
    `endif
    );

    //// SP REGISTER ////
    reg                     ldSP;
    reg                     incSP;
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_sp(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldSP),
        .in(),
        .out(sp),
        .inc(incSp)
    );

    //// IR ////
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

    //// MAR ////
    reg [ADDR_WIDTH-1:0]    inMAR;
    reg                     ldMAR;
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_mar(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldMAR),
        .in(inMAR),
        .out(mem_addr)
    );

    //// MDR //// 
    reg  [DATA_WIDTH-1:0]   inMDR;
    reg                     ldMDR;
    wire [DATA_WIDTH-1:0]   mdr;
    register #(.DATA_WIDTH(DATA_WIDTH)) u_mdr(
        .clk(clk),
        .rst_n(rst_n),
        .ld(ldMDR),
        .in(inMDR),
        .out(mem_data)
    );

    //// TMP1 REGISTER ////
    wire [DATA_WIDTH-1:0]   tmp1;
    reg                     ldTMP1;
    register #(.DATA_WIDTH(DATA_WIDTH)) u_tmp1(
        .clk(clk),
        .rst_n(rst_n),
        .in(mem_in),
        .ld(ldTMP1),
        .out(tmp1)
    );

    //// ACCUMULATOR ////
    wire [DATA_WIDTH-1:0]   acc;
    reg                     ldA;
    reg  [DATA_WIDTH-1:0]   inA;
    register #(.DATA_WIDTH(DATA_WIDTH)) u_acc(
        .clk(clk),
        .rst_n(rst_n),
        .in(inA),
        .ld(ldA),
        .out(acc)
    );

    //// ALU ////
    wire [DATA_WIDTH-1:0]   alu_out;
    reg  [2:0]              alu_oc;
    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu(
        .oc(ir[30:28] - 3'd1),
        .a(acc),
        .b(mem_in),
        .f(alu_out)
    );

//////// WIRES and REGS ////////
    //// FSM REGS////
    reg [3:0]               fsm_state;
    reg [3:0]               fsm_state_next;

    //// OUTPUT REG ////
    reg [DATA_WIDTH-1:0]    out_next;

    //// OPERATOR WIRES ////
    wire [3:0]              opCode  = ir[`INS_CODE];
    wire [2:0]              opAddr1 = ir[`OP0];
    wire [2:0]              opAddr2 = ir[`OP1];
    wire [2:0]              opAddr3 = ir[`OP2];

    //// OPERATOR REGS ////
    reg  [1:0]              currOp; // count of the loaded SOURCE operands // TODO: change to cntOp
    reg  [1:0]              currOp_next; // TODO: change to cntOp_next
    reg  [2:0]              currOpAddr;
    reg                     currOpMode;
    

    //// SIGNAL REG ////
`ifdef PHASE_3
    reg                     signal_next;
    //// READY TO READ CONDITION ////
    wire                    ready_to_read = signal && control;
`else
    wire                    ready_to_read = control;
`endif

    //// ASSIGN TESTING WIRES ////
`ifdef TEST
    assign                  bcd1 = fsm_state;
    assign                  led1 = 0;
    assign                  bcd2 = pc;
    assign                  hex_digit1 = mem_in[DATA_WIDTH-1:DATA_WIDTH-4];
    assign                  hex_digit2 = mem_in[DATA_WIDTH-5:DATA_WIDTH-8];
`endif 

    //// MODIFICATION PHASE 2 ////
`ifdef MODIF
    //// VECTOR OPERATION ////
    wire                    vector_op = (opCode == 4'b1001) | (opCode == 4'b1010);  
    
    //// COUNTER REGISTER ////
    reg                     ldCNT;
    reg                     decCNT;
    reg  [ADDR_WIDTH:0]     inCNT;
    wire [ADDR_WIDTH:0]     cnt;
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_cnt(
        .clk(clk),
        .rst_n(rst_n),
        .in(inCNT),
        .dec(decCNT),
        .ld(ldCNT),
        .out(cnt)
    );

    //// POINTER1 REGISTER ////
    reg                     ldPOINTER1;
    reg                     incPOINTER1;
    reg  [ADDR_WIDTH:0]     inPOINTER1;
    wire [ADDR_WIDTH:0]     pointer1;
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_pointer1(
        .clk(clk),
        .rst_n(rst_n),
        .in(inPOINTER1),
        .inc(incPOINTER1),
        .ld(ldPOINTER1),
        .out(pointer1)
    );

    //// POINTER2 REGISTER ////
    reg                     ldPOINTER2;
    reg                     incPOINTER2;
    reg  [ADDR_WIDTH:0]     inPOINTER2;
    wire [ADDR_WIDTH:0]     pointer2;
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_pointer2(
        .clk(clk),
        .rst_n(rst_n),
        .in(inPOINTER2),
        .inc(incPOINTER2),
        .ld(ldPOINTER2),
        .out(pointer2)
    );
`endif

//////// COMBINATION LOGIC ////////
    always @(*) begin
        //// REG INIT ////
        incPC   = 'd0;
        ldPC    = 'd0;

        incSP   = 'd0;

        inIR    = 'd0;
        ldIR    = 'd0;

        ldTMP1  = 'd0;
        
        inA     = 'd0;
        ldA     = 'd0;

        inMAR   = 'd0;
        ldMAR   = 'd0;
        ldMDR   = 'd0;
        inMDR   = 'd0;
        mem_we  = 'd0;
        
        fsm_state_next = fsm_state;

        currOp_next = currOp;
        currOpMode  = 'd0;
        currOpAddr  = 'd0;
        
        out_next = out;

`ifdef PHASE_3
        signal_next = signal;
`endif

`ifdef MODIF
        ldCNT   = 0;
        decCNT  = 0;
        inCNT   = 0;

        ldPOINTER1  = 0;
        incPOINTER1 = 0;
        inPOINTER1  = 0;

        ldPOINTER2  = 0;
        incPOINTER2 = 0;
        inPOINTER2  = 0;
`endif
        //// FSM IMP ////
        case(fsm_state)
            // RESET
            'd0: begin
                fsm_state_next = 4'd12;
            end

            // LOAD AFTER RESET // NOT NEEDED ?
            'd12: begin
                ldPC = 1'b1;
                fsm_state_next = 2'd1;
            end

            // IF0 (MEMORY ACCESS)
            'd1: begin
                inMAR = pc;
                ldMAR = 1'b1;
                incPC = 1'b1;
                fsm_state_next = 'd2;
            end
            
            // IF1
            'd2: begin
                // Fetch the first word of instruction
                ldIR = 1'b1;
                inIR[`WORD1] = mem_in;
                inIR[`WORD2] = {DATA_WIDTH{1'b0}};
                
                if (mem_in[`INS_CODE_W] == 4'd0 &&
                    mem_in[`IMM_IND_W] == 4'd8) 
                    // If instruction is IMM_MOV go to IF2 state 
                begin
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
                // Fetch the second word of instruction(imm)
                inIR[`WORD1] = ir[`WORD1];
                inIR[`WORD2] = mem_in;
                ldIR = 1'b1;
                fsm_state_next = 'd4; // ID
            end

            // ID0            
            'd4: begin
                // Decode the instruction code
                casex(opCode) 
                    // MOV_ID
                    4'b0000:begin
                        // Fetch the operands
                        if(ir[`IMM_IND] == 4'd8) begin 
                            // IMM_MOV
                            // second instruction word is the operand
                            inA = ir[`WORD2];
                            ldA = 1'b1;
                            currOp_next = 2'd3;
                            fsm_state_next = 'd6; //EXEC
                        end
                        else begin
                            // mov has 1 operand on the 1-st pos
                            case(currOp)
                                0: currOp_next = 1; // skip the 0-th operand 
                                2: begin
                                    // operand 1 is on memory output
                                    inA = mem_in; 
                                    ldA = 1'b1;
                                    fsm_state_next = 'd6; //EXEC
                                    currOp_next = 2'd3; // indicator to finish fetching operands
                                end
                                default: currOp_next = currOp;
                            endcase
                        end
                    end
                    
                    // IN_ID
                    4'b0111: begin
                        currOp_next = 2'd3; // IN has no SOURCE operands
                        if(ready_to_read) begin
                            // the data is ready on the in line
                            inA = in;
                            ldA = 1'b1;
                            fsm_state_next = 'd6;
                            `ifdef PHASE_3
                                // turn off the signal value
                                signal_next = 1'b0; 
                            `endif
                        end
                        else begin
                            // the data is not ready
                            fsm_state_next = 'd4;
                            `ifdef PHASE_3
                                // keep signal on
                                signal_next = 1'b1;
                            `endif
                        end
                    end

                    // OUT_ID
                    4'b1000: begin
                        case(currOp)
                            1: begin
                                // operand 0 is on mem out
                                inA = mem_in;
                                ldA = 1'b1;
                                currOp_next = 2'd3;
                                fsm_state_next = 'd6; //EXEC
                            end
                            default: currOp_next = currOp;
                        endcase                
                    end

                    // ALU_ID
                    4'b0001, 4'b0100, 4'b0010, 4'b0011: 
                    begin
                        case(currOp)
                            0: currOp_next = 1; // skip operand 0
                            2: begin
                                // operand 1 is on mem out
                                inA = mem_in;
                                ldA = 1'b1;    
                            end
                            3: begin
                                // operand 2 is on mem out (keep it there)
                                currOp_next = 3;
                                fsm_state_next = 'd6; //EXEC
                            end
                            default: currOp_next = currOp;
                        endcase
                    end

                    // STOP_ID
                    4'b1111: begin
                        // go through operands to se which to fetch 
                        if(currOp_next == 'd0) begin
                            // there are no operands on mem out
                            if(opAddr1 != 3'd0)
                                // 0-th operand is not 0
                                currOp_next = currOp_next; // fetch 0th operand
                            else
                                currOp_next = currOp_next + 1; // just check next
                        end
                        else 
                            // the instruction has operand on mem out
                            // so keep the track on which
                            currOp_next = currOp_next;

                        if(currOp_next == 'd1) begin
                            // maybe 1-st operand on mem out
                            if(opAddr1 != 3'd0) begin
                                // 1-st operand on mem out 
                                // because it is not 0
                                inA = mem_in;
                                ldA = 1'b1;
                            end
                            else
                                // came here by incrementing currOp_next
                                inA = inA;

                            if(opAddr2 != 3'd0) // same as for opAddr1
                                currOp_next = currOp_next;
                            else
                                currOp_next = currOp_next + 1;
                        end
                        else 
                            currOp_next = currOp_next;
                        
                        if(currOp_next == 'd2) begin
                            // same as for operand 1
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
                            // we ended up here so we fetched all operands
                            // or came here by incrementing
                            fsm_state_next = 'd6; // EXEC
                        end
                        else begin
                            // there must be an else so
                            currOp_next = currOp_next;
                        end
                    end

                `ifdef MODIF // VECTOR OPERATION MODIFICATION
                    // instructions accept just 3 byte addresses !!! 
                    // TODO: CHANGE to get addresses from registers

                    // TODO: generalize vector instructions and merge into one case
                            // each instruction places DEST addr in POINTER1 and uses addr1 as DEST address
                            // each instruction places SOURCE addr in POINTER2 and uses addr2 as SOURCE address
                            // CAN THIS BE DONE IF WE USE REGISTER ADDRESSING???
                                // we dont know if both registers are needed -> solution wire that checks this with inst code

                    // VECTOR_MOV_ID
                    4'b1001: begin
                        // init counter
                        inCNT = opAddr3;
                        ldCNT = 1'b1;

                        // init dest pointer
                        inPOINTER1 = opAddr1;
                        ldPOINTER1 = 1'b1;

                        // init source pointer
                        inPOINTER2 = opAddr2;
                        ldPOINTER2 = 1'b1;

                        currOp_next = 2'd3; // no operands
                        fsm_state_next = 'd6; // EXEC
                    end

                    // VECTOR_OUT_ID
                    4'b1010: begin
                        // init counter
                        inCNT = opAddr3;
                        ldCNT = 1'b1;

                        // init source pointer
                        inPOINTER1 = opAddr1;
                        ldPOINTER1 = 1'b1;

                        currOp_next = 2'd3; // no operands
                        fsm_state_next = 'd6; // EXEC
                    end
                `endif
                    default: begin
                        currOp_next = 2'd3;
                    end

                endcase

                //// OPERAND FETCH LOGIC ////

                // set parameters based on which operand is next to be loaded
                case(currOp_next) 
                    2'd0: begin 
                        // 0-th operand
                        currOpAddr = opAddr1;
                        currOpMode = ir[`OP0_MODE];
                    end
                    2'd1: begin 
                        // 1-st operand
                        currOpAddr = opAddr2;
                        currOpMode = ir[`OP1_MODE];
                    end
                    2'd2: begin 
                        // 2-nd operand
                        currOpAddr = opAddr3;
                        currOpMode = ir[`OP2_MODE];
                    end
                    2'd3: currOpAddr = currOpAddr; // no operands
                endcase

                if(currOp_next != 3) begin
                    // there is operand to be loaded
                    inMAR = {{(ADDR_WIDTH-3){1'b0}}, currOpAddr};
                    ldMAR = 1'b1;
                    if(currOpMode) begin
                        // indirect addressing
                        fsm_state_next = 'd5; // ID1
                    end
                    else begin
                        // direct addressing
                        fsm_state_next = 'd4; // ID0
                    end
                    
                    currOp_next = currOp_next + 1;
                end
                else
                    currOp_next = 0; // there is no operand to be loaded
            end

            // ID1 (INDIRECT ADDR OPERAND FETCH)
            'd5: begin
                inMAR = mem_in[ADDR_WIDTH-1:0];
                ldMAR = 1'b1;
                fsm_state_next = 'd4; // ID
            end

            // EXEC0
            'd6: begin
                // execute instruction based on code
                casex(opCode) 
                    // MOV_EXEC
                    4'b0000:begin
                        inMAR = {{(ADDR_WIDTH-3){1'b0}}, opAddr1};
                        ldMAR = 1'b1;
                        if(ir[`OP0_MODE] == 1'b0) begin 
                            // direct dest reg addressing
                            inMDR = acc;
                            ldMDR = 1'b1;
                            fsm_state_next = 'd11; // EXEC2
                        end
                        else 
                            // indirect dest reg addressing
                            fsm_state_next = 'd7; // EXEC1
                    end

                    // IN_EXEC
                    4'b0111: begin
                        // branch is same as the MOV_EXEC // TODO: merge them
                        inMAR = {{(ADDR_WIDTH-3){1'b0}}, opAddr1};
                        ldMAR = 1'b1;
                        if(ir[`OP0_MODE] == 1'b0) begin 
                            inMDR = acc;
                            ldMDR = 1'b1;
                            fsm_state_next = 'd11; // EXEC2
                        end
                        else 
                            fsm_state_next = 'd7; // EXEC1
                    
                    end

                    // OUT_EXEC
                    4'b1000: begin
                        // set output to be what is in accumulator
                        out_next = acc;
                        fsm_state_next = 'd1; // IF
                    end

                    // ALU_EXEC
                    4'b0001, 4'b0010, 4'b0011, 4'b0100: 
                    begin
                        inMAR = {{(ADDR_WIDTH-3){1'b0}}, opAddr1};
                        ldMAR = 1'b1;
                        if(ir[`OP0_MODE] == 1'b0) begin 
                            // direct addr of dest reg
                            // load result to accumulator and store into memory
                            inA = alu_out;
                            ldA = 1'b1;
                            inMDR = alu_out;
                            ldMDR = 1'b1;
                            fsm_state_next = 'd11; // EXEC2
                        end
                        else begin
                            // indirect addr of dest reg
                            // load result into accumulator
                            inA = alu_out;
                            ldA = 1'b1;
                            fsm_state_next = 'd7; // EXEC1
                        end
                    end

                    // STOP_EXEC0
                    4'b1111: begin
                        // SPIT FIRST NOT NULL OPERAND
                        if(opAddr1 != 3'd0) begin
                            // if there is first operand then it is in accumulator
                            out_next = acc;
                            fsm_state_next = 'd8; // STOP1
                        end
                        else if(opAddr2 != 3'd0) begin
                            // if there is first operand then it is in tmp
                            out_next = tmp1;
                            fsm_state_next = 'd9; // STOP2
                        end
                        else if(opAddr3 != 3'd0) begin
                            // if there is first operand then it is on mem out
                            out_next = mem_in;
                            fsm_state_next = 'd10; // SPIN
                        end
                        else begin
                            fsm_state_next = 'd10; // SPIN
                        end
                    end

                `ifdef MODIF
                    // VECTOR_MOV_EXEC
                    4'b1001: begin
                        if(cnt != 0) begin
                            // there is more so read from src pointer 
                            inMAR = pointer2;
                            ldMAR = 1'b1;
                            incPOINTER2 = 1'b1; // increment src pointer
                            decCNT = 1'b1; // decrement counter
                            fsm_state_next = 'd13; // VECTOR STATE
                        end
                        else begin
                           fsm_state_next = 'd1; 
                        end
                    end

                    // VECTOR_OUT_EXEC
                    4'b1010: begin
                        // if both instructions used same pointers as source
                        // this two cases could be merged // TODO: change and merge
                        if(cnt != 0) begin
                            // there ismore so read from src pointer
                            inMAR = pointer1;
                            ldMAR = 1'd1;
                            incPOINTER1 = 1'b1;
                            decCNT = 1'b1;
                            fsm_state_next = 'd13; // VECTOR STATE
                        end
                        else begin
                           fsm_state_next = 'd1; 
                        end
                        
                    end
                `endif
                    default: begin
                        fsm_state_next = 'd0; // RESET
                    end
                endcase
            end

            // STOP_EXEC1
            'd8: begin
                // SPIT SECOND NOT NULL OPERAND
                if(opAddr2 != 3'd0) begin
                    out_next = tmp1;
                    fsm_state_next = 'd9; // STOP2
                end
                else if(opAddr3 != 3'd0) begin
                    out_next = mem_in;
                    fsm_state_next = 'd10; // SPIN
                end
                else begin
                    fsm_state_next = 'd10; // SPIN
                end
            end

            // STOP_EXEC2
            'd9: begin
                // SPIT THIRD NOT NULL OPERAND
                if(opAddr3 != 3'd0) begin
                    out_next = mem_in;
                    fsm_state_next = 'd10; // SPIN
                end
                else begin
                    fsm_state_next = 'd10; // SPIN
                end
            end

            // EXEC1 (DEST ADDR FETCH)
            'd7: begin
                // on mem out will be the address of the destination
                inMDR = acc; // load the accumulator in the mdr
                // mdr could be set in EXEC0; that could give more possibilities; TODO: do that?
                ldMDR = 1'b1;
                inMAR = mem_in[ADDR_WIDTH-1:0];
                ldMAR = 1'b1;
                fsm_state_next = 'd11; // WRITE MEM
            end

            // SPIN
            'd10: begin
                // just spin in this state (stop the register)
                fsm_state_next = 'd10; // SPIN
            end

            // EXEC2 (WRITE MEM)
            'd11: begin
                // write on address put in last step
                mem_we = 1'b1;
                fsm_state_next = 'd1;
            `ifdef MODIF
                if(vector_op) begin
                    // vector operations need to do multiple writing
                    // so they are returning to EXEC0 if there is more to write
                    if(cnt != 0) 
                        fsm_state_next = 'd6;
                    else
                        fsm_state_next = 'd1;
                end
                else
                    fsm_state_next = 'd1;
            `endif
            end
        
        `ifdef MODIF
            // VECTOR STATE
            'd13: begin
                case(opCode)
                    // VECTOR_MOV_VS
                    4'b1001: begin
                        // setup for writing
                        inMDR = mem_in;
                        ldMDR = 1'b1;
                        inMAR = pointer1;
                        ldMAR = 1'b1;
                        incPOINTER1 = 1'b1; // increment dest pointer
                        fsm_state_next = 'd11; // EXEC2
                    end
                    // VECTOR_OUT_VS
                    4'b1010: begin
                        // just output read value
                        out_next = mem_in;
                        if(cnt != 0)
                            fsm_state_next = 'd6; // EXEC0
                        else 
                            fsm_state_next = 'd1; // IF0
                    end
                    default: fsm_state_next = 'd1; // IF0
                endcase
            end  
        `endif
        
            default: begin
                fsm_state_next = 'd0;
            end
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            fsm_state <= 0;
            currOp <= 0;
            out <= 0;
            `ifdef PHASE_3
                signal <= 1'b0;
            `endif
        end
        else begin
            `ifdef PHASE_3
                signal <= signal_next;
            `endif
            fsm_state <= fsm_state_next;
            out <= out_next;
            currOp <= currOp_next;
        end
    end

endmodule