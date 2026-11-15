"""Draw the Mossback's stand-in sprite sheet (the first enemy has no generated
art yet): six 32x24 frames in the Ironbark palette. Frames 0-3 walk, 4 rest,
5 hurt. It faces right; the game mirrors it.

Usage: python3 tools/make_mossback.py
"""
from PIL import Image

W, H = 32, 24
OUT = "game/assets/characters/mossback/mossback.png"
LINE = (26, 16, 36, 255)
ROCK_D, ROCK, ROCK_L = (58, 40, 74, 255), (88, 66, 110, 255), (122, 98, 144, 255)
MOSS_D, MOSS, MOSS_L = (62, 88, 44, 255), (110, 138, 46, 255), (170, 186, 64, 255)
EYE, EYE_DIM = (242, 176, 74, 255), (150, 100, 60, 255)


def frame(bob, legs, eyes, squash):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    cx, base = 16, 21  # feet on row 22
    rx, ry = (13, 7) if squash else (11, 9)
    cy = base - ry - bob + (1 if squash else 0)
    # Body: a boulder, lit from the upper left.
    for y in range(H):
        for x in range(W):
            dx, dy = (x - cx) / rx, (y - cy) / ry
            d = dx * dx + dy * dy
            if d <= 1.0 and y <= base:
                c = ROCK
                if dx - dy > 0.75:
                    c = ROCK_D
                elif dx + dy < -0.55:
                    c = ROCK_L
                px[x, y] = c
    # Moss cap over the top third, ragged along its hem.
    for x in range(W):
        hem = cy - ry * 0.25 + ((x * 7) % 5 - 2) * 0.8
        for y in range(H):
            if px[x, y][3] and y <= hem:
                dx = (x - cx) / rx
                px[x, y] = MOSS_L if (y < cy - ry * 0.7 and dx < 0.3) else (MOSS if dx < 0.5 else MOSS_D)
    # Outline.
    solid = [[px[x, y][3] > 0 for x in range(W)] for y in range(H)]
    for y in range(H):
        for x in range(W):
            if not solid[y][x]:
                if any(0 <= x + a < W and 0 <= y + b < H and solid[y + b][x + a] for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    px[x, y] = LINE
    # Little legs.
    for i, lx in enumerate((cx - 7, cx - 2, cx + 3, cx + 7)):
        up = 1 if (legs >= 0 and (i + legs) % 2 == 0) else 0
        for y in (base + 1 - up, base + 2 - up):
            if 0 <= y < H:
                px[lx, y] = LINE
                px[lx + 1, y] = ROCK_D
    # Eyes, on the side it faces.
    ey = cy + 1
    for ex in (cx + 5, cx + 8):
        if eyes == "open":
            px[ex, ey] = EYE
            px[ex, ey + 1] = EYE
        elif eyes == "sleepy":
            px[ex, ey + 1] = EYE_DIM
        else:  # hurt: squeezed shut
            px[ex, ey + 1] = LINE
            px[ex - 1, ey] = LINE
    # A sprout on top.
    for sx, sy in ((cx - 3, cy - ry - 1), (cx - 3, cy - ry - 2), (cx - 2, cy - ry - 3), (cx - 4, cy - ry - 3)):
        if 0 <= sy < H:
            px[sx, sy] = MOSS_L
    return im


frames = [frame(0, 0, "open", False), frame(1, -1, "open", False), frame(0, 1, "open", False), frame(1, -1, "open", False),
          frame(0, -1, "sleepy", False), frame(0, -1, "hurt", True)]
sheet = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
for i, f in enumerate(frames):
    sheet.paste(f, (i * W, 0))
sheet.save(OUT)
print("wrote", OUT, sheet.size)
