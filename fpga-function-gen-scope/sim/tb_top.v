// Full design test. Runs 3 frames, saves the last frame as a picture file
// and checks that the trace reaches every one of the 512 plot columns.
// The Pmod DA2 output is wired to the Pmod AD1 input through simple models,
// so with SW6 = 1 the whole loop DDS -> DAC -> ADC -> scope -> VGA is tested.
//
// Plusargs:  +SW=<hex switch value>   +OUT=<ppm file name>
`timescale 1ns/1ps
module tb_top;
    reg clk = 0;
    always #5 clk = ~clk;

    reg  [6:0] sw = 7'h14;          // sine, 1 kHz, 4 ms time scale, generator input
    reg        btnc = 1;
    wire [3:0] vga_r, vga_g, vga_b;
    wire       vga_hs, vga_vs;
    wire       da2_sync, da2_dina, da2_sclk;
    wire       ad1_cs, ad1_d0, ad1_sclk;

    top dut (.clk(clk), .sw(sw), .btnc(btnc),
             .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b), .vga_hs(vga_hs), .vga_vs(vga_vs),
             .da2_sync(da2_sync), .da2_dina(da2_dina), .da2_sclk(da2_sclk),
             .ad1_cs(ad1_cs), .ad1_d0(ad1_d0), .ad1_sclk(ad1_sclk));

    // Jumper wire from DA2 output A to AD1 input A
    wire [11:0] dac_value;
    wire [15:0] dac_word;
    wire [31:0] dac_frames;
    da2_model dac (.sync_n(da2_sync), .sclk(da2_sclk), .din(da2_dina), .value(dac_value),
                   .last_word(dac_word), .frames(dac_frames));
    ad1_model adc (.cs_n(ad1_cs), .sclk(ad1_sclk), .vin(dac_value), .dout(ad1_d0));

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
    integer t0, t1;

    task check_tick(input integer expected);
        begin
            @(posedge dut.sample_ce); t0 = $time;
            @(posedge dut.sample_ce); t1 = $time;
            $display("sample tick every %0d clocks (expected %0d)", (t1 - t0) / 10, expected);
            if ((t1 - t0) / 10 != expected) errors = errors + 1;
        end
    endtask
    integer x, y, f, hits, missing, total_green;
    reg [255:0] outname;
    integer swarg;

    initial begin
        if (!$value$plusargs("SW=%h", swarg)) swarg = 7'h14;
        sw = swarg[6:0];
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

        // check: sample tick every 200 clocks (500 kHz)
        check_tick(200);

        // check: the DAC got a frame for every sample
        $display("DAC frames=%0d", dac_frames);
        if (dac_frames < 20000) begin $display("FAIL: too few DAC frames"); errors = errors + 1; end

        if (errors == 0) $display("tb_top PASS"); else $display("tb_top FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
