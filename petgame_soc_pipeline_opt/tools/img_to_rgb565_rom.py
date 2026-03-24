#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert pet expression images to RGB565 ROM init.

Expected file naming (default):
  pet{P}_exp{E}.png  (e.g. pet0_exp0.png)
Also accepts:
  p{P}_e{E}.png

ROM order:
  index = (pet_id * exps_per_pet + exp_id) * (W*H) + pixel_index
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

PET_EXP_PATTERNS = [
    re.compile(r"pet(\d+)_exp(\d+)", re.IGNORECASE),
    re.compile(r"p(\d+)_e(\d+)", re.IGNORECASE),
]


def parse_pet_exp(filename: str):
    base = os.path.splitext(os.path.basename(filename))[0]
    for pat in PET_EXP_PATTERNS:
        m = pat.search(base)
        if m:
            return int(m.group(1)), int(m.group(2))
    return None, None


def rgb565(r, g, b):
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)


def load_image(path, size, resize):
    img = Image.open(path).convert("RGB")
    if img.size != size:
        if resize:
            img = img.resize(size, Image.NEAREST)
        else:
            raise ValueError(f"Image {path} size {img.size} != {size}")
    return img


def collect_images(input_dir):
    exts = (".png", ".bmp", ".jpg", ".jpeg")
    files = []
    for name in os.listdir(input_dir):
        if name.lower().endswith(exts):
            files.append(os.path.join(input_dir, name))
    return sorted(files)


def write_verilog(out_path, mem_name, values):
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("initial begin\n")
        for i, v in enumerate(values):
            f.write(f"    {mem_name}[{i}] = 16'h{v:04x};\n")
        f.write("end\n")


def write_mem(out_path, values):
    with open(out_path, "w", encoding="utf-8") as f:
        for v in values:
            f.write(f"{v:04x}\n")


def write_coe(out_path, values):
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        for i, v in enumerate(values):
            tail = ",\n" if i != len(values) - 1 else ";\n"
            f.write(f"{v:04x}{tail}")


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
    ap.add_argument("--resize", action="store_true", help="resize images to target size")
    args = ap.parse_args()

    input_dir = args.input
    size = (args.width, args.height)
    pixels_per_img = args.width * args.height

    files = collect_images(input_dir)
    if not files:
        print("ERROR: No images found.")
        sys.exit(1)

    total = args.pets * args.exps
    values = [0] * (total * pixels_per_img)

    seen = set()
    for path in files:
        pet_id, exp_id = parse_pet_exp(path)
        if pet_id is None:
            print(f"WARN: skip (name not match): {path}")
            continue
        if pet_id >= args.pets or exp_id >= args.exps:
            print(f"WARN: skip (out of range): {path}")
            continue

        img = load_image(path, size, args.resize)
        base = (pet_id * args.exps + exp_id) * pixels_per_img
        pix = img.load()

        for y in range(args.height):
            for x in range(args.width):
                r, g, b = pix[x, y]
                values[base + y * args.width + x] = rgb565(r, g, b)

        seen.add((pet_id, exp_id))

    missing = []
    for p in range(args.pets):
        for e in range(args.exps):
            if (p, e) not in seen:
                missing.append((p, e))

    if missing:
        print("WARN: missing images for:", missing)

    if args.format == "verilog":
        write_verilog(args.output, args.mem_name, values)
    elif args.format == "mem":
        write_mem(args.output, values)
    else:
        write_coe(args.output, values)

    print(f"Done. Wrote {len(values)} pixels to {args.output}")


if __name__ == "__main__":
    main()
