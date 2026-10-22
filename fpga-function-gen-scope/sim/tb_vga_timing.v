// Checks the VGA timing: 800 x 525 pixels per frame, sync widths, frame_tick spacing.
`timescale 1ns/1ps
module tb_vga_timing;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1;
    reg [1:0] pdiv = 0;
    reg pix_ce = 0;
    always @(posedge clk) begin
        pdiv   <= pdiv + 2'd1;
        pix_ce <= (pdiv == 2'd3);
    end

    wire [9:0] hcount, vcount;
    wire hsync, vsync, frame_tick;
    vga_timing dut (.clk(clk), .rst(rst), .pix_ce(pix_ce), .hcount(hcount), .vcount(vcount),
                    .hsync(hsync), .vsync(vsync), .frame_tick(frame_tick));

    integer errors = 0;
    integer clks = 0;
    integer h_fall_prev = -1, v_fall_prev = -1, h_rise = 0, v_rise = 0, tick_prev = -1;
    integer h_checked = 0, v_checked = 0, t_checked = 0;
    reg hs_d = 1, vs_d = 1;

    always @(posedge clk) begin
        clks <= clks + 1;
        hs_d <= hsync; vs_d <= vsync;
        if (hs_d && !hsync) begin
            if (h_fall_prev >= 0) begin
                if (clks - h_fall_prev !== 3200) begin $display("FAIL line length %0d clks", clks - h_fall_prev); errors = errors + 1; end
                h_checked = h_checked + 1;
            end
            h_fall_prev = clks;
        end
        if (!hs_d && hsync && h_fall_prev >= 0 && (clks - h_fall_prev) !== 384) begin
            $display("FAIL hsync width %0d clks", clks - h_fall_prev); errors = errors + 1;
        end
        if (vs_d && !vsync) begin
            if (v_fall_prev >= 0) begin
                if (clks - v_fall_prev !== 1680000) begin $display("FAIL frame length %0d clks", clks - v_fall_prev); errors = errors + 1; end
                v_checked = v_checked + 1;
            end
            v_fall_prev = clks;
        end
        if (!vs_d && vsync && v_fall_prev >= 0 && (clks - v_fall_prev) !== 6400) begin
            $display("FAIL vsync width %0d clks", clks - v_fall_prev); errors = errors + 1;
        end
        if (frame_tick) begin
            if (tick_prev >= 0) begin
                if (clks - tick_prev !== 1680000) begin $display("FAIL frame_tick spacing %0d", clks - tick_prev); errors = errors + 1; end
                t_checked = t_checked + 1;
            end
            tick_prev = clks;
        end
    end

    initial begin
        repeat (5) @(posedge clk);
        rst = 0;
        #(3 * 16_800_000 + 1_000_000);                 // a bit over 3 frames
        $display("checked %0d lines, %0d frames, %0d frame ticks", h_checked, v_checked, t_checked);
        if (h_checked < 1000 || v_checked < 2 || t_checked < 2) begin $display("FAIL: not enough checks"); errors = errors + 1; end
        if (errors == 0) $display("tb_vga_timing PASS"); else $display("tb_vga_timing FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
