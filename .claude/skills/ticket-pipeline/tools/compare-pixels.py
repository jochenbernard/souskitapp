#!/usr/bin/env python3
"""Counts the pixels that differ between two screenshots.
Usage: compare-pixels.py <a.png> <b.png> [--crop x,y,w,h] [--control <a2.png>] [--scale 3]
  --crop     compare only that rectangle, in pixels (the status bar's clock and the home indicator vary)
  --control  a second screenshot of the same state on a's build: its difference from a is the noise the
             comparison cannot see below
  --scale    pixels per point, for the bands' position in points (default 3; an iPad has 2)
Prints the count, how many differ by more than 8 of 255 in a channel, and the bands of rows that differ.
Exit 0 when the two are identical, 1 when they differ, 2 when they cannot be compared.
"""
import argparse
import subprocess
import sys


def raw(path):
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=p=0",
         path], capture_output=True, text=True).stdout.strip().split(",")
    if len(probe) < 2:
        sys.exit(f"cannot read {path}")
    data = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                          capture_output=True).stdout
    return int(probe[0]), int(probe[1]), data


def compare(a, b, crop, scale):
    wa, ha, da = raw(a)
    wb, hb, db = raw(b)
    if (wa, ha) != (wb, hb):
        print(f"DIFFERENT SIZES {wa}x{ha} and {wb}x{hb}")
        return None
    x0, y0, w, h = crop or (0, 0, wa, ha)
    x1, y1 = min(wa, x0 + w), min(ha, y0 + h)
    count = big = worst = 0
    bands, band = [], None
    for y in range(y0, y1):
        ra, rb = da[(y * wa + x0) * 3:(y * wa + x1) * 3], db[(y * wa + x0) * 3:(y * wa + x1) * 3]
        if ra == rb:
            if band and y - band[1] > 4:
                bands.append(band)
                band = None
            continue
        xs = [x for x in range(x1 - x0) if ra[x * 3:x * 3 + 3] != rb[x * 3:x * 3 + 3]]
        count += len(xs)
        for x in xs:
            step = max(abs(ra[x * 3 + c] - rb[x * 3 + c]) for c in range(3))
            worst = max(worst, step)
            big += step > 8
        left, right = x0 + xs[0], x0 + xs[-1]
        band = [y, y, left, right] if band is None else [band[0], y, min(band[2], left), max(band[3], right)]
    if band:
        bands.append(band)
    print(f"{count} pixels differ of {(x1 - x0) * (y1 - y0)}"
          + (f" (largest step {worst}/255, {big} by more than 8/255)" if count else ""))
    for top, bottom, left, right in bands:
        print(f"  rows {top}..{bottom} cols {left}..{right} px"
              f" = y {top / scale:.0f}..{bottom / scale:.0f} x {left / scale:.0f}..{right / scale:.0f} pt")
    return count


def main():
    parser = argparse.ArgumentParser(usage=__doc__)
    parser.add_argument("a")
    parser.add_argument("b")
    parser.add_argument("--crop")
    parser.add_argument("--control")
    parser.add_argument("--scale", type=float, default=3.0)
    args = parser.parse_args()
    crop = tuple(int(v) for v in args.crop.split(",")) if args.crop else None
    if crop and len(crop) != 4:
        parser.error("--crop takes x,y,w,h")

    if args.control:
        print("control, the same build twice: ", end="")
        if compare(args.a, args.control, crop, args.scale) is None:
            return 2
        print("compared: ", end="")
    count = compare(args.a, args.b, crop, args.scale)
    if count is None:
        return 2
    return 1 if count else 0


if __name__ == "__main__":
    sys.exit(main())
