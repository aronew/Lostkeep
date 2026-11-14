"""Draw a room's black-box map from its collision cells, readable at a glance:
solid rock in the void colour on a pale sky, with the walked routes and the
labels given below. For blockout reviews, before any art is placed.

Usage: python3 tools/blockout_map.py ib03   (after `playtest mode=map` and the tours)
Writes game/tests/out/<room>/map/room_blockout.png.
"""
import csv
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

T = 16
S = 2  # drawn at twice the game's pixels, so the labels are legible
AMBER, TEAL, INK = (242, 176, 74), (63, 224, 200), (235, 238, 245)
# Per room: seals and water as tile rects, routes, and labels at tile positions.
ROOMS = {
    "ib03": {
        "seals": [(5, 22, 5, 2), (34, 25, 6, 1), (44, 25, 6, 1), (6, 19, 14, 1), (49, 18, 16, 1)],
        "water": [(34, 27, 16, 4)],
        "ramps": [((440, 432), (384, 384)), ((488, 432), (544, 400)), ((856, 432), (800, 400)), ((904, 432), (960, 384)),
                  ((1048, 384), (1104, 336)), ((1192, 336), (1248, 288)), ((1336, 288), (1392, 240))],
        "routes": [("tour", AMBER), ("upper", TEAL)],
        "labels": [
            (1, 25.2, "START  row 24\nunder the great tree"),
            (8, 16.4, "WEST BRANCH (one-way)"),
            (23, 15.2, "RUIN ISLAND"),
            (37, 14.2, "GRAVE ISLAND"),
            (50, 15.2, "EAST BRANCH (one-way)"),
            (34, 22.4, "BROKEN BRIDGE: 4-tile gap"),
            (36, 29.2, "POOL: Breath lock"),
            (60, 25.2, "HILL: four flights of stairs"),
            (84, 11.4, "CHAPEL  row 15\nthe guard's post"),
            (97, 5.2, "FAR ISLAND\nWing-Cloak lock"),
            (101, 30.2, "EAST DOOR > IB-01"),
        ],
        "legend": [(AMBER, "main line (walked in engine)"), (TEAL, "upper line (walked in engine)")],
    },
}


def main(room):
    cfg = ROOMS[room]
    base = f"game/tests/out/{room}"
    d = json.load(open(f"{base}/map/cells.json"))
    _, _, w, h = d["room"]
    im = Image.new("RGB", (w * T * S, h * T * S), (70, 86, 122))
    dr = ImageDraw.Draw(im)
    for gx in range(0, w, 5):
        dr.line([(gx * T * S, 0), (gx * T * S, h * T * S)], fill=(78, 94, 130))
    for gy in range(0, h, 5):
        dr.line([(0, gy * T * S), (w * T * S, gy * T * S)], fill=(78, 94, 130))

    def rect(r, fill):
        x, y, rw, rh = r
        dr.rectangle([x * T * S, y * T * S, (x + rw) * T * S - 1, (y + rh) * T * S - 1], fill=fill)

    for x, y, _m in d["cells"]:
        rect((x, y, 1, 1), (11, 8, 18))
    for r in cfg["water"]:
        rect(r, (40, 110, 130))
    for r in cfg["seals"]:
        rect(r, (150, 108, 66))
    for foot, head in cfg.get("ramps", []):
        dr.polygon([(foot[0] * S, foot[1] * S), (head[0] * S, head[1] * S), (head[0] * S, foot[1] * S)], fill=(11, 8, 18))
    for name, col in cfg["routes"]:
        path = f"{base}/{name}/kleo.csv"
        if not os.path.exists(path):
            continue
        pts = [(int(r[5]) * S, (int(r[6]) - 12) * S) for r in csv.reader(open(path))]
        for a, b in zip(pts, pts[1:]):
            if abs(a[0] - b[0]) < 80 and abs(a[1] - b[1]) < 120:
                dr.line([a, b], fill=col, width=3)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 17)
    except OSError:
        font = ImageFont.load_default()
    for x, y, text in cfg["labels"]:
        dr.multiline_text((x * T * S, y * T * S), text, fill=INK, font=font, stroke_width=3, stroke_fill=(11, 8, 18))
    for i, (col, text) in enumerate(cfg["legend"]):
        y = 20 + i * 28
        dr.line([(w * T * S - 420, y + 10), (w * T * S - 380, y + 10)], fill=col, width=4)
        dr.text((w * T * S - 370, y), text, fill=INK, font=font, stroke_width=3, stroke_fill=(11, 8, 18))
    out = f"{base}/map/room_blockout.png"
    im.save(out)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "ib03")
