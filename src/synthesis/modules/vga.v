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
    output              hsync,
    output              vsync,
    output     [3:0]    red,
    output     [3:0]    green,
    output     [3:0]    blue
);

reg [10:0] h_counter;
reg [9:0]  v_counter;
reg [23:0] tmp_code;

// counters state crossing points
localparam  V_VISIBLE_START  = 0, 
            V_VISIBLE_END    = 600,
            V_FP_END        = 637,
            V_PULSE_END     = 643,
            V_BP_END        = 666;

localparam  H_VISIBLE_START  = 0, 
            H_VISIBLE_HALF   = 401,
            H_VISIBLE_END    = 800, 
            H_FP_END        = 856,
            H_PULSE_END     = 976,
            H_BP_END        = 1040;


// vsync is down only during sync pulse
assign vsync = v_counter < V_FP_END || 
                v_counter >= V_PULSE_END; 

// hsync is down only during sync pulse
assign hsync = h_counter < H_FP_END || 
                h_counter >= H_PULSE_END;

// is tmp pixel in visible part of the grid
wire visible =  v_counter < V_VISIBLE_END &&
                h_counter < H_VISIBLE_END;

// color is black if outside of visible grid
// on half of visible grid color should switch
assign red   = visible ? 
                (h_counter < H_VISIBLE_HALF ? tmp_code[23:20] : tmp_code[11:8]) 
                : 4'h0;

assign green   = visible ? 
                (h_counter < H_VISIBLE_HALF ? tmp_code[19:16] : tmp_code[7:4]) 
                : 4'h0;

assign blue   = visible ? 
                (h_counter < H_VISIBLE_HALF ? tmp_code[15:12] : tmp_code[3:0]) 
                : 4'h0;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        h_counter <= 0;
        v_counter <= 0;  
        tmp_code  <= 0;
    end
    else begin
        if(v_counter == V_BP_END - 1) begin
            // on last line of the grid
            if(h_counter == H_BP_END - 1) begin
                // on last pixel and last line of the grid
                v_counter <= 0;
                h_counter <= 0;
                // read new colors code on the end of displaying
                tmp_code <= code;
            end
            else 
                h_counter <= h_counter + 1;
        end
        else begin
            if(h_counter == H_BP_END - 1) begin
                // on last pixel of line but not last line
                h_counter <= 0;
                v_counter <= v_counter + 1;
            end
            else 
                h_counter <= h_counter + 1;
        end
    end
end
    
endmodule
