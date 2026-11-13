"""Build the Ironbark foreground silhouettes: dark shapes right in front of the
camera that scroll faster than the playfield and give the room depth.

They are alpha masks (white where solid): the game paints them one flat, near-
void colour with `shaders/silhouette.gdshader`, so only their outlines matter.
The outlines come from the processed art itself (ferns, grass, moss, vines),
plus two procedurally drawn tree trunks with root flares, kept pixel-crisp.

Output (game/assets/environment/ironbark/parallax/):
  fg_fringe.png   720 x 72, tiles horizontally: fern and grass clumps for the
                  bottom of the screen, with gaps so the world shows between.
  fg_hang.png     720 x 110, tiles horizontally: moss and vines hanging from
                  the top of the screen, sparse.
  fg_trunks.png   two trunks side by side, each 220 x 400 (base at the bottom).

Usage: python3 tools/make_silhouettes.py
"""
import os

import numpy as np
from PIL import Image

SRC = "game/assets/environment/ironbark"
OUT = os.path.join(SRC, "parallax")


def alpha(name, rect):
    x, y, w, h = rect
    a = np.asarray(Image.open(os.path.join(SRC, name)).convert("RGBA"))[:, :, 3]
    return a[y:y + h, x:x + w] > 0


def stamp(canvas, mask, x, y, flip=False, wrap=True):
    """OR a mask into the canvas at (x, y). Strips wrap horizontally so they tile."""
    if flip:
        mask = mask[:, ::-1]
    h, w = mask.shape
    H, W = canvas.shape
    for r in range(h):
        yy = y + r
        if 0 <= yy < H:
            cols = np.arange(w) + x
            if wrap:
                canvas[yy, cols % W] |= mask[r]
            else:
                ok = (cols >= 0) & (cols < W)
                canvas[yy, cols[ok]] |= mask[r][ok]


def save(mask, name):
    img = np.zeros(mask.shape + (4,), np.uint8)
    img[mask] = (255, 255, 255, 255)
    Image.fromarray(img, "RGBA").save(os.path.join(OUT, name))
    print(f"{name}: {mask.shape[1]}x{mask.shape[0]}")


# --- Pieces cut from the sheets (pixel rects, found from their alpha) -------------------
FERN_A = ("parallax/fg.png", (320, 168, 288, 88))   # the fern band's long clump
FERN_B = ("parallax/fg.png", (624, 168, 96, 88))    # these two meet across the wrap:
FERN_C = ("parallax/fg.png", (0, 168, 240, 88))     # B then C make one clump
BUSH = ("props_flora.png", (6, 6, 73, 42))
BUSH_SMALL = ("props_flora.png", (11, 55, 48, 30))
GRASS_TALL = ("props_flora.png", (124, 204, 37, 41))
GRASS_MID = ("props_flora.png", (177, 214, 30, 31))
GRASS_LOW = ("props_flora.png", (219, 223, 19, 22))
MOSS_A = ("props_flora.png", (9, 162, 66, 50))
MOSS_B = ("props_flora.png", (89, 162, 70, 37))
VINE_S = ("props_flora.png", (171, 126, 15, 51))
VINE_M = ("props_flora.png", (198, 126, 16, 71))
VINE_L = ("props_flora.png", (227, 126, 14, 88))


def fringe():
    """Clumps along the bottom edge. Kept low (most under 40 px) so they frame the
    lower floor without hiding Kleo's feet when she walks the crypt."""
    W, H = 720, 72
    c = np.zeros((H, W), bool)
    base = H  # plants stand on the strip's bottom edge

    def put(piece, x, sink=0, flip=False):
        m = alpha(*piece)
        stamp(c, m, x, base - m.shape[0] + sink, flip)

    # A big fern clump (the fg band's own, sunk so only its upper fronds rise).
    put(FERN_A, 10, sink=26)
    put(GRASS_TALL, 300, sink=4)
    put(GRASS_LOW, 334, sink=2)
    put(BUSH, 404, sink=10, flip=True)
    put(GRASS_MID, 470, sink=3, flip=True)
    put(FERN_B, 560, sink=30)
    put(FERN_C, 656, sink=30)  # wraps round to the strip's start
    put(GRASS_LOW, 540, sink=2, flip=True)
    return c


def hang():
    """Moss and vines hanging from the top edge, a few clusters per strip."""
    W, H = 720, 110
    c = np.zeros((H, W), bool)

    def put(piece, x, y, flip=False):
        stamp(c, alpha(*piece), x, y, flip)

    # Cluster 1: a moss mat with three vines falling from it.
    put(MOSS_A, 60, -14)
    put(VINE_L, 70, 14)
    put(VINE_S, 98, 20)
    put(VINE_M, 112, 12)
    # Cluster 2: a lighter fringe.
    put(MOSS_B, 380, -12, flip=True)
    put(VINE_M, 396, 10, flip=True)
    put(VINE_S, 430, 16)
    # Cluster 3: a single long vine and a small mat.
    put(MOSS_B, 600, -16)
    put(VINE_L, 640, 6, flip=True)
    return c


TRUNK_W = 220


def trunk(seed, lean):
    """One tree trunk rising out of frame: a gently swaying column with bark knots,
    a root flare and roots gripping the ground, and one limb reaching up."""
    rng = np.random.default_rng(seed)
    W, H = TRUNK_W, 400
    c = np.zeros((H, W), bool)
    ys = np.arange(H)
    # Bark: low bumps on each side, in whole pixels, so the edge reads hand-placed.
    def bumps(scale=1.0):
        b = np.zeros(H)
        for f, amp in ((1 / 70, 2.2), (1 / 31, 1.4), (1 / 11, 0.8)):
            b += scale * amp * np.sin(2 * np.pi * f * ys + rng.uniform(0, 6.3))
        return np.round(b)
    left, right = bumps(), bumps()
    side = 1 if lean >= 0 else -1  # the limb's side
    axis = W / 2 - side * 14 + lean * (ys - H) / H * 16 + 5 * np.sin(ys / 85 + rng.uniform(0, 6.3))
    # The trunk thickens a little toward the ground, then flares into its roots.
    half = 17 + 6 * ys / H + 24 * np.exp(-(H - 1 - ys) / 16)
    for y in range(H):
        x0 = int(round(axis[y] - half[y] - left[y]))
        x1 = int(round(axis[y] + half[y] + right[y]))
        c[y, max(0, x0):min(W, x1)] = True

    yy, xx = np.mgrid[0:H, 0:W]

    def limb(points, w0, w1, wobble=1.5):
        """A tapered, slightly knobbly limb along a smooth curve through `points`."""
        pts = np.array(points, float)
        # Catmull-Rom through the points, so limbs bend instead of kinking.
        p = np.vstack([pts[0], pts, pts[-1]])
        curve = []
        for i in range(1, len(p) - 2):
            for t in np.linspace(0, 1, 24, endpoint=False):
                t2, t3 = t * t, t * t * t
                curve.append(0.5 * ((2 * p[i]) + (-p[i - 1] + p[i + 1]) * t
                                    + (2 * p[i - 1] - 5 * p[i] + 4 * p[i + 1] - p[i + 2]) * t2
                                    + (-p[i - 1] + 3 * p[i] - 3 * p[i + 1] + p[i + 2]) * t3))
        curve.append(pts[-1])
        curve = np.array(curve)
        seg = np.linalg.norm(np.diff(curve, axis=0), axis=1)
        dist = np.concatenate([[0], np.cumsum(seg)])
        total = dist[-1]
        phase = rng.uniform(0, 6.3)
        for (x, y), d in zip(curve, dist):
            r = (w0 + (w1 - w0) * d / total) / 2 + wobble * 0.5 * np.sin(d / 9 + phase)
            c[(xx - x) ** 2 + (yy - y) ** 2 <= r * r] = True

    # Roots: fingers spreading over the ground and diving into it.
    base = H - 1
    ax = axis[base]
    for s in (-1, 1):
        reach = 1.0 if s == side else 0.85
        limb([(ax + s * 16, base - 30), (ax + s * 44, base - 12), (ax + s * 70 * reach, base - 3), (ax + s * 94 * reach, base + 4)], 18, 5)
        limb([(ax + s * 8, base - 18), (ax + s * 26, base - 4), (ax + s * 40, base + 6)], 12, 6)
    # The main limb: out from the trunk, then up and out of the frame.
    y0 = 150 + int(rng.integers(0, 24))
    ax = axis[y0]
    limb([(ax + side * 10, y0 + 8), (ax + side * 40, y0 - 30), (ax + side * 62, y0 - 90), (ax + side * 70, y0 - 150), (ax + side * 64, -16)], 24, 12)
    # A twig forking off it, with a vine hanging from its end.
    fy = y0 - 70
    fx = ax + side * 56
    tip = (fx + side * 46, fy - 22)
    limb([(fx, fy), (fx + side * 24, fy - 6), tip], 8, 3, wobble=0.6)
    vine = alpha(*VINE_L)
    stamp(c, vine, int(tip[0] - vine.shape[1] / 2), int(tip[1]), wrap=False)
    # A broken stub low on the other side.
    y1 = 250 + int(rng.integers(0, 20))
    ax = axis[y1]
    limb([(ax - side * 10, y1 + 4), (ax - side * 30, y1 - 8), (ax - side * 40, y1 - 22)], 14, 9)
    # Growth at the foot, so the trunk stands in the fringe rather than on a line.
    for piece, dx, flip in ((BUSH, -side * 60, side > 0), (GRASS_TALL, side * 34, False), (GRASS_LOW, -side * 10, True)):
        m = alpha(*piece)
        stamp(c, m, int(axis[base] + dx - m.shape[1] / 2), H - m.shape[0] + 4, flip, wrap=False)
    return c


def main():
    save(fringe(), "fg_fringe.png")
    save(hang(), "fg_hang.png")
    a, b = trunk(11, 1.0), trunk(23, -1.0)
    save(np.concatenate([a, b], axis=1), "fg_trunks.png")


if __name__ == "__main__":
    main()
