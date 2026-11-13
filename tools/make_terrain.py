"""Cut the processed Ironbark sheets into seamless, game-ready textures.

Generated bands rarely tile cleanly, so each texture is made seamless with a
dithered cross-fade at its wrap (an ordered Bayer pattern keeps every pixel
crisp). Output: game/assets/environment/ironbark/terrain/ and .../parallax/.

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
    """Seamless horizontally: the first `blend` columns fade from the tail into the head."""
    h, w, _ = a.shape
    out = a[:, : w - blend].copy()
    for x in range(blend):
        t = (x + 0.5) / blend  # 0 = tail, 1 = head
        for y in range(h):
            use_head = BAYER4[y % 4, x % 4] < t
            out[y, x] = a[y, x] if use_head else a[y, w - blend + x]
    return out


def wrap_y(a, blend):
    return np.transpose(wrap_x(np.transpose(a, (1, 0, 2)), blend), (1, 0, 2))


def darken_rows(a, rows, toward_bottom=False):
    """Step the given number of rows down to the void colour (pixel-art banding)."""
    h = a.shape[0]
    out = a.copy().astype(float)
    for i in range(rows):
        y = h - 1 - i if toward_bottom else i
        k = i / rows  # 0 at the edge -> full void, 1 -> untouched
        k = np.floor(k * 4) / 4
        mask = out[y, :, 3] > 0
        out[y, mask, :3] = out[y, mask, :3] * k + VOID[:3] * (1 - k)
    return out.astype(np.uint8)


def first_full_row(a, start, frac=0.95):
    w = a.shape[1]
    for y in range(start, a.shape[0]):
        if (a[y, :, 3] > 0).mean() >= frac:
            return y
    return start


def main():
    # --- earth -------------------------------------------------------------
    edges = load("ironbark_earth_edges.png")
    top = edges[0:62]
    line = first_full_row(top, 0, 0.97)
    save(wrap_x(top, 32), TERRAIN, "earth_top.png")
    print("  earth top walking line row", line)

    under = edges[74:127, 58:382]
    # ceiling line: the last row that is still (nearly) full width
    full = [(under[y, :, 3] > 0).mean() for y in range(under.shape[0])]
    ceil_line = max(y for y, f in enumerate(full) if f > 0.97) + 1
    under = darken_rows(under, 14)
    save(wrap_x(under, 32), TERRAIN, "earth_under.png")
    print("  earth under ceiling line row", ceil_line)

    corners = load("ironbark_earth_walls_corners.png")
    band = corners[:, 0:128]
    faces = []
    for y in range(band.shape[0]):
        xs = np.nonzero(band[y, :, 3] > 0)[0]
        if len(xs):
            faces.append(xs.max())
    face = int(np.median(faces))
    wall = band[:, max(0, face - 55): face + 1]
    # straighten the face: clear anything right of it (already cropped) and fill gaps
    # darken toward the interior (left side)
    wall = np.transpose(darken_rows(np.transpose(wall, (1, 0, 2)), 18), (1, 0, 2))
    save(wrap_y(wall, 32), TERRAIN, "earth_wall.png")
    print("  earth wall face column", wall.shape[1] - 1)

    fill = load("ironbark_earth_fill.png")
    save(wrap_y(wrap_x(fill, 16), 16), TERRAIN, "earth_fill.png")

    # --- stone (the Lost Keep's crypts) -----------------------------------------
    k2 = load("keep_stone_edges.png")
    stop = k2[12:59]
    save(wrap_x(stop, 32), TERRAIN, "stone_top.png")
    print("  stone top walking line row", first_full_row(stop, 0, 0.97))
    sunder = k2[75:122]
    sunder = darken_rows(sunder, 8)
    save(wrap_x(sunder, 32), TERRAIN, "stone_under.png")
    course = k2[134:184]
    save(wrap_x(course, 32), TERRAIN, "stone_course.png")
    k1 = load("keep_stone_fill.png")
    sfill = wrap_y(wrap_x(k1, 16), 16)
    save(sfill, TERRAIN, "stone_fill.png")
    # stone wall: a strip of the fill with a worn face on the right
    sw = np.tile(sfill[:, :48], (1, 1, 1)).astype(float)
    sw[:, -1, :3] = [37, 27, 44]
    sw[:, -2, :3] = np.minimum(sw[:, -2, :3] * 1.45 + 12, 255)
    sw[:, -3, :3] = np.minimum(sw[:, -3, :3] * 1.2 + 6, 255)
    sw = np.transpose(darken_rows(np.transpose(sw.astype(np.uint8), (1, 0, 2)), 16), (1, 0, 2))
    save(sw, TERRAIN, "stone_wall.png")

    # --- parallax -----------------------------------------------------------
    for name, out in [("ironbark_bg_sky.png", "sky.png"), ("ironbark_bg_far.png", "far.png"),
                      ("ironbark_bg_wall.png", "wall.png"), ("ironbark_fg.png", "fg.png")]:
        save(wrap_x(load(name), 48), PARALLAX, out)
    mid = wrap_x(load("ironbark_bg_mid.png"), 48)
    # dissolve the opaque top of the mid forest into the sky with a dither
    rows = 26
    for y in range(rows):
        t = (y + 0.5) / rows
        for x in range(mid.shape[1]):
            if BAYER4[y % 4, x % 4] >= t:
                mid[y, x, 3] = 0
    save(mid, PARALLAX, "mid.png")


if __name__ == "__main__":
    main()
