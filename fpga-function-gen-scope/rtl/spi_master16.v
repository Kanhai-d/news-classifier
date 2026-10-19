`timescale 1ns / 1ps
// Simple 16 bit SPI master, used for both Pmod DA2 (DAC) and Pmod AD1 (ADC).
//
// SCLK idles high and runs at clk / (2 * HALF): 12.5 MHz with HALF = 4.
// MOSI changes on the rising edge of SCLK, so the DAC can read it on the falling edge.
// MISO is read on every falling edge of SCLK, just before SCLK goes low.
// The ADC puts out one bit at CS low and then one bit after every falling edge.
//
// One frame takes 136 clock cycles (1.36 us).
module spi_master16 #(
    parameter HALF = 4
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,      // one clock pulse starts a frame
    input  wire [15:0] tx,         // word to send, MSB first
    output reg  [15:0] rx,         // word received, valid when done = 1
    output reg         done,       // one clock pulse at the end of a frame
    output reg         cs_n,
    output reg         sclk,
    output reg         mosi,
    input  wire        miso
);
    localparam [2:0] IDLE = 3'd0, LEAD = 3'd1, LOW = 3'd2, HIGH = 3'd3, LAST = 3'd4;

    reg [2:0]  state;
    reg [7:0]  cnt;
    reg [3:0]  bitn;
    reg [15:0] tx_sh;
    reg [15:0] rx_sh;

    wire half_done = (cnt == HALF - 1);

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            state <= IDLE;
            cs_n  <= 1'b1;
            sclk  <= 1'b1;
            mosi  <= 1'b0;
            cnt   <= 8'd0;
            bitn  <= 4'd0;
            rx    <= 16'd0;
        end else begin
            cnt <= half_done ? 8'd0 : cnt + 8'd1;
            case (state)
                IDLE: begin
                    cnt <= 8'd0;
                    if (start) begin
                        cs_n  <= 1'b0;
                        tx_sh <= tx;
                        mosi  <= tx[15];
                        bitn  <= 4'd0;
                        state <= LEAD;
                    end
                end
                LEAD: if (half_done) begin          // first falling edge
                    sclk  <= 1'b0;
                    rx_sh <= {rx_sh[14:0], miso};
                    state <= LOW;
                end
                LOW: if (half_done) begin           // rising edge: next bit out
                    sclk  <= 1'b1;
                    tx_sh <= {tx_sh[14:0], 1'b0};
                    mosi  <= tx_sh[14];
                    bitn  <= bitn + 4'd1;
                    state <= (bitn == 4'd15) ? LAST : HIGH;
                end
                HIGH: if (half_done) begin          // falling edge: read a bit
                    sclk  <= 1'b0;
                    rx_sh <= {rx_sh[14:0], miso};
                    state <= LOW;
                end
                LAST: if (half_done) begin          // end of frame
                    cs_n  <= 1'b1;
                    rx    <= rx_sh;
                    done  <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
