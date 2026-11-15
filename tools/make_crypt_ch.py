"""Brings in the creative lead's CH sheets (Book 1, CH1 to CH8: the character
pieces after the ten mockups in docs/mockups/character/).

The sheets in art/source/ironbark/crypt_ch/ were delivered grid-aligned (their
README: sheets 1-6 in 8 x 8 cells, 7-8 in 4 x 4). Each is reduced by its cell
size with nearest sampling and nothing else, to game/assets/environment/ironbark/
ch_<n>.png, and its pieces are found (opaque islands, joined when closer than
3 px) and written with their rects to ch_pieces.json. For every piece the
walking line is the first row whose opaque run spans at least 70 % of the
piece's width (a slab's cap row; things standing on it are narrower).

    python3 tools/make_crypt_ch.py
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art/source/ironbark/crypt_ch"
OUT = ROOT / "game/assets/environment/ironbark"
SHEETS = {
    "01-platforms.png": ("ch_platforms", 8),
    "02-supports.png": ("ch_supports", 8),
    "03-stairs-corners.png": ("ch_stairs", 8),
    "04-hanging-details.png": ("ch_hangings", 8),
    "05-small-props.png": ("ch_props", 8),
    "06-back-wall-pieces.png": ("ch_alcoves", 8),
    "07-cave-edges.png": ("ch_cave", 4),
    "08-foreground-dressing.png": ("ch_foreground", 4),
}


def _label(mask: np.ndarray) -> list:
    """Opaque islands of `mask` (8-connected), as lists of (y, x)."""
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    out = []
    for y0, x0 in zip(*np.nonzero(mask)):
        if seen[y0, x0]:
            continue
        stack = [(y0, x0)]
        seen[y0, x0] = True
        cells = []
        while stack:
            y, x = stack.pop()
            cells.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        out.append(cells)
    return out


def pieces(alpha: np.ndarray) -> list:
    # Grow by one pixel so bits closer than 3 px join their piece.
    grown = alpha.copy()
    grown[1:, :] |= alpha[:-1, :]
    grown[:-1, :] |= alpha[1:, :]
    g2 = grown.copy()
    g2[:, 1:] |= grown[:, :-1]
    g2[:, :-1] |= grown[:, 1:]
    out = []
    for cells in _label(g2):
        ys = [c[0] for c in cells]
        xs = [c[1] for c in cells]
        y0, y1, x0, x1 = min(ys), max(ys) + 1, min(xs), max(xs) + 1
        region = np.zeros((y1 - y0, x1 - x0), dtype=bool)
        for y, x in cells:
            region[y - y0, x - x0] = True
        sub = alpha[y0:y1, x0:x1] & region
        if sub.sum() < 12:
            continue
        # Trim to the opaque pixels themselves.
        rows = np.nonzero(sub.any(axis=1))[0]
        cols = np.nonzero(sub.any(axis=0))[0]
        sub = sub[rows[0]:rows[-1] + 1, cols[0]:cols[-1] + 1]
        y0 += int(rows[0])
        x0 += int(cols[0])
        h, w = sub.shape
        p = {"rect": [int(x0), int(y0), int(w), int(h)]}
        for r in range(h):
            row = np.nonzero(sub[r])[0]
            if len(row) and row[-1] - row[0] + 1 >= 0.7 * w and sub[r].sum() >= 0.6 * w:
                p["line"] = int(r)
                p["line_x"] = [int(row[0]), int(row[-1])]
                break
        out.append(p)
    out.sort(key=lambda p: (p["rect"][1] // 40, p["rect"][0]))
    return out

def main() -> None:
    table = {}
    for name, (stem, cell) in SHEETS.items():
        im = Image.open(SRC / name).convert("RGBA")
        small = im.resize((im.width // cell, im.height // cell), Image.NEAREST)
        small.save(OUT / (stem + ".png"))
        a = np.array(small)[:, :, 3] > 0
        table[stem] = pieces(a)
        print(stem, small.size, len(table[stem]), "pieces")
    (OUT / "ch_pieces.json").write_text(json.dumps(table, indent=1))


if __name__ == "__main__":
    main()
