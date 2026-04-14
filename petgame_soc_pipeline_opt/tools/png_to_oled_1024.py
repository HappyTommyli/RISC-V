#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert one PNG image to 32x32 (1024 pixels) monochrome data for SSD1306.

Default output is a flat 1024-pixel text file (0/1, one per line, row-major).
Optional verilog output format:
    rom[idx] = 16'hffff / 16'h0000
"""

import argparse
import sys

try:
    from PIL import Image
except Exception:
    print("ERROR: Pillow not installed. Run: pip install pillow")
    sys.exit(1)


def load_and_prepare(path: str, width: int, height: int, resize: bool):
    img = Image.open(path).convert("L")
    if img.size != (width, height):
        if resize:
            img = img.resize((width, height), Image.NEAREST)
        else:
            raise ValueError(
                f"Image size {img.size} != ({width}, {height}). Use --resize to force resize."
            )
    return img


def to_bits(img: Image.Image, threshold: int, invert: bool, on_color: str):
    w, h = img.size
    pix = img.load()
    out = []
    for y in range(h):
        for x in range(w):
            if on_color == "dark":
                # Dark pixels are ON, light pixels are OFF.
                bit = 1 if pix[x, y] < threshold else 0
            else:
                # Light pixels are ON, dark pixels are OFF.
                bit = 1 if pix[x, y] >= threshold else 0
            if invert:
                bit = 1 - bit
            out.append(bit)
    return out


def write_flat(out_path: str, bits):
    with open(out_path, "w", encoding="utf-8") as f:
        for b in bits:
            f.write(f"{b}\n")


def write_verilog(out_path: str, bits, mem_name: str, base: int):
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("initial begin\n")
        f.write("    integer i;\n")
        f.write(f"    for (i = 0; i < ROM_DEPTH; i = i + 1) {mem_name}[i] = 16'h0000;\n")
        f.write("\n")
        f.write(f"    // 32x32 image payload starts at {mem_name}[{base}]\n")
        for i, bit in enumerate(bits):
            if bit:
                f.write(f"    {mem_name}[{base + i}] = 16'hffff;\n")
        f.write("end\n")


def write_preview_console(bits, width: int, height: int):
    for y in range(height):
        row = bits[y * width : (y + 1) * width]
        print("".join("#" if b else "." for b in row))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="input .png image path")
    ap.add_argument("--output", required=True, help="output file path")
    ap.add_argument("--format", choices=["flat", "verilog"], default="flat")
    ap.add_argument("--width", type=int, default=32)
    ap.add_argument("--height", type=int, default=32)
    ap.add_argument("--threshold", type=int, default=128, help="0..255 grayscale threshold")
    ap.add_argument(
        "--on-color",
        choices=["dark", "light"],
        default="light",
        help="which grayscale side is treated as ON pixel (default: light)",
    )
    ap.add_argument("--invert", action="store_true", help="invert output bits")
    ap.add_argument("--resize", action="store_true", help="resize input image to target size")
    ap.add_argument("--mem-name", default="rom", help="verilog memory name (for --format verilog)")
    ap.add_argument("--base", type=int, default=0, help="verilog start index (for --format verilog)")
    ap.add_argument("--preview", action="store_true", help="print 32x32 ASCII preview")
    args = ap.parse_args()

    if args.threshold < 0 or args.threshold > 255:
        print("ERROR: --threshold must be in range 0..255")
        sys.exit(1)
    if args.width * args.height != 1024:
        print("ERROR: This tool targets 1024 pixels. Please use --width 32 --height 32.")
        sys.exit(1)

    img = load_and_prepare(args.input, args.width, args.height, args.resize)
    bits = to_bits(img, args.threshold, args.invert, args.on_color)

    if args.format == "flat":
        write_flat(args.output, bits)
    else:
        write_verilog(args.output, bits, args.mem_name, args.base)

    ones = sum(bits)
    zeros = len(bits) - ones
    print(f"Done. pixels={len(bits)} ones={ones} zeros={zeros} output={args.output}")
    if args.preview:
        write_preview_console(bits, args.width, args.height)


if __name__ == "__main__":
    main()
