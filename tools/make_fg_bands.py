"""Brings in the continuous foreground bands (Book 1's FG6 to FG10, and the
FG1 silhouettes), from the generator's exports in art/source/ironbark/foreground/
(2172 x 724, painted at about 3 screen pixels per art pixel, no exact grid).

Each sheet holds two versions of its band, A above B. Each is cut out by its
opaque rows (a bottom band keeps the sheet's bottom edge, a top band its top
edge), reduced 3:1 (box average with premultiplied alpha, so no dark fringe)
and its alpha hardened at half. Nothing else is done to it. Saved under
game/assets/environment/ironbark/:

    fg_crypt_bottom_a.png, _b   FG6: the ruin ridge along the bottom of the view
    fg_crypt_top_a.png, _b      FG7: vault, roots and chains along the top
    fg_forest_bottom_a.png, _b  FG9: undergrowth along the bottom (surface)
    fg_forest_top_a.png, _b     FG10: the canopy along the top (surface)
    fg_crypt_lip.png            FG8: kept for later (it reads as a ledge)
    fg_crypt_silhouettes.png    FG1-style silhouettes: kept for later

It also prints how well each version's right end meets its own and the other
version's left end (mean colour difference over the edge column, 0 = perfect).

    python3 tools/make_fg_bands.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art/source/ironbark/foreground"
OUT = ROOT / "game/assets/environment/ironbark"
SCALE = 3

BANDS = [
    ("fg6_crypt_band_bottom.png", "fg_crypt_bottom", "bottom"),
    ("fg7_crypt_band_top.png", "fg_crypt_top", "top"),
    ("fg9_surface_band_bottom.png", "fg_forest_bottom", "bottom"),
    ("fg10_surface_band_top.png", "fg_forest_top", "top"),
]
WHOLE = [
    ("fg8_crypt_floor_lip.png", "fg_crypt_lip"),
    ("fg1_crypt_silhouettes.png", "fg_crypt_silhouettes"),
]


def reduce(a: np.ndarray) -> np.ndarray:
    """Box-reduce an RGBA array SCALE:1 with premultiplied alpha; harden alpha."""
    h, w = (a.shape[0] // SCALE) * SCALE, (a.shape[1] // SCALE) * SCALE
    a = a[:h, :w].astype(np.float64)
    al = a[:, :, 3:4] / 255.0
    pre = np.concatenate([a[:, :, :3] * al, al], axis=2)
    blk = pre.reshape(h // SCALE, SCALE, w // SCALE, SCALE, 4).mean(axis=(1, 3))
    alpha = blk[:, :, 3:4]
    rgb = np.where(alpha > 0, blk[:, :, :3] / np.maximum(alpha, 1e-6), 0)
    out = np.zeros((h // SCALE, w // SCALE, 4), np.uint8)
    out[:, :, :3] = np.clip(np.rint(rgb), 0, 255).astype(np.uint8)
    out[:, :, 3] = np.where(alpha[:, :, 0] >= 0.5, 255, 0)
    out[out[:, :, 3] == 0, :3] = 0
    return out


def segments(alpha: np.ndarray) -> list:
    rows = alpha.max(axis=1) > 40
    segs, start = [], None
    for i, v in enumerate(rows):
        if v and start is None:
            start = i
        if not v and start is not None:
            segs.append((start, i))
            start = None
    if start is not None:
        segs.append((start, len(rows)))
    # Merge segments split by a stray clear row: keep the two biggest groups.
    segs.sort(key=lambda s: s[0])
    merged = [list(segs[0])]
    for s in segs[1:]:
        if s[0] - merged[-1][1] < 24:
            merged[-1][1] = s[1]
        else:
            merged.append(list(s))
    merged.sort(key=lambda s: s[1] - s[0], reverse=True)
    return sorted(merged[:2], key=lambda s: s[0])


def edge_diff(left: np.ndarray, right: np.ndarray) -> float:
    """How far right's last column is from left's first, over rows both cover."""
    h = min(left.shape[0], right.shape[0])
    if left.shape[0] != right.shape[0]:
        # align on the band's anchored edge: bottoms for bottom bands, tops for top
        pass
    a = right[-h:, -1, :].astype(int)
    b = left[-h:, 0, :].astype(int)
    both = (a[:, 3] > 0) & (b[:, 3] > 0)
    only = (a[:, 3] > 0) ^ (b[:, 3] > 0)
    col = np.abs(a[both, :3] - b[both, :3]).mean() if both.any() else 0.0
    return round(float(col), 1), int(only.sum())


def main() -> None:
    for src, name, edge in BANDS:
        a = np.array(Image.open(SRC / src).convert("RGBA"))
        segs = segments(a[:, :, 3])
        outs = []
        for (y0, y1), tag in zip(segs, "ab"):
            # Snap each band's cut to the scale so its anchored edge stays exact.
            y0 = (y0 // SCALE) * SCALE
            y1 = -(-y1 // SCALE) * SCALE
            band = reduce(a[y0:y1])
            rows = np.nonzero(band[:, :, 3].any(axis=1))[0]
            band = band[rows[0]:rows[-1] + 1]
            Image.fromarray(band).save(OUT / f"{name}_{tag}.png")
            outs.append(band)
            print(f"{name}_{tag}: {band.shape[1]} x {band.shape[0]}")
        if len(outs) == 2:
            A, B = outs
            # For a bottom band the bottoms line up; for a top band the tops.
            if edge == "top":
                A, B = A[::-1], B[::-1]
            print(f"  seams (colour diff, rows only one side covers): A|A {edge_diff(A, A)}  A|B {edge_diff(B, A)}  B|A {edge_diff(A, B)}  B|B {edge_diff(B, B)}")
    for src, name in WHOLE:
        a = np.array(Image.open(SRC / src).convert("RGBA"))
        img = reduce(a)
        Image.fromarray(img).save(OUT / f"{name}.png")
        print(f"{name}: {img.shape[1]} x {img.shape[0]}")


if __name__ == "__main__":
    main()
