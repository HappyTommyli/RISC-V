#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert PNG images to 1-bit ROM initialization data.

Expected filename patterns:
  pet{P}_exp{E}_f{F}.png
  pet{P}_exp{E}.png                (frame defaults to 0)
  p{P}_e{E}_f{F}.png

ROM order:
  index = (((pet_id * exps) + exp_id) * frames + frame_id) * (W*H) + pixel_index
  pixel_index is row-major: y*W + x
"""

import argparse
import os
import re
import sys

try:
    from PIL import Image
except Exception:
    print("ERROR: Pillow not installed. Run: pip install pillow")
    sys.exit(1)

NAME_PATTERNS = [
    re.compile(r"pet(\d+)_exp(\d+)_f(?:rame)?(\d+)", re.IGNORECASE),
    re.compile(r"p(\d+)_e(\d+)_f(?:rame)?(\d+)", re.IGNORECASE),
    re.compile(r"pet(\d+)_exp(\d+)", re.IGNORECASE),
    re.compile(r"p(\d+)_e(\d+)", re.IGNORECASE),
]


def parse_ids(filename: str):
    base = os.path.splitext(os.path.basename(filename))[0]
    for pat in NAME_PATTERNS:
        m = pat.search(base)
        if not m:
            continue
        if len(m.groups()) == 3:
            return int(m.group(1)), int(m.group(2)), int(m.group(3))
        return int(m.group(1)), int(m.group(2)), 0
    return None, None, None


def collect_images(input_dir: str):
    exts = (".png", ".bmp", ".jpg", ".jpeg")
    files = []
    for name in os.listdir(input_dir):
        if name.lower().endswith(exts):
            files.append(os.path.join(input_dir, name))
    return sorted(files)


def load_image(path: str, size, resize: bool):
    img = Image.open(path).convert("L")
    if img.size != size:
        if resize:
            img = img.resize(size, Image.NEAREST)
        else:
            raise ValueError(f"Image {path} size {img.size} != {size}")
    return img


def threshold_to_bit(gray: int, threshold: int, invert: bool):
    bit = 1 if gray >= threshold else 0
    return 1 - bit if invert else bit


def write_verilog_bits(out_path: str, mem_name: str, values):
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("initial begin\n")
        for i, v in enumerate(values):
            f.write(f"    {mem_name}[{i}] = 1'b{v};\n")
        f.write("end\n")


def write_mem_bits(out_path: str, values):
    with open(out_path, "w", encoding="utf-8") as f:
        for v in values:
            f.write(f"{v}\n")


def write_coe_bits(out_path: str, values):
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("memory_initialization_radix=2;\n")
        f.write("memory_initialization_vector=\n")
        for i, v in enumerate(values):
            tail = ",\n" if i != len(values) - 1 else ";\n"
            f.write(f"{v}{tail}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="input image folder")
    ap.add_argument("--output", required=True, help="output file path")
    ap.add_argument("--format", choices=["verilog", "mem", "coe"], default="verilog")
    ap.add_argument("--mem-name", default="rom", help="memory array name for verilog")
    ap.add_argument("--width", type=int, default=32)
    ap.add_argument("--height", type=int, default=32)
    ap.add_argument("--pets", type=int, required=True, help="number of pets")
    ap.add_argument("--exps", type=int, required=True, help="expressions per pet")
    ap.add_argument("--frames", type=int, default=1, help="frames per expression")
    ap.add_argument("--threshold", type=int, default=128, help="0..255 grayscale threshold")
    ap.add_argument("--invert", action="store_true", help="invert output bits")
    ap.add_argument("--resize", action="store_true", help="resize images to target size")
    args = ap.parse_args()

    if args.threshold < 0 or args.threshold > 255:
        print("ERROR: --threshold must be in range 0..255")
        sys.exit(1)
    if args.frames <= 0:
        print("ERROR: --frames must be >= 1")
        sys.exit(1)

    input_dir = args.input
    size = (args.width, args.height)
    pixels_per_img = args.width * args.height
    total_slots = args.pets * args.exps * args.frames
    values = [0] * (total_slots * pixels_per_img)

    files = collect_images(input_dir)
    if not files:
        print("ERROR: No images found.")
        sys.exit(1)

    seen = set()
    for path in files:
        pet_id, exp_id, frame_id = parse_ids(path)
        if pet_id is None:
            print(f"WARN: skip (name not match): {path}")
            continue
        if pet_id >= args.pets or exp_id >= args.exps or frame_id >= args.frames:
            print(f"WARN: skip (out of range): {path}")
            continue

        img = load_image(path, size, args.resize)
        base = (((pet_id * args.exps) + exp_id) * args.frames + frame_id) * pixels_per_img
        pix = img.load()

        for y in range(args.height):
            for x in range(args.width):
                bit = threshold_to_bit(pix[x, y], args.threshold, args.invert)
                values[base + y * args.width + x] = bit

        seen.add((pet_id, exp_id, frame_id))

    missing = []
    for p in range(args.pets):
        for e in range(args.exps):
            for fr in range(args.frames):
                if (p, e, fr) not in seen:
                    missing.append((p, e, fr))
    if missing:
        print(f"WARN: missing images count = {len(missing)}")
        print(f"WARN: first 20 missing = {missing[:20]}")

    if args.format == "verilog":
        write_verilog_bits(args.output, args.mem_name, values)
    elif args.format == "mem":
        write_mem_bits(args.output, values)
    else:
        write_coe_bits(args.output, values)

    print(f"Done. Wrote {len(values)} bits to {args.output}")


if __name__ == "__main__":
    main()
