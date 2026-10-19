// Checks the four waves at 1 kHz: value range and number of cycles in 20 ms.
`timescale 1ns/1ps
module tb_dds;
    reg clk = 0;
    always #5 clk = ~clk;                     // 100 MHz

    reg rst = 1;
    reg [6:0] div = 0;
    reg sample_ce = 0;
    always @(posedge clk) begin
        sample_ce <= (div == 7'd99);
        div <= (div == 7'd99) ? 7'd0 : div + 7'd1;
    end

    reg  [1:0] wave = 0;
    wire [7:0] sample;
    dds dut (.clk(clk), .rst(rst), .sample_ce(sample_ce),
             .ftw(32'd4294967), .wave(wave), .sample(sample));   // 1 kHz

    integer errors = 0;
    integer w, n;
    integer vmin, vmax, crossings;
    reg [7:0] last;

    task run_wave(input [1:0] sel);
        begin
            wave = sel;
            rst = 1; repeat (10) @(posedge clk); rst = 0;
            vmin = 255; vmax = 0; crossings = 0; last = 128;
            for (n = 0; n < 20000; n = n + 1) begin      // 20000 samples = 20 ms
                @(posedge sample_ce); #1;
                if (sample < vmin) vmin = sample;
                if (sample > vmax) vmax = sample;
                if (last < 128 && sample >= 128) crossings = crossings + 1;
                last = sample;
            end
            $display("wave %0d: min=%0d max=%0d rising crossings=%0d", sel, vmin, vmax, crossings);
            if (crossings < 19 || crossings > 21) begin
                $display("  FAIL: expected about 20 cycles"); errors = errors + 1;
            end
            case (sel)
                0: if (vmin > 2 || vmax < 254)   begin $display("  FAIL: sine range");     errors = errors + 1; end
                1: if (vmin != 0 || vmax != 255) begin $display("  FAIL: square range");   errors = errors + 1; end
                2: if (vmin > 4 || vmax < 250)   begin $display("  FAIL: triangle range"); errors = errors + 1; end
                3: if (vmin > 2 || vmax < 253)   begin $display("  FAIL: saw range");      errors = errors + 1; end
            endcase
        end
    endtask

    initial begin
        for (w = 0; w < 4; w = w + 1) run_wave(w[1:0]);
        if (errors == 0) $display("tb_dds PASS"); else $display("tb_dds FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
