"""Brings in CH9, the gallery floor and ceiling bands (Book 1), from the
generator's own export: art/source/ironbark/crypt_ch/ch9/lost-keep-terrain-bands-raw.png
(1536 x 1024, painted at full resolution, no pixel grid).

It is reduced 4:1 (box average, to the card's 384 x 256 layout) and its alpha
hardened at half; nothing else is done to it. Each band is cut where its two
ends match best, so it repeats with the least visible seam, and saved as its own
texture under game/assets/environment/ironbark/:

    ch9_floor.png     the floor band, its walking line on row 0
    ch9_ceiling.png   the ceiling band, its underside on its last row
    ch9_under.png     the underside strip, its straight top on row 0
    ch9_steps.png     the two step pieces, as painted

    python3 tools/make_crypt_ch9.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art/source/ironbark/crypt_ch/ch9/lost-keep-terrain-bands-raw.png"
OUT = ROOT / "game/assets/environment/ironbark"


def rows_of(alpha: np.ndarray) -> list:
    rows = np.nonzero(alpha.any(axis=1))[0]
    groups, start, prev = [], rows[0], rows[0]
    for r in rows[1:]:
        if r != prev + 1:
            groups.append((int(start), int(prev) + 1))
            start = r
        prev = r
    groups.append((int(start), int(prev) + 1))
    return groups


def tile_cut(band: np.ndarray) -> np.ndarray:
    """The widest stretch whose last column best matches the one before its first."""
    a = band[:, :, 3] > 0
    cols = np.nonzero(a.all(axis=0) | (a.sum(axis=0) > 0.6 * a.shape[0]))[0]
    lo, hi = int(cols.min()) + 1, int(cols.max())
    rgb = band[:, :, :3].astype(float)
    best = None
    for w in range(hi - lo - 40, hi - lo + 1):
        for x0 in range(lo, hi - w + 1):
            err = np.abs(rgb[:, x0 + w - 1] - rgb[:, x0 - 1]).mean() + np.abs(rgb[:, x0 + w] - rgb[:, x0]).mean() if x0 + w < band.shape[1] else 1e9
            if best is None or err < best[0]:
                best = (err, x0, w)
    _, x0, w = best
    return band[:, x0:x0 + w]


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    small = np.array(im.resize((im.width // 4, im.height // 4), Image.BOX))
    small[:, :, 3] = np.where(small[:, :, 3] >= 128, 255, 0)
    small[small[:, :, 3] == 0] = 0
    groups = rows_of(small[:, :, 3] > 0)
    assert len(groups) == 4, groups
    names = ["ch9_floor", "ch9_ceiling", "ch9_under"]
    for (y0, y1), name in zip(groups[:3], names):
        band = tile_cut(small[y0:y1])
        # The reduction leaves a half-covered row at a band's straight edge:
        # drop it, so the line is a full row of stone.
        full = (band[:, :, 3] > 0).mean(axis=1) >= 0.9
        if name == "ch9_ceiling":
            while not full[-1]:
                band, full = band[:-1], full[:-1]
        else:
            while not full[0]:
                band, full = band[1:], full[1:]
        Image.fromarray(band).save(OUT / (name + ".png"))
        print(name, band.shape[1], "x", band.shape[0])
    y0, y1 = groups[3]
    Image.fromarray(small[y0:y1]).save(OUT / "ch9_steps.png")
    print("ch9_steps", small.shape[1], "x", y1 - y0)


if __name__ == "__main__":
    main()
