"""Draw where the built rooms sit: the macro map with the Ironbark sector
marked, and the built rooms to scale on their shared world grid (tiles,
relative to IB-01's origin), with the rooms still to build as dashed boxes.

Usage: python3 tools/world_map.py   (after `playtest mode=map` and
`stitch_map.py` for each room). Writes docs/maps/where_we_are.png.
"""
from PIL import Image, ImageDraw, ImageFont

T = 4                      # px per tile on the sector map
X0, Y0 = -250, -24         # world tile at the sector map's top-left
W, H = 470, 136            # sector map size in tiles
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
AMBER, TEAL, PALE, DIM = (242, 176, 74), (63, 224, 200), (230, 226, 240), (150, 144, 170)

# name, label, origin (tiles), size (tiles), stitched art
ROOMS = [
    ("IB-03", "The Ruin Gardens", (-221, -13), (93, 40), "game/tests/out/ib03/map/room_art.png"),
    ("IB-04", "The Gate Road", (-128, -13), (128, 40), "game/tests/out/ib04/map/room_art.png"),
    ("IB-01", "The Lantern Clearing", (0, 0), (138, 40), "game/tests/out/map/room_art.png"),
    ("IB-05", "The Shrine Hall", (-58, 30), (58, 34), "game/tests/out/ib05/map/room_art.png"),
    ("IB-02", "The Old Crypt", (-170, 28), (112, 40), "game/tests/out/ib02/map/room_art.png"),
    ("IB-06", "The Undercroft (blockout)", (0, 40), (96, 40), "game/tests/out/ib06/map/room_art.png"),
    ("IB-07", "The Pit Shaft (blockout)", (-44, 64), (44, 41), "game/tests/out/ib07/map/room_art.png"),
]
# Not built yet: label, origin, size, what opens it
PLANNED = [
    ("The Keep's foundations", "next on the main line", (98, 62), (60, 30)),
    ("The Refuge road", "behind the plated door: Ironbark Ward", (-246, 32), (74, 30)),
    ("The Lost Keep", "across the broken bridge: Wing-Cloak", (140, 0), (90, 44)),
]


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)


def wx(x):
    return (x - X0) * T


def wy(y):
    return (y - Y0) * T


def dashed_rect(d, box, color, dash=8):
    x0, y0, x1, y1 = box
    for x in range(int(x0), int(x1), dash * 2):
        d.line([(x, y0), (min(x + dash, x1), y0)], fill=color, width=2)
        d.line([(x, y1), (min(x + dash, x1), y1)], fill=color, width=2)
    for y in range(int(y0), int(y1), dash * 2):
        d.line([(x0, y), (x0, min(y + dash, y1))], fill=color, width=2)
        d.line([(x1, y), (x1, min(y + dash, y1))], fill=color, width=2)


def arrow(d, pts, color, width=4):
    d.line(pts, fill=color, width=width, joint="curve")
    (ax, ay), (bx, by) = pts[-2], pts[-1]
    import math
    a = math.atan2(by - ay, bx - ax)
    s = 12
    d.polygon([(bx, by), (bx - s * math.cos(a - 0.45), by - s * math.sin(a - 0.45)),
               (bx - s * math.cos(a + 0.45), by - s * math.sin(a + 0.45))], fill=color)


def sector():
    im = Image.new("RGB", (W * T, H * T), (14, 11, 22))
    d = ImageDraw.Draw(im)
    for name, label, (ox, oy), (w, h), path in ROOMS:
        art = Image.open(path).convert("RGB").resize((w * T, h * T), Image.LANCZOS)
        art = art.point(lambda v: min(255, int(v * 1.7)))  # brighter, to read at this scale
        im.paste(art, (wx(ox), wy(oy)))
        d.rectangle([wx(ox), wy(oy), wx(ox + w) - 1, wy(oy + h) - 1], outline=PALE, width=2)
    for label, why, (ox, oy), (w, h) in PLANNED:
        dashed_rect(d, (wx(ox), wy(oy), wx(ox + w), wy(oy + h)), DIM)
        tx = wx(ox + w) - 330 if label == "The Undercroft" else wx(ox) + 10
        ty = wy(oy + h) - 50 if label == "The Undercroft" else wy(oy) + 10
        d.text((tx, ty), label, fill=PALE, font=font(15, True))
        d.text((tx, ty + 20), "not built: " + why, fill=DIM, font=font(12))
    # The main line: start in IB-03, east through IB-04, into IB-01, down its
    # hall door into IB-05, out its lower East door to the Undercroft.
    path = [(-205, 6), (-120, 2), (-60, 12), (-8, 21), (40, 26), (8, 34), (-30, 36), (-40, 53), (8, 55), (45, 55),
            (56, 65), (14, 65), (12, 76), (60, 76), (104, 76)]
    arrow(d, [(wx(x), wy(y)) for x, y in path], AMBER, 5)
    # Side trips (teal): IB-05's west doors into IB-02 and back; the Lost Keep.
    arrow(d, [(wx(-56), wy(36)), (wx(-90), wy(36)), (wx(-120), wy(46))], TEAL, 3)
    arrow(d, [(wx(110), wy(25)), (wx(150), wy(20))], TEAL, 3)
    arrow(d, [(wx(4), wy(76)), (wx(-14), wy(76)), (wx(-26), wy(96))], TEAL, 3)
    # Labels on the built rooms.
    for i, (name, label, (ox, oy), (w, h), _) in enumerate(ROOMS):
        tx, ty = wx(ox) + 8, wy(oy) + 6
        if name == "IB-05":
            tx, ty = wx(ox) + 8, wy(oy + h) - 46
        if name in ("IB-02", "IB-06", "IB-07"):
            tx, ty = wx(ox) + 8, wy(oy + h) - 46
        d.rectangle([tx - 4, ty - 2, tx + 230, ty + 38], fill=(14, 11, 22))
        d.text((tx, ty), name, fill=AMBER, font=font(16, True))
        d.text((tx, ty + 19), label, fill=PALE, font=font(13))
    # The start.
    sx, sy = wx(-214), wy(9)
    d.ellipse([sx - 9, sy - 9, sx + 9, sy + 9], fill=AMBER)
    d.text((sx + 14, sy - 10), "START", fill=AMBER, font=font(16, True))
    # The well's mouth, up out of IB-02 under IB-04.
    d.text((wx(-131), wy(23)), "IB-02's well rises toward here (gated)", fill=DIM, font=font(11))
    return im


def macro():
    g = Image.open("docs/art-production/lostkeep-attach/G-macro-map.jpg").convert("RGB")
    d = ImageDraw.Draw(g)
    # Ironbark Guard on the mockup (its green region, top left of centre).
    d.rounded_rectangle([170, 160, 760, 480], radius=26, outline=AMBER, width=6)
    d.ellipse([196, 236, 222, 262], fill=AMBER)
    d.rectangle([224, 228, 520, 290], fill=(8, 6, 14))
    d.text((232, 232), "WE ARE HERE", fill=AMBER, font=font(26, True))
    d.text((232, 264), "Ironbark: 5 rooms built", fill=PALE, font=font(18))
    # From Ironbark down to the Refuge (the hub, centre).
    arrow(d, [(600, 440), (700, 470), (790, 480)], AMBER, 6)
    d.rectangle([556, 490, 800, 516], fill=(8, 6, 14))
    d.text((560, 492), "then the Refuge (the hub)", fill=AMBER, font=font(18, True))
    return g


def main():
    m = macro()
    s = sector()
    mw = s.width
    m = m.resize((mw, int(m.height * mw / m.width)), Image.LANCZOS)
    pad = 60
    out = Image.new("RGB", (mw, m.height + s.height + pad * 3), (8, 6, 14))
    d = ImageDraw.Draw(out)
    d.text((20, 16), "1. Vaelora: where Ironbark sits (the macro map mockup, G)", fill=PALE, font=font(24, True))
    out.paste(m, (0, pad))
    y = pad + m.height + pad
    d.text((20, y - 44), "2. The Ironbark sector: the built rooms to scale on the world grid", fill=PALE, font=font(24, True))
    out.paste(s, (0, y))
    ly = y + s.height + 14
    d.line([(20, ly + 10), (70, ly + 10)], fill=AMBER, width=5)
    d.text((80, ly), "main line", fill=PALE, font=font(16))
    d.line([(200, ly + 10), (250, ly + 10)], fill=TEAL, width=3)
    d.text((260, ly), "side ways", fill=PALE, font=font(16))
    dashed_rect(d, (380, ly, 430, ly + 20), DIM)
    d.text((440, ly), "rooms not built yet", fill=PALE, font=font(16))
    out.save("docs/maps/where_we_are.png")
    print(out.size)


if __name__ == "__main__":
    main()
