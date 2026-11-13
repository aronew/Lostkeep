"""Cut the processed Ironbark sheets into seamless, game-ready textures.

Generated bands rarely tile cleanly, so each texture is made seamless with a
minimum-error cut at its wrap (or cut at a whole number of repeats for regular
patterns), keeping every pixel crisp. Every band steps down to the void at its
inner end, because the inside of each mass is painted black.
Output: game/assets/environment/ironbark/terrain/ and .../parallax/.

Usage: python3 tools/make_terrain.py
"""
import os

import numpy as np
from PIL import Image

SRC = "game/assets/environment/ironbark"
TERRAIN = os.path.join(SRC, "terrain")
PARALLAX = os.path.join(SRC, "parallax")
VOID = np.array([11, 8, 18, 255], np.uint8)

BAYER4 = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 + 1 / 32


def load(name):
    return np.asarray(Image.open(os.path.join(SRC, name)).convert("RGBA")).copy()


def save(arr, folder, name):
    os.makedirs(folder, exist_ok=True)
    Image.fromarray(arr, "RGBA").save(os.path.join(folder, name))
    print(f"{name}: {arr.shape[1]}x{arr.shape[0]}")


def wrap_x(a, blend):
    """Seamless horizontally by a minimum-error cut (image quilting): the first
    `blend` columns take the image's tail on the left of a winding cut and its
    head on the right. The cut follows the path where the two match best, so the
    join has no blur and no dither."""
    h, w, _ = a.shape
    head = a[:, :blend].astype(int)
    tail = a[:, w - blend:].astype(int)
    diff = np.abs(head - tail)
    cost = diff[..., :3].sum(2) + diff[..., 3] * 3  # alpha mismatches cost most
    # Dynamic programming: cheapest top-to-bottom path, moving at most one
    # column per row, kept off the overlap's outer edges.
    acc = cost.astype(float).copy()
    acc[:, :2] = acc[:, -2:] = 1e9
    back = np.zeros((h, blend), int)
    for y in range(1, h):
        for x in range(2, blend - 2):
            prev = acc[y - 1, x - 1:x + 2]
            k = int(np.argmin(prev))
            back[y, x] = x - 1 + k
            acc[y, x] += prev[k]
    out = a[:, : w - blend].copy()
    x = int(np.argmin(acc[-1]))
    for y in range(h - 1, -1, -1):
        out[y, :x] = a[y, w - blend: w - blend + x]  # the tail, left of the cut
        out[y, x:blend] = a[y, x:blend]  # the head, right of the cut
        x = back[y, x] if y > 0 else x
    return out


def wrap_period(a, period, count):
    """Seamless by cutting exactly `count` repeats of a regular pattern (arches,
    carved panels), starting where the cut's two ends match best: no blending."""
    w = period * count
    best, best_err = 0, None
    for start in range(0, a.shape[1] - w + 1):
        left = a[:, start:start + 3].astype(float)
        right = a[:, start + w - 3:start + w].astype(float)
        nxt = a[:, start + w:start + w + 3].astype(float) if start + w + 3 <= a.shape[1] else None
        # Compare the column after the cut's end with the cut's first columns.
        err = np.abs((nxt if nxt is not None else right) - left).sum()
        if best_err is None or err < best_err:
            best, best_err = start, err
    return a[:, best:best + w].copy()


def wrap_y(a, blend):
    return np.transpose(wrap_x(np.transpose(a, (1, 0, 2)), blend), (1, 0, 2))


def darken_rows(a, rows, toward_bottom=False, floor=0.0):
    """Step the given number of rows down toward the void colour (pixel-art banding).
    `floor` is the brightness kept at the edge: 0 for full void, ~0.5 to meet a lit fill."""
    h = a.shape[0]
    out = a.copy().astype(float)
    for i in range(rows):
        y = h - 1 - i if toward_bottom else i
        k = i / rows  # 0 at the edge -> darkest, 1 -> untouched
        k = np.floor(k * 4) / 4
        k = floor + (1 - floor) * k
        mask = out[y, :, 3] > 0
        out[y, mask, :3] = out[y, mask, :3] * k + VOID[:3] * (1 - k)
    return out.astype(np.uint8)


def first_full_row(a, start, frac=0.95):
    w = a.shape[1]
    for y in range(start, a.shape[0]):
        if (a[y, :, 3] > 0).mean() >= frac:
            return y
    return start


# Every band ends in the void: the inside of a mass is black (the black box is
# the shadow), so each band steps down to the void colour at its inner end and
# nothing else is painted between a floor's soil and the ceiling below it.
SOIL_LIT = 12   # rows of lit soil kept under a walking line
SOIL_FADE = 10  # rows over which the soil then steps down to the void
WALL_LIT = 12   # columns of lit rock behind a wall face
WALL_FADE = 8   # columns over which it then steps down to the void


def degreen(a):
    """Replace foliage (green-dominant pixels) with the first non-green pixel below."""
    out = a.copy()
    rgb = a[..., :3].astype(int)
    green = rgb[..., 1] >= rgb[..., 0] - 2  # soil is purple-brown: red well above green
    h = a.shape[0]
    for x in range(a.shape[1]):
        for y in range(h):
            if green[y, x]:
                k = y
                while k < h - 1 and green[k, x]:
                    k += 1
                out[y, x] = a[k, x]
    return out


def soil(top, line):
    """Keep the walking band's grass and a short lit soil, then fade to the void."""
    a = top[: line + SOIL_LIT + SOIL_FADE]
    return darken_rows(a, SOIL_FADE, toward_bottom=True)


def main():
    # --- earth -------------------------------------------------------------
    edges = load("ironbark_earth_edges.png")
    top = edges[0:62]
    line = first_full_row(top, 0, 0.97)
    save(wrap_x(soil(top, line), 32), TERRAIN, "earth_top.png")
    print("  earth top walking line row", line)

    under = edges[74:127, 58:382]
    # ceiling line: the last row that is still (nearly) full width
    full = [(under[y, :, 3] > 0).mean() for y in range(under.shape[0])]
    ceil_line = max(y for y, f in enumerate(full) if f > 0.97) + 1
    under = darken_rows(under, 14)
    save(wrap_x(under, 32), TERRAIN, "earth_under.png")
    print("  earth under ceiling line row", ceil_line)

    # The wall: the floor's own soil turned on its side, so a cut face (the drop,
    # a shaft, a pier) is the same earth as the ground above it. (IB3's wall band
    # grows ferns and mushrooms out of the rock, which reads as leafy clutter on
    # short faces.) The soil starts under the grass, with the vines that hang
    # into it replaced by the soil beneath them, so no leaf lies sideways.
    soil_rows = degreen(wrap_x(top, 32)[line + 7: line + 7 + 30])[: WALL_LIT + WALL_FADE]
    wall = np.transpose(soil_rows, (1, 0, 2))[:, ::-1].copy()  # face (right) = nearest the grass
    wall[:, -1, :3] = np.minimum(wall[:, -1, :3].astype(float) * 1.25 + 6, 255).astype(np.uint8)
    wall = np.transpose(darken_rows(np.transpose(wall, (1, 0, 2)), WALL_FADE), (1, 0, 2))
    save(wall, TERRAIN, "earth_wall.png")  # already seamless: it is the wrapped top band
    print("  earth wall face column", wall.shape[1] - 1)

    fill = load("ironbark_earth_fill.png")
    save(wrap_y(wrap_x(fill, 16), 16), TERRAIN, "earth_fill.png")

    # --- stone (the Lost Keep's crypts) -----------------------------------------
    k2 = load("keep_stone_edges.png")
    stop = k2[12:59]
    sline = first_full_row(stop, 0, 0.97)
    save(wrap_x(soil(stop, sline), 32), TERRAIN, "stone_top.png")
    print("  stone top walking line row", sline)
    sunder = k2[75:122]
    sunder = darken_rows(sunder, 10)
    save(wrap_period(sunder, 107, 3), TERRAIN, "stone_under.png")  # the arches repeat every 107 px
    course = k2[134:184]
    save(wrap_period(course, 148, 2), TERRAIN, "stone_course.png")  # the carved panels every 148 px
    k1 = load("keep_stone_fill.png")
    sfill = wrap_y(wrap_x(k1, 16), 16)
    save(sfill, TERRAIN, "stone_fill.png")
    # stone wall: a strip of the fill with a worn face on the right
    sw = sfill[:, :WALL_LIT + WALL_FADE].astype(float)
    sw[:, -1, :3] = [37, 27, 44]
    sw[:, -2, :3] = np.minimum(sw[:, -2, :3] * 1.45 + 12, 255)
    sw[:, -3, :3] = np.minimum(sw[:, -3, :3] * 1.2 + 6, 255)
    sw = np.transpose(darken_rows(np.transpose(sw.astype(np.uint8), (1, 0, 2)), WALL_FADE), (1, 0, 2))
    save(sw, TERRAIN, "stone_wall.png")

    # --- parallax -----------------------------------------------------------
    for name, out in [("ironbark_bg_sky.png", "sky.png"), ("ironbark_bg_far.png", "far.png"),
                      ("ironbark_bg_wall.png", "wall.png"), ("ironbark_fg.png", "fg.png")]:
        save(wrap_x(load(name), 48), PARALLAX, out)
    mid = wrap_x(load("ironbark_bg_mid.png"), 48)
    # A natural crown line: the canopy ends in rounded tree crowns against the
    # sky instead of a straight cut. Crowns of varied width and height, laid
    # end to end across the layer's width, so the layer still tiles.
    w = mid.shape[1]
    rng = np.random.default_rng(7)
    widths = []
    while sum(widths) < w:
        widths.append(int(rng.integers(38, 92)))
    widths[-1] -= sum(widths) - w
    if widths[-1] < 30:
        last = widths.pop()  # (pop first: `widths[-2] += widths.pop()` hits the wrong item)
        widths[-1] += last
    edge = np.zeros(w)
    x0 = 0
    for cw in widths:
        h = rng.uniform(14, 30)
        xs = np.arange(cw)
        t = (xs + 0.5) / cw * 2 - 1  # -1..1 across the crown
        edge[x0:x0 + cw] = 48 - h * np.sqrt(np.clip(1 - t * t, 0, 1)) ** 0.8
        x0 += cw
    # Small leafy ripples on each crown, so they read as foliage, not domes.
    edge += 1.6 * np.sin(np.arange(w) * 2 * np.pi / 9.0) + 1.0 * np.sin(np.arange(w) * 2 * np.pi / 5.0)
    edge = np.round(edge).astype(int)
    for x in range(w):
        mid[: edge[x], x, 3] = 0
    # A dark outline on the new crown line only (not on the canopy's own holes).
    for x in range(w):
        ys = np.nonzero(mid[:, x, 3] > 0)[0]
        if len(ys):
            y = ys[0]
            mid[y, x, :3] = (mid[y, x, :3] * 0.5).astype(np.uint8)
    for name, img in [("far", load("ironbark_bg_far.png")), ("mid", mid)]:
        bottom = img[-6:, :, :3].reshape(-1, 3).mean(0)
        print(f"  {name} base colour #{int(bottom[0]):02x}{int(bottom[1]):02x}{int(bottom[2]):02x}")
    save(mid, PARALLAX, "mid.png")


if __name__ == "__main__":
    main()
