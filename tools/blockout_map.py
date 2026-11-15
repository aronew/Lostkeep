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
        "seals": [(66, 22, 5, 1)],
        "water": [],
        "ramps": [((60, 592), (128, 544)), ((316, 496), (384, 448)), ((1196, 352), (1264, 304)), ((1292, 304), (1360, 256))],
        "routes": [("tour", AMBER), ("upper", TEAL)],
        "labels": [(1, 38.2, "START"), (46, 19.6, "GREAT ISLAND"), (84, 13.4, "EXIT > IB-04"), (72, 34.2, "cave"), (40, 38.2, "garden")],
        "legend": [(AMBER, "main line (walked in engine)"), (TEAL, "garden, cave, ways back (walked)")],
    },
    "ib04": {
        "seals": [],
        "water": [(88, 37, 4, 2)],
        "ramps": [((228, 304), (160, 256)), ((356, 352), (288, 304)), ((612, 464), (544, 416)), ((868, 592), (800, 544))],
        "routes": [("tour", AMBER), ("upper", TEAL)],
        "labels": [(1, 13.4, "IN < IB-03"), (30, 13.6, "GREAT ISLAND"), (72, 14.6, "FAR ISLAND: Wing-Cloak lock"), (84, 34.6, "water: 4-tile jump"), (100, 38.2, "EXIT > IB-01")],
        "legend": [(AMBER, "main line (walked in engine)"), (TEAL, "islands and the way back (walked)")],
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
