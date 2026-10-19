`timescale 1ns / 1ps
// Two flip flop synchronizer for slow inputs such as switches and buttons.
module sync2 #(
    parameter WIDTH = 1
) (
    input  wire             clk,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    reg [WIDTH-1:0] meta;
    always @(posedge clk) begin
        meta <= d;
        q    <= meta;
    end
endmodule
