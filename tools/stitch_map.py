"""Stitch the playtest map tiles into whole-room images, and draw walked routes.

Usage: python3 tools/stitch_map.py [room]   (after `playtest mode=map` and the room's tours)
`room` is ib01 (default) or ib02. Writes room_art.png, room_box.png and
room_routes.png into the room's map folder (game/tests/out[/<room>]/map).
"""
import csv
import os
import sys

from PIL import Image, ImageDraw

ROOM = sys.argv[1] if len(sys.argv) > 1 else "ib01"
BASE = "game/tests/out" + ("" if ROOM == "ib01" else "/" + ROOM)
OUT = BASE + "/map"
# The tours whose walked routes are drawn, per room.
ROUTES = {
    "ib01": [("tour", (242, 176, 74)), ("upper", (63, 224, 200))],
    "ib02": [("tour", (242, 176, 74)), ("west", (63, 224, 200))],
    "ib03": [("tour", (242, 176, 74)), ("upper", (63, 224, 200))],
    "ib04": [("tour", (242, 176, 74)), ("upper", (63, 224, 200))],
    "ib05": [("tour", (242, 176, 74)), ("upper", (63, 224, 200))],
}


def stitch(view, w, h, names):
    im = Image.new("RGB", (w, h))
    for n in names:
        if not n.startswith(view + "_"):
            continue
        _, x, y = n.split("_")
        im.paste(Image.open(os.path.join(OUT, n + ".png")).convert("RGB"), (int(x), int(y)))
    return im


def main():
    lines = open(os.path.join(OUT, "tiles.txt")).read().split("\n")
    w, h = map(int, lines[0].split())
    names = [l for l in lines[1:] if l]
    art = stitch("art", w, h, names)
    box = stitch("box", w, h, names)
    art.save(os.path.join(OUT, "room_art.png"))
    box.save(os.path.join(OUT, "room_box.png"))
    # Routes: Kleo's walked positions from the tours, drawn over the box view.
    routes = box.copy()
    d = ImageDraw.Draw(routes)
    for name, color in ROUTES[ROOM]:
        path = f"{BASE}/{name}/kleo.csv"
        if not os.path.exists(path):
            continue
        pts = [(int(r[5]), int(r[6]) - 12) for r in csv.reader(open(path))]
        for a, b in zip(pts, pts[1:]):
            if abs(a[0] - b[0]) < 40 and abs(a[1] - b[1]) < 60:
                d.line([a, b], fill=color, width=2)
    routes.save(os.path.join(OUT, "room_routes.png"))
    print("stitched", w, h)


if __name__ == "__main__":
    main()
