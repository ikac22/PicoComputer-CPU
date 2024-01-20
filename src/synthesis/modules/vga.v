// VESA 800x600 72Hz
// pixel freq: 50MHz

// HORIZONTAL (pixels)
// visible: 800    
// front porch: 56  // R 0 G 0 B 0
// sync pulse: 120 // R 0 G 0 B 0
// back porch: 64   // R 0 G 0 B 0
//
// 1040 pixels

// VERTICAL (lines)
// visible: 600
// front porch: 37
// sync pulse: 6
// back porch: 23
//
// 666 lines 



module vga (
    input               clk,
    input               rst_n,
    input      [23:0]   code,
`ifndef VGA_NEXT
    output              hsync,
    output              vsync,
    output     [3:0]    red,
    output     [3:0]    green,
    output     [3:0]    blue
`else
    output reg             hsync,
    output reg             vsync,
    output reg    [3:0]    red,
    output reg    [3:0]    green,
    output reg    [3:0]    blue
`endif
);

reg [10:0] h_counter;
reg [9:0]  v_counter;
reg [23:0] tmp_code;

`ifdef VGA_NEXT
    reg [3:0]  red_next, green_next, blue_next;
    reg        vsync_next, hsync_next;
`endif

localparam  V_VISIBLE_START  = 0, 
            V_VISIBLE_END    = 600,
            V_FP_END        = 637,
            V_PULSE_END     = 643,
            V_BP_END        = 666;

localparam  H_VISIBLE_START  = 0, 
            H_VISIBLE_HALF   = 400,
            H_VISIBLE_END    = 800, 
            H_FP_END        = 856,
            H_PULSE_END     = 976,
            H_BP_END        = 1040;


// Da li se koristi NEXT logika ili assign?
`ifndef VGA_NEXT  
    assign vsync = v_counter < V_FP_END || 
                   v_counter >= V_PULSE_END;

    assign hsync = h_counter < H_FP_END || 
                   h_counter >= H_PULSE_END;

    wire visible =  v_counter < V_VISIBLE_END &&
                    h_counter < H_VISIBLE_END;

    assign red   = visible ? 
                   (h_counter < H_VISIBLE_HALF ? tmp_code[23:20] : tmp_code[11:8]) 
                   : 4'h0;

    assign green   = visible ? 
                   (h_counter < H_VISIBLE_HALF ? tmp_code[19:16] : tmp_code[7:4]) 
                   : 4'h0;

    assign blue   = visible ? 
                   (h_counter < H_VISIBLE_HALF ? tmp_code[15:12] : tmp_code[3:0]) 
                   : 4'h0;
`else

    reg visible;

    always @(*) begin
        visible =  v_counter < V_VISIBLE_END - 1 &&
                   h_counter < H_VISIBLE_END - 1;

        vsync_next = (v_counter < V_FP_END - 1) | (v_counter >= V_PULSE_END - 1);
        hsync_next = (h_counter < H_FP_END - 1) | (h_counter >= H_PULSE_END - 1);

        red_next   = visible ? 
                     (h_counter < H_VISIBLE_HALF - 1 ? tmp_code[23:20] : tmp_code[11:8]) 
                    : 4'h0;

        green_next = visible ? 
                    (h_counter < H_VISIBLE_HALF - 1 ? tmp_code[19:16] : tmp_code[7:4]) 
                    : 4'h0;

        blue_next  = visible ? 
                     (h_counter < H_VISIBLE_HALF - 1 ? tmp_code[15:12] : tmp_code[3:0]) 
                     : 4'h0; 
    end
`endif

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        h_counter <= 0;
        v_counter <= 0;  
        tmp_code  <= 0;
        `ifdef VGA_NEXT
            red       <= 0;
            green     <= 0;
            blue      <= 0;
            vsync     <= 1;
            hsync     <= 1;
        `endif
    end
    else begin
        `ifdef VGA_NEXT
            hsync <= hsync_next;
            vsync <= vsync_next;
            red   <= red_next;
            blue  <= blue_next;
            green <= green_next;
        `endif
        if(v_counter == V_BP_END - 1) begin
            if(h_counter == H_BP_END - 1) begin
                v_counter <= 0;
                h_counter <= 0;
                tmp_code <= code;
            end
            else 
                h_counter <= h_counter + 1;
        end
        else begin
            if(h_counter == H_BP_END - 1) begin
                h_counter <= 0;
                v_counter <= v_counter + 1;
            end
            else 
                h_counter <= h_counter + 1;
        end
    end
end
    
endmodule