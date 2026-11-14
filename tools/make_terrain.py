"""Cut the processed Ironbark sheets into seamless, game-ready textures.

Generated bands rarely tile cleanly, so each texture is made seamless with a
minimum-error cut at its wrap (or cut at a whole number of repeats for regular
patterns), keeping every pixel crisp. The inside of each mass is painted black,
so every band ends in the void along its own stones (a "crust"), never along a
straight line, and wall faces stand a few pixels proud of the collision.
Output: game/assets/environment/ironbark/terrain/ and .../parallax/.

Usage: python3 tools/make_terrain.py
"""
import json
import os
from collections import deque

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
# the shadow). A band never ends in a straight line or an even fade against the
# black: it ends the way a crust does, along the outlines of its own stones.
# Only walking lines are straight; wall faces stand a few pixels proud of the
# collision in uneven runs.
CRUST_MIN = 9   # px of a band always kept behind its edge
CRUST_LIT = 8   # px of it at full light; deeper, it steps down into shadow
CRUST_MAX = 22  # deepest its stones reach into the void
OVER = 4        # px a wall face may stand out past the collision line


def lum(rgb):
    rgb = rgb.astype(float)
    return rgb[..., 0] * 0.3 + rgb[..., 1] * 0.59 + rgb[..., 2] * 0.11


def wobble(w, seed, base, spread):
    """A smooth, wrapping per-column offset in whole pixels (whole periods across w)."""
    rng = np.random.default_rng(seed)
    xs = np.arange(w)
    v = np.zeros(w)
    for k, amp in ((max(1, w // 60), 1.0), (max(1, w // 23), 0.7), (max(1, w // 9), 0.4)):
        v += amp * np.sin(2 * np.pi * k * xs / w + rng.uniform(0, 6.3))
    v = v / 2.1  # roughly -1..1
    return np.round(base + spread * v).astype(int)


def flood(keep, cand):
    """Grow `keep` through 4-connected `cand` pixels. Runs over three copies side by
    side and keeps the middle one, so a band that wraps stays seamless."""
    h, w = keep.shape
    K = np.concatenate([keep] * 3, axis=1)
    C = np.concatenate([cand] * 3, axis=1)
    q = deque(zip(*np.nonzero(K)))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (0, 1), (0, -1), (-1, 0)):
            yy, xx = y + dy, x + dx
            if 0 <= yy < h and 0 <= xx < 3 * w and C[yy, xx] and not K[yy, xx]:
                K[yy, xx] = True
                q.append((yy, xx))
    return K[:, w:2 * w]


def shade_edge(out, keep, rows):
    """Darken kept pixels that border the void, within `rows`: a stone's underside
    (open below) most, its sides less, so each stone reads as a solid shape."""
    h, w = keep.shape
    below = np.zeros_like(keep)
    below[:-1] = ~keep[1:]
    below[-1] = True
    side = ~np.roll(keep, 1, axis=1) | ~np.roll(keep, -1, axis=1)
    zone = np.zeros_like(keep)
    zone[rows] = True
    under = keep & below & zone
    sides = keep & side & zone & ~under
    rgb = out[..., :3].astype(float)
    rgb[under] = rgb[under] * 0.45 + VOID[:3] * 0.55
    rgb[sides] = rgb[sides] * 0.7 + VOID[:3] * 0.3
    # the pixel above an underside gets a softer step
    above = np.zeros_like(keep)
    above[:-1] = under[1:]
    above &= keep & zone & ~under & ~sides
    rgb[above] = rgb[above] * 0.75 + VOID[:3] * 0.25
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)


def crust(a, start, seed, dmin=CRUST_MIN, dmax=CRUST_MAX, pct=30):
    """End a band in the void along its stones. The band's edge (a walking line, a
    face or a ceiling) is row `start`, and depth grows downward. Everything above
    `start` is kept; a few rows below it always are (their count wanders column to
    column); deeper, only stone pixels (lighter than the soil around them) joined
    to what is kept reach on, to `dmax` at most. The rest becomes transparent, so
    the void shows. Each stone gets a shaded underside."""
    a = a[: start + dmax].copy()
    h, w, _ = a.shape
    L = lum(a[..., :3])
    solid = a[..., 3] > 0
    zone = L[start:][solid[start:]]
    thr = np.percentile(zone, pct) if zone.size else 0
    keep = np.zeros((h, w), bool)
    keep[:start] = solid[:start]
    depth = np.clip(wobble(w, seed, dmin + 1, 3), 2, dmax)
    for x in range(w):
        keep[start:start + depth[x], x] = solid[start:start + depth[x], x]
    cand = solid & (L >= thr)
    cand[:start] = False
    keep = flood(keep, cand)
    # Fill pinholes: a dropped pixel mostly surrounded by kept ones is kept.
    for _ in range(2):
        n = (np.roll(keep, 1, 0).astype(int) + np.roll(keep, -1, 0) + np.roll(keep, 1, 1) + np.roll(keep, -1, 1))
        hole = ~keep & (n >= 3) & solid
        hole[:start] = False
        keep |= hole
    # Drop one-pixel whiskers: deep pixels with fewer than two kept neighbours.
    for _ in range(2):
        n = (np.roll(keep, 1, 0).astype(int) + np.roll(keep, -1, 0) + np.roll(keep, 1, 1) + np.roll(keep, -1, 1))
        deep = np.zeros_like(keep)
        for x in range(w):
            deep[start + depth[x]:, x] = True
        keep &= ~(deep & (n < 2))
    out = a.copy()
    out[~keep, 3] = 0
    shade_edge(out, keep, slice(start, h))
    # Into shadow, like the walls: lit for CRUST_LIT rows under the edge, then
    # stepping toward the void, so the deepest stones are only just visible.
    rgb = out[..., :3].astype(float)
    span = max(1, h - start - CRUST_LIT)
    for y in range(start + CRUST_LIT, h):
        t = (y - start - CRUST_LIT + 1) / span
        k = 1 - (np.floor(t * 4 - 1e-6) + 1) / 4 * 0.9
        rgb[y] = rgb[y] * k + VOID[:3] * (1 - k)
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return out


def proud(a, start, seed):
    """A face standing proud of the collision: rows above `start` (the air side,
    OVER rows) keep a pixel only where a stone stands out there, in uneven runs.
    The outermost pixel of each run is darkened, a selective outline."""
    h, w, _ = a.shape
    L = lum(a[..., :3])
    thr = np.percentile(L[start:start + 6][a[start:start + 6, :, 3] > 0], 45)
    reach = np.clip(wobble(w, seed + 1, OVER * 0.5, OVER * 0.9), 0, OVER)
    # Stones at the face stand further out, in runs of at least a few pixels.
    stone = (L[start:start + 3] >= thr).mean(0) > 0.5
    run = np.convolve(np.concatenate([stone[-3:], stone, stone[:3]]).astype(float), np.ones(7) / 7, "same")[3:-3] > 0.5
    reach = np.where(run, reach, np.minimum(reach, 1))
    # Never step more than one pixel between neighbours: a worn edge, not teeth.
    for _ in range(OVER):
        reach = np.minimum(reach, np.minimum(np.roll(reach, 1), np.roll(reach, -1)) + 1)
    out = a.copy()
    for x in range(w):
        out[: start - reach[x], x, 3] = 0
        if reach[x] > 0:
            y = start - reach[x]
            out[y, x, :3] = (out[y, x, :3] * 0.55 + VOID[:3] * 0.45).astype(np.uint8)
    return out


def degreen(a):
    """Replace foliage (green-dominant pixels) with soil from elsewhere in the same
    row, so a vine leaves no smear (the band wraps, so the row does too)."""
    out = a.copy()
    rgb = a[..., :3].astype(int)
    green = rgb[..., 1] >= rgb[..., 0] - 2  # soil is purple-brown: red well above green
    h, w = green.shape
    offsets = [d * s for d in (37, 59, 83, 101, 127, 149) for s in (1, -1)]
    for y in range(h):
        for x in np.nonzero(green[y])[0]:
            for d in offsets:
                xx = (x + d) % w
                if not green[y, xx]:
                    out[y, x] = a[y, xx]
                    break
    return out


def face_band(rows, seed):
    """A wall band from face-up rows (OVER rows of air side, then the face, then
    depth): proud stones on the air side, a crust into the void behind, then
    turned so the face points right. Column `width - 1 - OVER` is the face."""
    a = crust(rows, OVER, seed)
    a = proud(a, OVER, seed)
    return np.transpose(a, (1, 0, 2))[:, ::-1].copy()


# --- The edge kits (IB5 earth, K4 masonry) ----------------------------------------------
# Painted pieces: a face band and corners. Their painted void becomes transparent
# (the game paints the void), and each corner is measured for its anchor: the
# point where its walking line (or ceiling line) meets its face.

def clear_void(a):
    out = a.copy()
    rgb = a[..., :3].astype(int)
    dark = (rgb.max(2) < 30) & (lum(rgb) < 18)
    out[dark, 3] = 0
    return out


def pieces(a, gap=3):
    """Bounding boxes of the separate pieces on a sheet, top to bottom, left to right."""
    op = a[..., 3] > 0
    d = op.copy()
    for _ in range(gap):
        d = d | np.roll(d, 1, 0) | np.roll(d, -1, 0) | np.roll(d, 1, 1) | np.roll(d, -1, 1)
    seen = np.zeros_like(d)
    h, w = d.shape
    out = []
    for y0, x0 in zip(*np.nonzero(d)):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        ys, xs = [y0], [x0]
        while q:
            y, x = q.popleft()
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and d[yy, xx] and not seen[yy, xx]:
                    seen[yy, xx] = True
                    q.append((yy, xx))
                    ys.append(yy)
                    xs.append(xx)
        sub = op[min(ys):max(ys) + 1, min(xs):max(xs) + 1]
        if sub.sum() > 300:
            yy, xx = np.nonzero(sub)
            out.append((min(xs) + xx.min(), min(ys) + yy.min(), xx.max() + 1 + min(xs), yy.max() + 1 + min(ys)))
    out.sort(key=lambda b: (b[1] // 40, b[0]))
    return out


def crop(a, box):
    x0, y0, x1, y1 = box
    return a[y0:y1, x0:x1].copy()


def right_edge(a, rows, pct=50):
    """A percentile of the rightmost solid column over `rows`: where a face runs."""
    xs = [np.nonzero(a[y, :, 3] > 0)[0].max() for y in rows if (a[y, :, 3] > 0).any()]
    return int(np.percentile(xs, pct))


WALL_LIT = 12   # px of a wall's face at full light, inward from the wall line
WALL_SHADE = 12  # px over which it then steps down into the void, like a shadow


def shadow_face(band, face):
    """A wall band that goes into shadow: solid from the wall line inward (no gaps
    for the black box to show through), WALL_LIT px lit, then WALL_SHADE px
    stepping down to the void colour, its last columns the void itself. Only the
    stones standing proud past the wall line keep their own outline. The face
    points right; returns the band and its new face column."""
    depth = WALL_LIT + WALL_SHADE
    band = band[:, max(0, face + 1 - depth):].copy()
    face = depth - 1 if band.shape[1] > depth else band.shape[1] - 1
    h, w, _ = band.shape
    # Fill the gaps inside the wall line with the nearest stone in the row, shaded,
    # as mortar joints and recesses read.
    for y in range(h):
        op = band[y, : face + 1, 3] > 0
        xs = np.nonzero(op)[0]
        if not len(xs):
            band[y, : face + 1, :3] = VOID[:3]
            band[y, : face + 1, 3] = 255
            continue
        for x in np.nonzero(~op)[0]:
            n = xs[np.argmin(np.abs(xs - x))]
            band[y, x, :3] = (band[y, n, :3].astype(float) * 0.6 + VOID[:3] * 0.4).astype(np.uint8)
            band[y, x, 3] = 255
    # The shadow: stepped bands from lit to the void, over WALL_SHADE columns.
    out = band.astype(float)
    for i in range(WALL_SHADE):
        k = np.floor(i / WALL_SHADE * 4) / 4  # 0 at the inner end (void) .. 0.75 near the lit part
        out[:, i, :3] = out[:, i, :3] * k + VOID[:3] * (1 - k)
    return out.astype(np.uint8), face


def shadow_corner(c, anchor, top):
    """A corner piece going into shadow like the bands: a pixel inside the mass
    (inward of the face and below the walking line, or above the ceiling line) is
    lit within WALL_LIT px of the nearer open edge, then steps down to the void
    over WALL_SHADE px; past that it is cut, so the void fill shows. Pixels outside
    the mass (moss over the edge, an arch hanging below a ceiling) are kept."""
    ax, ay = anchor
    h, w, _ = c.shape
    out = c.astype(float)
    for y in range(h):
        into_line = (y - ay) if top else (ay - y)  # distance into the mass from the line
        for x in range(w):
            into_face = ax - x
            if into_line < 0 or into_face < 0 or out[y, x, 3] == 0:
                continue
            d = min(into_line, into_face)
            if d < WALL_LIT:
                continue
            t = (d - WALL_LIT) / WALL_SHADE
            if t >= 1:
                out[y, x, 3] = 0
                continue
            k = 1 - (np.floor(t * 4) + 1) / 4 * 0.85
            out[y, x, :3] = out[y, x, :3] * k + VOID[:3] * (1 - k)
    return out.astype(np.uint8)


def kit_face(a, box, trim, crust_depth=None):
    """A wall band from a kit's face band (face pointing right), trimmed of its end
    caps, going into shadow (shadow_face), seamless top to bottom. Returns the band
    and its face column (stones beyond it stand proud)."""
    band = crop(a, box)[trim[0]: -trim[1] or None]
    # The face line sits where most of the edge runs, so only the proudest stones
    # (up to about 6 px) stand past the collision.
    face = right_edge(band, range(band.shape[0]), pct=70) - 1
    band, face = shadow_face(band, face)
    band = wrap_y(band, 32)
    return band, face


def walking_line(a, frac=0.85):
    """First row, from the top, solid across most of the piece's inner 60%."""
    w = a.shape[1]
    x0, x1 = int(w * 0.1), int(w * 0.6)
    for y in range(a.shape[0]):
        if (a[y, x0:x1, 3] > 0).mean() >= frac:
            return y
    return 0


def ceiling_line(a, frac=0.6):
    """Last row, from the bottom, solid across most of the piece's inner 60%."""
    w = a.shape[1]
    x0, x1 = int(w * 0.1), int(w * 0.6)
    for y in range(a.shape[0] - 1, -1, -1):
        if (a[y, x0:x1, 3] > 0).mean() >= frac:
            return y + 1
    return a.shape[0]


def kit_corner(a, box, kind):
    """Cut a corner and measure its anchor (face column, line row)."""
    c = crop(a, box)
    h = c.shape[0]
    if kind == "top":
        line = walking_line(c)
        face = right_edge(c, range(min(h - 1, line + 12), max(line + 13, h - 6))) - 2
    else:
        line = ceiling_line(c)
        face = right_edge(c, range(4, max(5, line - 10))) - 2
    return shadow_corner(c, (face, line), kind == "top"), (face, line)


CRYPT_HANG = 80  # a crypt is five tiles tall: arcade piers stand on its floor
# The painted crypt kit (CR1 to CR3) in place of K2, K4 and K5 in the crypts.
# Off until the creative lead picks: as painted, or tinted toward the region's
# plum (CRYPT_TINT multiplies red, green, blue; None keeps the paint as it is).
USE_CRYPT_KIT = False
CRYPT_TINT = (1.02, 0.93, 1.12)


def darken_from(a, row, step=0.72):
    """One value step darker from `row` down (a pier's shaft and plinth), so the
    piers sit back against the crypt wall while the arches and course stay lit."""
    out = a.astype(float)
    for y in range(row, a.shape[0]):
        k = 0.86 if y < row + 2 else step
        m = out[y, :, 3] > 0
        out[y, m, :3] = out[y, m, :3] * k + VOID[:3] * (1 - k)
    return out.astype(np.uint8)


def arcade():
    """K5, the crypt arcade: cut pier centre to pier centre (three arches every
    360 px) so it repeats, its ceiling line placed so the piers' plinth stands on
    the floor of a five-tile crypt. Returns the ceiling line row."""
    a = wrap_period(load("keep_crypt_arcade.png"), 120, 3)
    # Measured on the processed sheet: the imposts end at row 94; below them run
    # the pier shafts and the plinth.
    a = darken_from(a, 94)
    save(a, TERRAIN, "stone_under.png")
    line = a.shape[0] - CRYPT_HANG
    print("  stone under ceiling line row", line, "(the crowns are at row 54)")
    return line


def crypt_kit():
    """The crypt kit (CR1 to CR3, painted together): the stone floor, the ceiling's
    arcade, the wall band, the outer top corner, the arcade's open end and the back
    wall. Measured on the processed sheets (game pixels). Returns anchors."""
    def tinted(a):
        if not CRYPT_TINT:
            return a
        out = a.astype(float)
        out[..., :3] *= np.array(CRYPT_TINT)
        return np.clip(out, 0, 255).astype(np.uint8)
    cr1 = tinted(load("crypt_back_wall.png"))
    cr2 = tinted(load("crypt_floor_arcade.png"))
    cr3 = clear_void(tinted(load("crypt_walls_corners_ends.png")))
    anchors = {}
    # The floor: walking line at row 8, its underside painted into shadow.
    save(wrap_x(cr2[0:34], 24), TERRAIN, "stone_top.png")
    anchors["stone_top_line"] = 8
    # The arcade: rows 63..190, pier feet at row 190. Its piers stand on the crypt
    # floor (CRYPT_HANG below the ceiling line), so the crowns (row 89) rise 21 px
    # into the dark slab, as the vault's shadow.
    band = wrap_x(cr2[63:190], 24)
    save(band, TERRAIN, "stone_under.png")
    anchors["stone_under_line"] = band.shape[0] - CRYPT_HANG
    # The wall band (face pointing right), its painted shadow kept as it is.
    wall = cr3[3:252, 4:64]
    op = wall[..., 3] > 0
    edge = [np.nonzero(op[y])[0].max() for y in range(wall.shape[0]) if op[y].any()]
    face = int(np.percentile(edge, 50)) - 1
    save(wrap_y(wall, 24), TERRAIN, "stone_wall.png")
    anchors["stone_wall_face"] = face
    # The outer top corner (the floor turning down into a face on its right).
    c, anc = kit_corner(cr3, (71, 12, 149, 71), "top")
    save(c, TERRAIN, "stone_corner_top.png")
    anchors["stone_corner_top"] = anc
    # The arcade's open end (a full pier, its right side to open air), standing on
    # the floor like the band.
    c = crop(cr3, (156, 139, 223, 249))
    h = c.shape[0]
    foot = max(np.nonzero(c[:, x, 3] > 0)[0].max() for x in range(c.shape[1]) if (c[:, x, 3] > 0).any()) + 1
    efface = right_edge(c, range(foot - 40, foot - 12), pct=60) - 1
    save(c, TERRAIN, "stone_corner_under.png")
    anchors["stone_corner_under"] = (efface, foot - CRYPT_HANG)
    anchors["stone_corner_under_reach"] = CRYPT_HANG
    # The back wall: the niche storey (rows 38..118, its plinth on the floor line)
    # as the course, the coursed wall above it as the fill. The two lantern
    # brackets are patched out with the wall beside them (the game hangs its own).
    wall = cr1.copy()
    for x0, x1 in ((88, 116), (281, 308)):
        wall[0:50, x0:x1] = cr1[0:50, x0 - 40:x1 - 40]
    save(wall[38:118], TERRAIN, "stone_course.png")
    save(wrap_y(wall[0:48], 8), TERRAIN, "stone_fill.png")
    anchors["back_course_height"] = 0
    anchors["back_brightness"] = 0.6
    print("  crypt kit: floor line 8, arcade line", anchors["stone_under_line"], "wall face", face,
          "corner", anc, "open end", anchors["stone_corner_under"])
    return anchors


def kits():
    """Cut the kits and write their measurements to kit_anchors.json, which the
    room builder reads: face columns, and each corner's (face, line) anchor."""
    anchors = {}
    ib5 = clear_void(load("ironbark_earth_faces_corners.png"))
    b = pieces(ib5)
    print("  IB5 pieces", b)
    face_box = max(b, key=lambda r: r[3] - r[1])  # the tall face band
    band, face = kit_face(ib5, face_box, (20, 6))
    save(band, TERRAIN, "earth_wall.png")
    print("  earth wall face column", face)
    anchors["earth_wall_face"] = face
    rest = [r for r in b if r != face_box]
    corners = sorted([r for r in rest if r[1] < 180], key=lambda r: (r[1] // 40, r[0]))
    # Book order: a outer top, b inner floor, c outer ceiling, d inner ceiling.
    for name, box, kind in (("earth_corner_top", corners[0], "top"), ("earth_corner_under", corners[2], "under")):
        c, anc = kit_corner(ib5, box, kind)
        save(c, TERRAIN, name + ".png")
        anchors[name] = anc
        print(f"  {name} anchor (face, line) {anc} size {c.shape[1]}x{c.shape[0]}")

    k4 = clear_void(load("keep_stone_faces_ends.png"))
    b = pieces(k4)
    print("  K4 pieces", b)
    face_box = max(b, key=lambda r: r[3] - r[1])
    band, face = kit_face(k4, face_box, (24, 16))
    save(band, TERRAIN, "stone_wall.png")
    print("  stone wall face column", face)
    anchors["stone_wall_face"] = face
    low = sorted([r for r in b if r != face_box and r[1] > 120], key=lambda r: r[0])
    c, anc = kit_corner(k4, low[0], "top")
    save(c, TERRAIN, "stone_corner_top.png")
    anchors["stone_corner_top"] = anc
    print(f"  stone_corner_top anchor (face, line) {anc} size {c.shape[1]}x{c.shape[0]}")
    # The arcade's end against a wall: K4's arch end whose pier stands on the right
    # (the arcade runs off to the left). Its ceiling line is the crown of the arch
    # opening, as in K2's arcade; its face is the pier's outer side.
    ends = sorted([r for r in b if r != face_box and r[1] < 120], key=lambda r: r[0])
    c = crop(k4, ends[0])
    op = c[..., 3] > 0
    h, w = op.shape
    # Its ceiling line is where the course under the arcade leaves the piece on its
    # left (the lowest solid row of its first columns); its face is the pier's
    # outer side. The pier reaches down to the floor of a five-tile crypt.
    crown = max(np.nonzero(op[:, x])[0].max() for x in range(0, 6) if op[:, x].any()) + 1
    face = right_edge(c, range(h * 3 // 4, h), pct=60) - 1
    # Like K5's piers, this one stands on the floor of a five-tile crypt, and its
    # shaft below the impost (row 79, measured) sits one value step back.
    crown = h - CRYPT_HANG
    c = darken_from(c, 79)
    c = shadow_corner(c, (face, crown), False)
    save(c, TERRAIN, "stone_corner_under.png")
    anchors["stone_corner_under"] = (face, crown)
    anchors["stone_corner_under_reach"] = CRYPT_HANG
    print(f"  stone_corner_under anchor (face, line) {(face, crown)} size {w}x{h}")
    anchors["stone_under_line"] = arcade()
    if USE_CRYPT_KIT and os.path.exists(os.path.join(SRC, "crypt_floor_arcade.png")):
        anchors.update(crypt_kit())  # the crypt kit replaces K2, K4 and K5 in the crypts
    clean = {k: ([int(v) for v in a] if isinstance(a, tuple) else (float(a) if isinstance(a, float) else int(a)))
             for k, a in anchors.items()}
    with open(os.path.join(TERRAIN, "kit_anchors.json"), "w") as f:
        json.dump(clean, f, indent=1)
    return anchors


def main():
    # --- earth -------------------------------------------------------------
    edges = load("ironbark_earth_edges.png")
    top = edges[0:62]
    line = first_full_row(top, 0, 0.97)
    save(crust(wrap_x(top, 32), line, seed=1), TERRAIN, "earth_top.png")
    print("  earth top walking line row", line)

    under = edges[74:127, 58:382]
    # ceiling line: the last row that is still (nearly) full width
    full = [(under[y, :, 3] > 0).mean() for y in range(under.shape[0])]
    ceil_line = max(y for y, f in enumerate(full) if f > 0.97) + 1
    # Flipped, the ceiling becomes a walking line: crust it the same way, flip back.
    flipped = wrap_x(under, 32)[::-1]
    hang = flipped.shape[0] - ceil_line
    under = crust(flipped, hang, seed=2)[::-1].copy()
    save(under, TERRAIN, "earth_under.png")
    print("  earth under ceiling line row", under.shape[0] - hang)

    # The wall: the floor's own soil turned on its side, so a cut face (the drop,
    # a shaft, a pier) is the same earth as the ground above it. (IB3's wall band
    # grows ferns and mushrooms out of the rock, which reads as leafy clutter on
    # short faces.) The soil starts under the grass, with the vines that hang
    # into it replaced by the soil beneath them, so no leaf lies sideways.
    # Built face-up (the air side on top, OVER rows of it), then turned so the face
    # points right with its proud stones beyond the face column.
    # (Replaced by IB5's painted face band in kits(); kept as the fallback.)
    soil_rows = degreen(wrap_x(top, 32)[line + 10 - OVER: line + 10 + CRUST_MAX + 2])
    wall = face_band(soil_rows, seed=3)
    save(wall, TERRAIN, "earth_wall.png")  # already seamless: it is the wrapped top band

    fill = load("ironbark_earth_fill.png")
    save(wrap_y(wrap_x(fill, 16), 16), TERRAIN, "earth_fill.png")

    # --- stone (the Lost Keep's crypts) -----------------------------------------
    k2 = load("keep_stone_edges.png")
    stop = k2[12:59]
    sline = first_full_row(stop, 0, 0.97)
    save(crust(wrap_x(stop, 32), sline, seed=4), TERRAIN, "stone_top.png")
    print("  stone top walking line row", sline)
    # (The crypt arcade is K5 now: see arcade().)
    course = k2[134:184]
    save(wrap_period(course, 148, 2), TERRAIN, "stone_course.png")  # the carved panels every 148 px
    k1 = load("keep_stone_fill.png")
    sfill = wrap_y(wrap_x(k1, 16), 16)
    save(sfill, TERRAIN, "stone_fill.png")
    # stone wall fallback: the fill's own stones (replaced by K4's in kits())
    sw = face_band(sfill[: OVER + CRUST_MAX + 2].copy(), seed=6)
    save(sw, TERRAIN, "stone_wall.png")

    # --- the painted edge kits ------------------------------------------------
    kits()

    # --- parallax -----------------------------------------------------------
    for name, out in [("ironbark_bg_sky.png", "sky.png"), ("ironbark_bg_far.png", "far.png"),
                      ("ironbark_bg_wall.png", "wall.png"), ("ironbark_fg.png", "fg.png")]:
        save(wrap_x(load(name), 48), PARALLAX, out)
    # P3 v2 has whole crowns on a transparent sky: it only needs its wrap.
    mid = wrap_x(load("ironbark_bg_mid.png"), 48)
    for name, img in [("far", load("ironbark_bg_far.png")), ("mid", mid)]:
        bottom = img[-6:, :, :3].reshape(-1, 3).mean(0)
        print(f"  {name} base colour #{int(bottom[0]):02x}{int(bottom[1]):02x}{int(bottom[2]):02x}")
    save(mid, PARALLAX, "mid.png")


if __name__ == "__main__":
    main()
