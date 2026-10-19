// ZedBoard function generator and digital oscilloscope. Only the board is needed.
//
// Switches:
//   SW1 SW0  wave        00 sine, 01 square, 10 triangle, 11 sawtooth
//   SW4 SW3 SW2  frequency  000 100 Hz, 001 200 Hz, 010 500 Hz, 011 1 kHz,
//                           100 2 kHz, 101 5 kHz, 110 10 kHz, 111 20 kHz
//   SW6 SW5  time scale  00 fastest (512 us on screen), 01 2 ms, 10 8 ms, 11 33 ms
//   SW7      spare
// BTNC resets the design.
// LEDs show the 8 bit generator output.
module top (
    input  wire       clk,        // 100 MHz
    input  wire [7:0] sw,
    input  wire       btnc,
    output wire [7:0] led,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hs,
    output wire       vga_vs
);
    // Inputs
    wire [7:0] sw_s;
    wire       rst;
    sync2 #(.WIDTH(8)) u_sync_sw  (.clk(clk), .d(sw),   .q(sw_s));
    sync2 #(.WIDTH(1)) u_sync_rst (.clk(clk), .d(btnc), .q(rst));

    // Clock enables: 1 MHz sample rate and 25 MHz pixel rate
    reg [6:0] sample_div = 7'd0;
    reg       sample_ce  = 1'b0;
    reg [1:0] pix_div    = 2'd0;
    reg       pix_ce     = 1'b0;
    always @(posedge clk) begin
        if (sample_div == 7'd99) begin
            sample_div <= 7'd0;
            sample_ce  <= 1'b1;
        end else begin
            sample_div <= sample_div + 7'd1;
            sample_ce  <= 1'b0;
        end
        pix_div <= pix_div + 2'd1;
        pix_ce  <= (pix_div == 2'd3);
    end

    // Frequency table: ftw = f * 2^32 / 1 MHz
    reg [31:0] ftw;
    always @(*) begin
        case (sw_s[4:2])
            3'd0:    ftw = 32'd429497;      // 100 Hz
            3'd1:    ftw = 32'd858993;      // 200 Hz
            3'd2:    ftw = 32'd2147484;     // 500 Hz
            3'd3:    ftw = 32'd4294967;     // 1 kHz
            3'd4:    ftw = 32'd8589935;     // 2 kHz
            3'd5:    ftw = 32'd21474836;    // 5 kHz
            3'd6:    ftw = 32'd42949673;    // 10 kHz
            default: ftw = 32'd85899346;    // 20 kHz
        endcase
    end

    // Function generator
    wire [7:0] gen_sample;
    dds u_dds (
        .clk(clk), .rst(rst), .sample_ce(sample_ce),
        .ftw(ftw), .wave(sw_s[1:0]), .sample(gen_sample)
    );
    assign led = gen_sample;

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
        .sample(gen_sample), .timebase(sw_s[6:5]),
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
