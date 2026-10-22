#!/usr/bin/env python3
"""Turns the .ppm pictures from the simulation into .png files (no extra packages needed).

Usage: python3 scripts/ppm_to_png.py build/sim/frame_sine.ppm [more.ppm ...]
"""
import sys, zlib, struct

def convert(path):
    tok = open(path).read().split()
    assert tok[0] == "P3"
    w, h, maxv = int(tok[1]), int(tok[2]), int(tok[3])
    vals = [int(t) * 255 // maxv for t in tok[4:]]
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw.extend(vals[y * w * 3:(y + 1) * w * 3])
    def chunk(kind, data):
        c = struct.pack(">I", len(data)) + kind + data
        return c + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) \
          + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    out = path.rsplit(".", 1)[0] + ".png"
    open(out, "wb").write(png)
    print("wrote", out)

for p in sys.argv[1:]:
    convert(p)
