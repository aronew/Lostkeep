"""The outpost building (Book 1, OP1), from the generator's own image
art/source/ironbark/outpost/outpost_building_white.png (1536 x 1024, painted at full
resolution, no pixel grid).

Cropped to the building, reduced 5:1 (box), its alpha hardened at half:
nothing else is done. 5:1 makes it about 277 x 184 px in the game, about six
and a half times Kleo's height, as in the creative lead's outpost mockup.
Prints where its doorway and windows fall, for the builder.

    python3 tools/make_outpost.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
# The white door (the creative lead's pick); outpost_building.png is the gold one.
SRC = ROOT / "art/source/ironbark/outpost/outpost_building_white.png"
OUT = ROOT / "game/assets/environment/ironbark/outpost.png"
FACTOR = 5


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    a = np.array(im)
    ys, xs = np.nonzero(a[:, :, 3] > 128)
    x0, y0 = xs.min(), ys.min()
    w = (xs.max() + 1 - x0 + FACTOR - 1) // FACTOR * FACTOR
    h = (ys.max() + 1 - y0 + FACTOR - 1) // FACTOR * FACTOR
    crop = im.crop((x0, y0, x0 + w, y0 + h))
    small = np.array(crop.resize((w // FACTOR, h // FACTOR), Image.BOX))
    small[:, :, 3] = np.where(small[:, :, 3] >= 128, 255, 0)
    small[small[:, :, 3] == 0] = 0
    Image.fromarray(small).save(OUT)
    print("outpost", small.shape[1], "x", small.shape[0], "from crop at", x0, y0)
    for name, (sx, sy) in {"door (centre, sill)": (465, 930), "round window": (790, 640), "leaf window": (930, 760)}.items():
        print(" ", name, round((sx - x0) / FACTOR), round((sy - y0) / FACTOR))


if __name__ == "__main__":
    main()
