"""Draws the Claude Code banner mascot as a PNG: argv[1] is the output,
argv[2] the body colour as hex, orange by default."""
import struct
import sys
import zlib

ART = [" ▐▛███▜▌ ",
       "▝▜█████▛▘",
       "  ▘▘ ▝▝  "]
# Upper left, upper right, lower left, lower right
QUADRANTS = {"█": "1111", "▛": "1110", "▜": "1101", "▐": "0101", "▌": "1010",
             "▝": "0100", "▘": "1000", " ": "0000"}
BODY = tuple(bytes.fromhex(sys.argv[2] if len(sys.argv) > 2 else "d77757"))
BLACK, PAPER = (0, 0, 0), (250, 249, 245)
SIZE, UNIT = 512, 24

pixels = [[PAPER] * SIZE for _ in range(SIZE)]
left = (SIZE - len(ART[0]) * 2 * UNIT) // 2
top = (SIZE - len(ART) * 4 * UNIT) // 2
for row, line in enumerate(ART):
    for col, char in enumerate(line):
        # The face is drawn on black, which shows through as the eyes
        face = row < 2 and 2 <= col <= 6
        for quadrant, lit in enumerate(QUADRANTS[char]):
            if lit == "0" and not face:
                continue
            x = left + (col * 2 + quadrant % 2) * UNIT
            y = top + (row * 2 + quadrant // 2) * 2 * UNIT
            for py in range(y, y + 2 * UNIT):
                pixels[py][x:x + UNIT] = [
                    BODY if lit == "1" else BLACK] * UNIT


def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(
        ">I", zlib.crc32(body))


raw = b"".join(b"\0" + bytes(c for px in line for c in px) for line in pixels)
with open(sys.argv[1], "wb") as f:
    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
