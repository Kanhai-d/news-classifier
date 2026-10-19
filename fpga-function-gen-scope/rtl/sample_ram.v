`timescale 1ns / 1ps
// Simple dual port RAM: 1024 words of 8 bits.
// Two banks of 512 words. The capture FSM writes one bank
// while the VGA block reads the other bank.
module sample_ram (
    input  wire       clk,
    input  wire       we,
    input  wire [9:0] waddr,
    input  wire [7:0] wdata,
    input  wire [9:0] raddr,
    output reg  [7:0] rdata
);
    (* ram_style = "block" *) reg [7:0] mem [0:1023];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 8'd128;
    end

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
        rdata <= mem[raddr];
    end
endmodule
