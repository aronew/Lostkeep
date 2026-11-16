"""Draw Resin's stand-in sprite (the currency has no generated art yet): a bead
of the Great Ironbark's sap, honey-gold with a bright glint, in six 9x9 frames
turning (the glint travels round it). Frame 0 is also the counter's icon.

Usage: python3 tools/make_resin.py
"""
from PIL import Image

N, S = 6, 9
OUT = "game/assets/items/resin.png"
LINE = (58, 30, 16, 255)
DARK, MID, LIT, HI = (150, 78, 24, 255), (214, 128, 40, 255), (246, 186, 84, 255), (255, 240, 196, 255)


def frame(i):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    px = im.load()
    c = 4.0
    for y in range(S):
        for x in range(S):
            dx, dy = (x - c) / 3.6, (y - c) / 4.0
            d = dx * dx + dy * dy
            if d > 1.0:
                continue
            if d > 0.72:
                px[x, y] = LINE
            elif dx + dy > 0.35:
                px[x, y] = DARK
            elif dx + dy > -0.45:
                px[x, y] = MID
            else:
                px[x, y] = LIT
    # The glint turns round the bead.
    gx = [2, 3, 4, 5, 4, 3][i]
    gy = [3, 2, 2, 3, 5, 5][i]
    px[gx, gy] = HI
    return im


def main():
    sheet = Image.new("RGBA", (S * N, S), (0, 0, 0, 0))
    for i in range(N):
        sheet.paste(frame(i), (i * S, 0))
    sheet.save(OUT)
    print("wrote", OUT, sheet.size)


if __name__ == "__main__":
    main()
