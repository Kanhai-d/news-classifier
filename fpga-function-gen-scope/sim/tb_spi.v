`timescale 1ns / 1ps
// Checks the SPI master: 16 clock edges, correct bits out to a DAC model,
// correct bits in from an ADC model, and SCLK at 12.5 MHz.
module tb_spi;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, start = 0;
    reg [15:0] tx = 16'hA5C3;
    wire [15:0] rx;
    wire done, cs_n, sclk, mosi, miso;

    spi_master16 dut (.clk(clk), .rst(rst), .start(start), .tx(tx), .rx(rx), .done(done),
                      .cs_n(cs_n), .sclk(sclk), .mosi(mosi), .miso(miso));

    wire [11:0] dac_value;
    wire [15:0] dac_word;
    wire [31:0] dac_frames;
    da2_model dac (.sync_n(cs_n), .sclk(sclk), .din(mosi), .value(dac_value),
                   .last_word(dac_word), .frames(dac_frames));
    ad1_model adc (.cs_n(cs_n), .sclk(sclk), .vin(12'hABC), .dout(miso));

    integer errors = 0, falls = 0, t_fall = 0, period = 0;
    always @(negedge sclk) if (!cs_n) begin
        if (falls > 0) period = $time - t_fall;
        t_fall = $time;
        falls = falls + 1;
    end

    task one_frame(input [15:0] word);
        begin
            tx = word; falls = 0;
            @(posedge clk); start <= 1; @(posedge clk); start <= 0;
            @(posedge done); @(posedge clk);
            $display("sent %h, DAC got %h | ADC sent %h, got %h | falling edges %0d | SCLK period %0d ns",
                     word, dac_word, 16'h0ABC, rx, falls, period);
            if (dac_word !== word)   begin $display("  FAIL: DAC word"); errors = errors + 1; end
            if (rx !== 16'h0ABC)     begin $display("  FAIL: ADC word"); errors = errors + 1; end
            if (falls != 16)         begin $display("  FAIL: edge count"); errors = errors + 1; end
            if (period != 80)        begin $display("  FAIL: SCLK period"); errors = errors + 1; end
            if (cs_n !== 1'b1)       begin $display("  FAIL: CS still low"); errors = errors + 1; end
        end
    endtask

    initial begin
        repeat (5) @(posedge clk); rst = 0;
        one_frame(16'hA5C3);
        one_frame(16'h0FFF);
        one_frame(16'h0001);
        if (errors == 0) $display("tb_spi PASS"); else $display("tb_spi FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
