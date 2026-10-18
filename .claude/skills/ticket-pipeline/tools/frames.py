#!/usr/bin/env python3
"""Prints or compares the frames of the labelled elements in `axe describe-ui` dumps.
Usage: frames.py <dump.json|->                       every labelled element, button and field
       frames.py <dump> --filter <text>              only the lines holding the text
       frames.py <dump> --sheet                      only the open sheet, with what passes its edges
       frames.py <dump> --window                     the window's width and height
       frames.py <dump> --center <value> [--key AXLabel|AXUniqueId|type] [--index n]
                                                     the centre of an element as "x y"; ^ starts a prefix
       frames.py <before.json> <after.json> [--sheet] [--tolerance pt]
                                                     what differs, countdowns and the clock masked; exit 1 if any
"""
import argparse
import difflib
import json
import re
import sys

LISTED_WITHOUT_LABEL = ("Button", "TextField", "SearchField", "Heading", "Link", "Slider", "Switch")


def load(path):
    roots = json.load(sys.stdin if path == "-" else open(path))
    return roots if isinstance(roots, list) else [roots]


def flatten(roots):
    out = []

    def walk(node):
        out.append(node)
        for child in node.get("children", []):
            walk(child)

    for root in roots:
        walk(root)
    return out


def open_sheet(roots):
    """The sheet on top: the sibling after the last dimming group, which is found by being three screens wide."""
    screen = roots[0]["frame"]
    found = []

    def find(node):
        kids = node.get("children", [])
        for i, kid in enumerate(kids):
            if kid["frame"]["x"] < -100 and kid["frame"]["width"] > 2 * screen["width"] and i + 1 < len(kids):
                found.append(kids[i + 1])
            find(kid)

    for root in roots:
        find(root)
    return found[-1] if found else None


def listed(nodes):
    return [n for n in nodes if n.get("AXLabel") or n.get("type") in LISTED_WITHOUT_LABEL]


def mask(text):
    return re.sub(r"\d+:\d\d(:\d\d)?", "<t>", text) if isinstance(text, str) else text


def line(node, masked=False):
    f = node.get("frame") or {}
    label, value = node.get("AXLabel"), node.get("AXValue")
    if masked:
        label, value = mask(label), mask(value)
    return (f"{node.get('type')} {label!r} value={value!r} enabled={node.get('enabled')} "
            f"[{f.get('x', 0):.1f},{f.get('y', 0):.1f} {f.get('width', 0):.1f}x{f.get('height', 0):.1f}]")


def elements(path, sheet_only):
    roots = load(path)
    if not sheet_only:
        return roots, listed(flatten(roots)), None
    sheet = open_sheet(roots)
    if sheet is None:
        return roots, [], None
    return roots, [n for n in listed(flatten([sheet])) if n.get("type") != "Group"], sheet


def print_sheet(roots, nodes, sheet):
    screen, s = roots[0]["frame"], sheet["frame"]
    left, right = s["x"], s["x"] + s["width"]
    print(f"window {screen['width']:.0f}x{screen['height']:.0f}  sheet x {left:.1f}..{right:.1f} "
          f"y {s['y']:.1f}..{s['y'] + s['height']:.1f}")
    worst = 0.0
    for node in nodes:
        f = node["frame"]
        over_left, over_right = max(0.0, left - f["x"]), max(0.0, f["x"] + f["width"] - right)
        worst = max(worst, over_left, over_right)
        flag = f"  <-- past the sheet: left {over_left:.1f} right {over_right:.1f}" if over_left or over_right else ""
        print(line(node) + flag)
    if nodes:
        lowest = max(n["frame"]["y"] + n["frame"]["height"] for n in nodes)
        print(f"BELOW CONTENT {s['y'] + s['height'] - lowest:.1f}")
    print(f"WORST OVERFLOW {worst:.1f}")


def center(nodes, key, value, index):
    if value.startswith("^"):
        found = [n for n in nodes if (n.get(key) or "").startswith(value[1:])]
    else:
        found = [n for n in nodes if (n.get(key) or "") == value]
    if not found or not -len(found) <= index < len(found):
        return 1
    node = found[index]
    f = node["frame"]
    if node.get("type") == "Link" and f["height"] > 30:
        # A link wrapped over two lines: only its last line is sure to start at the frame's leading edge.
        print(round(f["x"] + 12), round(f["y"] + f["height"] - 12))
    else:
        print(round(f["x"] + f["width"] / 2), round(f["y"] + f["height"] / 2))
    return 0


def compare(before, after, tolerance):
    def key(node):
        return (node.get("type"), mask(node.get("AXLabel")), mask(node.get("AXValue")), node.get("enabled"))

    if [key(n) for n in before] != [key(n) for n in after]:
        a, b = [line(n, masked=True) for n in before], [line(n, masked=True) for n in after]
        diff = [d for d in difflib.unified_diff(a, b, "before", "after", n=0, lineterm="") if not d.startswith("@@")]
        print("\n".join(diff))
        return 1
    moved = 0
    for a, b in zip(before, after):
        fa, fb = a["frame"], b["frame"]
        deltas = [fb[k] - fa[k] for k in ("x", "y", "width", "height")]
        if max(abs(d) for d in deltas) > tolerance:
            moved += 1
            print(f"- {line(a, masked=True)}\n+ {line(b, masked=True)}\n"
                  f"  moved x {deltas[0]:+.1f} y {deltas[1]:+.1f}, grew {deltas[2]:+.1f}x{deltas[3]:+.1f}")
    if not moved:
        print(f"identical ({len(before)} elements)")
    return 1 if moved else 0


def main():
    parser = argparse.ArgumentParser(usage=__doc__)
    parser.add_argument("dump")
    parser.add_argument("after", nargs="?")
    parser.add_argument("--filter", default="")
    parser.add_argument("--sheet", action="store_true")
    parser.add_argument("--window", action="store_true")
    parser.add_argument("--center")
    parser.add_argument("--key", default="AXLabel")
    parser.add_argument("--index", type=int, default=-1)
    parser.add_argument("--tolerance", type=float, default=0.0)
    args = parser.parse_args()

    if args.center is not None:
        return center(flatten(load(args.dump)), args.key, args.center, args.index)

    roots, nodes, sheet = elements(args.dump, args.sheet)
    if args.window:
        print(round(roots[0]["frame"]["width"]), round(roots[0]["frame"]["height"]))
        return 0
    if args.after:
        return compare(nodes, elements(args.after, args.sheet)[1], args.tolerance)
    if args.sheet:
        if sheet is None:
            print("NO SHEET OPEN")
            return 1
        print_sheet(roots, nodes, sheet)
        return 0
    for node in nodes:
        text = line(node)
        if args.filter.lower() in text.lower():
            print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
