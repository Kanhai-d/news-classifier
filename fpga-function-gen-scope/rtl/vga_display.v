`timescale 1ns / 1ps
// Draws the grid and the trace.
//
// Plot area: 512 x 256 pixels, top left corner at (64, 112).
// One screen column shows one saved sample. A sample value of 255 is the top.
//
// The RAM read has one clock of delay. A pixel lasts 4 clocks, so the RAM data
// is always ready when pix_ce comes.
module vga_display (
    input  wire       clk,
    input  wire       pix_ce,
    input  wire [9:0] hcount,
    input  wire [9:0] vcount,
    input  wire       disp_bank,
    output wire [9:0] rd_addr,
    input  wire [7:0] rd_data,
    output reg  [3:0] red,
    output reg  [3:0] green,
    output reg  [3:0] blue
);
    localparam X0 = 64,  W = 512;
    localparam Y0 = 112, H = 256;

    wire       visible = (hcount < 640) && (vcount < 480);
    wire [9:0] col    = hcount - X0;          // 0 to 511 inside the plot
    wire [9:0] row    = vcount - Y0;          // 0 to 255 inside the plot
    wire       in_plot = (hcount >= X0) && (hcount < X0 + W) &&
                         (vcount >= Y0) && (vcount < Y0 + H);

    assign rd_addr = {disp_bank, col[8:0]};

    // Keep the sample of the last column so vertical gaps can be filled.
    reg [7:0] prev;
    always @(posedge clk)
        if (pix_ce) prev <= rd_data;

    wire [7:0] cur  = rd_data;
    wire [7:0] last = (col == 10'd0) ? rd_data : prev;
    wire [7:0] lo   = (cur < last) ? cur : last;
    wire [7:0] hi   = (cur < last) ? last : cur;

    // Row value: 255 at the top of the plot, 0 at the bottom.
    wire [7:0] v = ~row[7:0];

    wire trace   = in_plot && (v >= lo) && (v <= hi + 9'd1);
    wire border  = in_plot && ((col == 10'd0) || (col == W - 1) ||
                               (row == 10'd0) || (row == H - 1));
    wire grid    = in_plot && ((col[5:0] == 6'd0) || (row[4:0] == 5'd0));
    wire centre  = in_plot && (row == 10'd128);

    always @(posedge clk) begin
        if (pix_ce) begin
            if (!visible) begin
                {red, green, blue} <= 12'h000;
            end else if (trace) begin
                {red, green, blue} <= 12'h0F0;      // green trace
            end else if (border || centre) begin
                {red, green, blue} <= 12'h888;      // grey frame and middle line
            end else if (grid) begin
                {red, green, blue} <= 12'h333;      // dark grey grid
            end else begin
                {red, green, blue} <= 12'h000;
            end
        end
    end
endmodule
