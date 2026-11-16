"""The hooded stranger (the outpost's wanderer), from the creative lead's
pixel-art mockup art/source/ironbark/outpost/hooded_stranger.png.

The mockup is drawn on a 15.5 px grid starting 12.3 px in (found by lining a
grid up with its colour edges). Each art pixel is read at its centre, the
alpha hardened at half, and the figure is trimmed: nothing else is done.
Writes game/assets/characters/stranger/stranger.png, its feet on the last row.

    python3 tools/make_stranger.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art/source/ironbark/outpost/hooded_stranger.png"
OUT = ROOT / "game/assets/characters/stranger/stranger.png"
GRID = 15.5
PHASE = 12.3


def main() -> None:
    a = np.array(Image.open(SRC).convert("RGBA"))
    h, w, _ = a.shape
    xs = [int(PHASE + GRID * (k + 0.5)) for k in range(int((w - PHASE) / GRID))]
    ys = [int(PHASE + GRID * (k + 0.5)) for k in range(int((h - PHASE) / GRID))]
    small = a[np.ix_(ys, xs)]
    rgba = small.copy()
    rgba[:, :, 3] = np.where(small[:, :, 3] >= 128, 255, 0)
    opaque = rgba[:, :, 3] > 0
    # Trim to the figure: rows and columns with at least 3 of its pixels.
    rows = np.nonzero(opaque.sum(axis=1) >= 3)[0]
    cols = np.nonzero(opaque.sum(axis=0) >= 3)[0]
    rgba = rgba[rows[0]:rows[-1] + 1, cols[0]:cols[-1] + 1]
    Image.fromarray(rgba).save(OUT)
    print("stranger", rgba.shape[1], "x", rgba.shape[0])


if __name__ == "__main__":
    main()
