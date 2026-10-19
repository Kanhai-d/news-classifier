`timescale 1ns / 1ps
// ZedBoard function generator and digital oscilloscope.
//
// Function generator: DDS core, then Pmod DA2 (DAC) on port JA, analog output.
// Oscilloscope:       Pmod AD1 (ADC) on port JB, or the generator itself, then the
//                     capture FSM, the sample RAM and the VGA screen.
// Connect the DA2 output to the AD1 input with a jumper wire to see the real analog wave.
//
// Switches:
//   SW1 SW0  wave         00 sine, 01 square, 10 triangle, 11 sawtooth
//   SW3 SW2  frequency    00 100 Hz, 01 1 kHz, 10 5 kHz, 11 20 kHz
//   SW5 SW4  time scale   00 1 ms on screen, 01 4 ms, 10 16 ms, 11 65 ms
//   SW6      scope input  0 = generator (inside the FPGA), 1 = Pmod AD1
// BTNC resets the design.
module top (
    input  wire       clk,        // 100 MHz
    input  wire [6:0] sw,
    input  wire       btnc,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hs,
    output wire       vga_vs,
    // Pmod DA2 on JA (pins 1 to 4)
    output wire       da2_sync,
    output wire       da2_dina,
    output wire       da2_sclk,
    // Pmod AD1 on JB (pins 1, 2 and 4)
    output wire       ad1_cs,
    input  wire       ad1_d0,
    output wire       ad1_sclk
);
    // Inputs
    wire [6:0] sw_s;
    wire       rst;
    sync2 #(.WIDTH(7)) u_sync_sw  (.clk(clk), .d(sw),   .q(sw_s));
    sync2 #(.WIDTH(1)) u_sync_rst (.clk(clk), .d(btnc), .q(rst));

    // Clock enables: 500 kHz sample rate and 25 MHz pixel rate
    reg [7:0] sample_div  = 8'd0;
    reg       sample_ce   = 1'b0;
    reg       sample_ce_d = 1'b0;
    reg [1:0] pix_div     = 2'd0;
    reg       pix_ce      = 1'b0;
    always @(posedge clk) begin
        if (sample_div == 8'd199) begin
            sample_div <= 8'd0;
            sample_ce  <= 1'b1;
        end else begin
            sample_div <= sample_div + 8'd1;
            sample_ce  <= 1'b0;
        end
        sample_ce_d <= sample_ce;
        pix_div     <= pix_div + 2'd1;
        pix_ce      <= (pix_div == 2'd3);
    end

    // Frequency table: ftw = f * 2^32 / 500 kHz
    reg [31:0] ftw;
    always @(*) begin
        case (sw_s[3:2])
            2'd0:    ftw = 32'd858993;      // 100 Hz
            2'd1:    ftw = 32'd8589935;     // 1 kHz
            2'd2:    ftw = 32'd42949673;    // 5 kHz
            default: ftw = 32'd171798692;   // 20 kHz
        endcase
    end

    // Function generator
    wire [7:0] gen_sample;
    dds u_dds (
        .clk(clk), .rst(rst), .sample_ce(sample_ce),
        .ftw(ftw), .wave(sw_s[1:0]), .sample(gen_sample)
    );

    // Pmod DA2: one 16 bit frame per sample. Frame = 2 unused bits, 2 power down bits
    // (00 = normal) and 12 data bits. The 8 bit sample is stretched to 12 bits.
    spi_master16 u_da2 (
        .clk(clk), .rst(rst), .start(sample_ce_d),
        .tx({4'b0000, gen_sample, gen_sample[7:4]}), .rx(), .done(),
        .cs_n(da2_sync), .sclk(da2_sclk), .mosi(da2_dina), .miso(1'b0)
    );

    // Pmod AD1: one 16 bit frame per sample. Frame = 4 zeros and 12 data bits.
    wire [15:0] ad1_word;
    wire        ad1_done;
    reg  [7:0]  adc_sample = 8'd0;
    spi_master16 u_ad1 (
        .clk(clk), .rst(rst), .start(sample_ce_d),
        .tx(16'd0), .rx(ad1_word), .done(ad1_done),
        .cs_n(ad1_cs), .sclk(ad1_sclk), .mosi(), .miso(ad1_d0)
    );
    always @(posedge clk)
        if (ad1_done) adc_sample <= ad1_word[11:4];     // keep the top 8 of 12 bits

    // Scope input select
    wire [7:0] scope_in = sw_s[6] ? adc_sample : gen_sample;

    // VGA timing
    wire [9:0] hcount, vcount;
    wire       frame_tick;
    vga_timing u_timing (
        .clk(clk), .rst(rst), .pix_ce(pix_ce),
        .hcount(hcount), .vcount(vcount),
        .hsync(vga_hs), .vsync(vga_vs),
        .frame_tick(frame_tick)
    );

    // Oscilloscope capture
    wire       we;
    wire [9:0] waddr;
    wire [7:0] wdata;
    wire       disp_bank;
    scope_capture u_capture (
        .clk(clk), .rst(rst), .sample_ce(sample_ce),
        .sample(scope_in), .timebase(sw_s[5:4]),
        .frame_tick(frame_tick),
        .we(we), .waddr(waddr), .wdata(wdata),
        .disp_bank(disp_bank)
    );

    // Sample RAM
    wire [9:0] rd_addr;
    wire [7:0] rd_data;
    sample_ram u_ram (
        .clk(clk), .we(we), .waddr(waddr), .wdata(wdata),
        .raddr(rd_addr), .rdata(rd_data)
    );

    // Screen
    vga_display u_display (
        .clk(clk), .pix_ce(pix_ce),
        .hcount(hcount), .vcount(vcount),
        .disp_bank(disp_bank), .rd_addr(rd_addr), .rd_data(rd_data),
        .red(vga_r), .green(vga_g), .blue(vga_b)
    );

endmodule
