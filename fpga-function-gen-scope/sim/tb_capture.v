// Checks the capture FSM with a counting ramp as input.
//  1. every sample is saved, starting at the level crossing
//  2. time scale 1 skips 3 samples between saved samples
//  3. the banks swap on frame_tick
//  4. the time out starts a capture when the input never crosses the level
`timescale 1ns/1ps
module tb_capture;
    reg clk = 0;
    always #5 clk = ~clk;

    reg rst = 1;
    reg [6:0] div = 0;
    reg sample_ce = 0;
    always @(posedge clk) begin
        sample_ce <= (div == 7'd99);
        div <= (div == 7'd99) ? 7'd0 : div + 7'd1;
    end

    reg  [7:0] sample = 8'd0;
    reg        hold   = 0;               // 1 keeps the input constant
    always @(posedge clk)
        if (sample_ce && !hold) sample <= sample + 8'd1;

    reg  [1:0] timebase = 0;
    reg        frame_tick = 0;
    wire       we;
    wire [9:0] waddr;
    wire [7:0] wdata;
    wire       disp_bank;

    scope_capture dut (.clk(clk), .rst(rst), .sample_ce(sample_ce), .sample(sample),
                       .timebase(timebase), .frame_tick(frame_tick),
                       .we(we), .waddr(waddr), .wdata(wdata), .disp_bank(disp_bank));

    wire [7:0] unused_rdata;
    sample_ram ram (.clk(clk), .we(we), .waddr(waddr), .wdata(wdata),
                    .raddr(10'd0), .rdata(unused_rdata));

    integer errors = 0;
    integer i;

    task pulse_frame;
        begin
            @(posedge clk); frame_tick <= 1; @(posedge clk); frame_tick <= 0;
        end
    endtask

    initial begin
        repeat (5) @(posedge clk);
        rst = 0;

        // 1. time scale 0, ramp up 1 per sample
        wait (dut.state == 2'd2);
        for (i = 0; i < 512; i = i + 1)
            if (ram.mem[i] !== ((128 + i) & 255)) begin
                if (errors < 5) $display("  FAIL bank0[%0d] = %0d, expected %0d", i, ram.mem[i], (128 + i) & 255);
                errors = errors + 1;
            end
        $display("test 1: capture of 512 samples checked");

        // 3. bank swap
        if (disp_bank !== 1'b1) begin $display("  FAIL: disp_bank should be 1 before the swap"); errors = errors + 1; end
        pulse_frame;
        @(posedge clk); @(posedge clk);
        if (disp_bank !== 1'b0 || dut.state !== 2'd0) begin
            $display("  FAIL: bank swap, disp_bank=%0d state=%0d", disp_bank, dut.state); errors = errors + 1;
        end
        $display("test 3: bank swap checked");

        // 2. time scale 1, every 4th sample
        timebase = 2'd1;
        wait (dut.state == 2'd2);
        for (i = 0; i < 511; i = i + 1)
            if (((ram.mem[512 + i + 1] - ram.mem[512 + i]) & 255) !== 4) begin
                if (errors < 5) $display("  FAIL bank1 step at %0d", i);
                errors = errors + 1;
            end
        $display("test 2: time scale step checked");
        pulse_frame;
        @(posedge clk); @(posedge clk);

        // 4. time out: input stays at 10 and never crosses 128
        hold = 1; @(posedge clk); sample = 8'd10; timebase = 2'd0;
        wait (dut.state == 2'd1);
        wait (dut.state == 2'd2);
        if (ram.mem[0] !== 8'd10) begin $display("  FAIL: time out capture, mem[0]=%0d", ram.mem[0]); errors = errors + 1; end
        $display("test 4: time out checked");

        if (errors == 0) $display("tb_capture PASS"); else $display("tb_capture FAIL (%0d errors)", errors);
        $finish;
    end

    initial begin
        #100_000_000;                       // 100 ms limit
        $display("tb_capture FAIL: time limit"); $finish;
    end
endmodule
