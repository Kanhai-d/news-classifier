// VGA timing for 640 x 480 at 60 Hz.
// The 25 MHz pixel rate comes from a clock enable (pix_ce) on the 100 MHz clock.
// Sync pulses are active low. hsync and vsync are one pixel late
// compared with hcount and vcount, the same as the colour output.
module vga_timing (
    input  wire       clk,
    input  wire       rst,
    input  wire       pix_ce,
    output reg  [9:0] hcount,
    output reg  [9:0] vcount,
    output reg        hsync,
    output reg        vsync,
    output reg        frame_tick   // one clk pulse when the blank time starts
);
    localparam H_VISIBLE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;   // 800
    localparam V_VISIBLE = 480, V_FRONT = 10, V_SYNC = 2, V_BACK = 33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;   // 525

    wire h_last = (hcount == H_TOTAL - 1);
    wire v_last = (vcount == V_TOTAL - 1);

    always @(posedge clk) begin
        frame_tick <= 1'b0;
        if (rst) begin
            hcount   <= 10'd0;
            vcount   <= 10'd0;
            hsync    <= 1'b1;
            vsync    <= 1'b1;
        end else if (pix_ce) begin
            if (h_last) begin
                hcount <= 10'd0;
                vcount <= v_last ? 10'd0 : vcount + 10'd1;
                if (vcount == V_VISIBLE - 1)
                    frame_tick <= 1'b1;
            end else begin
                hcount <= hcount + 10'd1;
            end

            hsync    <= ~((hcount >= H_VISIBLE + H_FRONT) &&
                          (hcount <  H_VISIBLE + H_FRONT + H_SYNC));
            vsync    <= ~((vcount >= V_VISIBLE + V_FRONT) &&
                          (vcount <  V_VISIBLE + V_FRONT + V_SYNC));
        end
    end
endmodule
