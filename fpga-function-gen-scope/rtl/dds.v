`timescale 1ns / 1ps
// Function generator core (direct digital synthesis).
// A 32 bit phase counter grows by "ftw" on every sample_ce pulse.
// The top 8 bits of the counter make the wave.
//
//   wave 0 = sine, 1 = square, 2 = triangle, 3 = sawtooth
//   f_out  = ftw * f_sample / 2^32     (f_sample is 1 MHz in this project)
module dds (
    input  wire        clk,
    input  wire        rst,
    input  wire        sample_ce,   // one pulse per sample (1 MHz)
    input  wire [31:0] ftw,         // frequency tuning word
    input  wire [1:0]  wave,
    output reg  [7:0]  sample       // 8 bit output, 0 to 255
);
    reg  [31:0] phase;
    wire [7:0]  p = phase[31:24];
    wire [7:0]  sine_val;

    sine_rom u_sine (.addr(p), .data(sine_val));

    // Triangle goes up for the first half and down for the second half.
    wire [7:0] tri_val = p[7] ? ~{p[6:0], 1'b0} : {p[6:0], 1'b0};

    reg [7:0] wave_val;
    always @(*) begin
        case (wave)
            2'd0:    wave_val = sine_val;
            2'd1:    wave_val = p[7] ? 8'd255 : 8'd0;
            2'd2:    wave_val = tri_val;
            default: wave_val = p;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            phase  <= 32'd0;
            sample <= 8'd128;
        end else if (sample_ce) begin
            phase  <= phase + ftw;
            sample <= wave_val;
        end
    end
endmodule
