"""The hooded stranger's frames (Book 1, OP2), from the generator's sheet
art/source/ironbark/outpost/hooded_stranger_frames.png: eight figures in a row,
idle 1 to 4 and talk 5 to 8.

The sheet is painted on a 7.75 px grid (found by lining a grid up with its
colour edges: 2.85 px in across, 3.65 px down). Each art pixel is read at its
centre and the alpha hardened at half: nothing else is done. The eight
figures are split apart and lined up by their feet (the bottom row, and the
middle of the feet across), so the stranger doesn't wobble from frame to frame,
then saved side by side in equal frames:

    game/assets/characters/stranger/stranger_frames.png   (8 frames)

    python3 tools/make_stranger_frames.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art/source/ironbark/outpost/hooded_stranger_frames.png"
OUT = ROOT / "game/assets/characters/stranger/stranger_frames.png"
GRID, PX, PY = 7.75, 2.85, 3.65


def main() -> None:
    a = np.array(Image.open(SRC).convert("RGBA"))
    h, w, _ = a.shape
    xs = [int(PX + GRID * (k + 0.5)) for k in range(int((w - PX) / GRID))]
    ys = [int(PY + GRID * (k + 0.5)) for k in range(int((h - PY) / GRID))]
    s = a[np.ix_(ys, xs)].copy()
    s[:, :, 3] = np.where(s[:, :, 3] >= 128, 255, 0)
    s[s[:, :, 3] == 0] = 0
    op = s[:, :, 3] > 0
    cols = np.nonzero(op.any(axis=0))[0]
    figs, start, prev = [], cols[0], cols[0]
    for c in cols[1:]:
        if c > prev + 1:
            figs.append((start, prev + 1))
            start = c
        prev = c
    figs.append((start, prev + 1))
    assert len(figs) == 8, figs
    cuts = []
    for x0, x1 in figs:
        sub = s[:, x0:x1]
        rows = np.nonzero((sub[:, :, 3] > 0).any(axis=1))[0]
        sub = sub[rows[0]:rows[-1] + 1]
        feet = np.nonzero(sub[-3:, :, 3].any(axis=0))[0]
        cuts.append((sub, (feet.min() + feet.max()) / 2.0))
    fh = max(c[0].shape[0] for c in cuts)
    left = max(c[1] for c in cuts)
    right = max(c[0].shape[1] - c[1] for c in cuts)
    fw = int(np.ceil(left + right)) + 2
    sheet = np.zeros((fh, fw * 8, 4), dtype=np.uint8)
    for i, (sub, mid) in enumerate(cuts):
        ox = i * fw + int(round(fw / 2.0 - mid))
        oy = fh - sub.shape[0]
        sheet[oy:oy + sub.shape[0], ox:ox + sub.shape[1]] = sub
    Image.fromarray(sheet).save(OUT)
    print("stranger frames: 8 of", fw, "x", fh)


if __name__ == "__main__":
    main()
