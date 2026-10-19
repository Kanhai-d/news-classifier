#!/usr/bin/env python3
"""Makes rtl/sine_rom.v, a 256 entry, 8 bit sine table written as a case statement.

Run it from the project folder:  python3 scripts/gen_sine_rom.py
The table is centered on 128 and swings from 1 to 255.
"""
import math

lines = []
lines.append("// Made by scripts/gen_sine_rom.py. Do not edit by hand.")
lines.append("module sine_rom (")
lines.append("    input  wire [7:0] addr,")
lines.append("    output reg  [7:0] data")
lines.append(");")
lines.append("    always @(*) begin")
lines.append("        case (addr)")
for i in range(256):
    v = round(128 + 127 * math.sin(2 * math.pi * i / 256))
    lines.append("            8'd%d: data = 8'd%d;" % (i, v))
lines.append("            default: data = 8'd128;")
lines.append("        endcase")
lines.append("    end")
lines.append("endmodule")

with open("rtl/sine_rom.v", "w") as f:
    f.write("\n".join(lines) + "\n")

# Frequency tuning words for a 1 MHz sample rate: ftw = f * 2^32 / 1e6
print("Frequency tuning words (1 MHz sample rate):")
for f in (100, 200, 500, 1000, 2000, 5000, 10000, 20000):
    print("  %6d Hz -> %d" % (f, round(f * 2**32 / 1e6)))
