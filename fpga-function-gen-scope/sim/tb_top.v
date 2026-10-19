// Full design test. Runs 3 frames, saves the last frame as a picture file
// and checks that the trace reaches every one of the 512 plot columns.
//
// Plusargs:  +SW=<hex switch value>   +OUT=<ppm file name>
`timescale 1ns/1ps
module tb_top;
    reg clk = 0;
    always #5 clk = ~clk;

    reg  [7:0] sw = 8'h2C;          // sine, 1 kHz, time scale 1
    reg        btnc = 1;
    wire [7:0] led;
    wire [3:0] vga_r, vga_g, vga_b;
    wire       vga_hs, vga_vs;

    top dut (.clk(clk), .sw(sw), .btnc(btnc), .led(led),
             .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b), .vga_hs(vga_hs), .vga_vs(vga_vs));

    reg [11:0] frame [0:307199];
    integer    px = 0, py = 0;
    reg        started = 0;

    // The colour that is visible now belongs to the pixel seen at the last pix_ce.
    always @(posedge clk) begin
        if (dut.pix_ce) begin
            if (started && px < 640 && py < 480)
                frame[py * 640 + px] = {vga_r, vga_g, vga_b};
            px      = dut.hcount;
            py      = dut.vcount;
            started = 1;
        end
    end

    integer errors = 0;
    integer x, y, f, hits, missing, total_green;
    reg [255:0] outname;
    integer swarg;

    initial begin
        if (!$value$plusargs("SW=%h", swarg)) swarg = 8'h2C;
        sw = swarg[7:0];
        if (!$value$plusargs("OUT=%s", outname)) outname = "frame.ppm";

        repeat (20) @(posedge clk);
        btnc = 0;
        #(3 * 16_800_000 + 2_000_000);

        // check: every plot column has green pixels
        missing = 0; total_green = 0;
        for (x = 64; x < 576; x = x + 1) begin
            hits = 0;
            for (y = 112; y < 368; y = y + 1)
                if (frame[y * 640 + x] == 12'h0F0) hits = hits + 1;
            total_green = total_green + hits;
            if (hits == 0) missing = missing + 1;
        end
        $display("sw=%h  green pixels=%0d  columns without trace=%0d", sw, total_green, missing);
        if (missing != 0) begin $display("FAIL: trace has gaps"); errors = errors + 1; end

        // check: nothing is drawn outside the plot area
        for (y = 0; y < 480; y = y + 1)
            for (x = 0; x < 640; x = x + 1)
                if ((x < 64 || x >= 576 || y < 112 || y >= 368) && frame[y * 640 + x] != 12'h000) begin
                    if (errors < 5) $display("FAIL: pixel outside plot at %0d,%0d", x, y);
                    errors = errors + 1;
                end

        // save the picture
        f = $fopen(outname, "w");
        $fwrite(f, "P3\n640 480\n15\n");
        for (y = 0; y < 480; y = y + 1)
            for (x = 0; x < 640; x = x + 1)
                $fwrite(f, "%0d %0d %0d\n", frame[y*640+x][11:8], frame[y*640+x][7:4], frame[y*640+x][3:0]);
        $fclose(f);

        if (errors == 0) $display("tb_top PASS"); else $display("tb_top FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
