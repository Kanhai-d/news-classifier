`timescale 1ns / 1ps
// Simple behavior models of the two Pmods, for simulation only.

// Pmod DA2 (DAC121S101): reads DIN on each falling SCLK edge while SYNC is low.
// After 16 bits the low 12 bits become the output value.
module da2_model (
    input  wire        sync_n,
    input  wire        sclk,
    input  wire        din,
    output reg  [11:0] value,
    output reg  [15:0] last_word,
    output reg  [31:0] frames
);
    reg [15:0] sh;
    integer    n;
    initial begin value = 12'd2048; frames = 0; n = 0; end
    always @(negedge sync_n) n = 0;
    always @(negedge sclk) if (!sync_n) begin
        sh = {sh[14:0], din};
        n  = n + 1;
        if (n == 16) begin
            last_word = sh;
            value     = sh[11:0];
            frames    = frames + 1;
        end
    end
endmodule

// Pmod AD1 (AD7476A): holds the input when CS goes low, then sends 4 zeros and
// 12 data bits, MSB first. The first bit comes out at CS low, the others after each
// falling SCLK edge (with a small delay, like the real chip).
module ad1_model (
    input  wire        cs_n,
    input  wire        sclk,
    input  wire [11:0] vin,
    output reg         dout
);
    reg [15:0] word;
    integer    idx;
    initial dout = 1'b0;
    always @(negedge cs_n) begin
        word = {4'b0000, vin};
        idx  = 15;
        dout <= #5 word[15];
    end
    always @(negedge sclk) if (!cs_n) begin
        idx = idx - 1;
        dout <= #5 (idx >= 0) ? word[idx] : 1'b0;
    end
endmodule
