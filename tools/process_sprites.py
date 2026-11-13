"""Turn Kleo's generated animation sheets into game-scale sprite strips.

Each source sheet is a 4-column grid (rows per sheet below). Every frame is
cut out, scaled so Kleo stands 28 px tall, snapped to one shared palette (so
every animation uses identical colours), given hard alpha, and placed in a
64 × 64 cell. Grounded animations have each frame's feet snapped to the anchor
(x 32, y 56); airborne ones keep the animator's motion inside the cell.

Output per sheet: <name>.png, a horizontal strip of 64 × 64 frames.
Usage: python3 tools/process_sprites.py <source_dir> <out_dir> [preview_dir]
"""
import os
import sys

import numpy as np
from PIL import Image

CELL = 64
ANCHOR = (32, 56)
HEIGHT = 28  # Kleo standing, boot soles to the top of her head

# Every character sheet is scaled so Kleo's hair covers the same area as in
# the idle sheet: the generator draws sheets at different sizes, and hair area
# stays steady across poses (height does not). STANDING_FIRST is kept for
# reference: these sheets open with her standing upright.
STANDING_FIRST = {
    "01_idle", "01b_idle_long", "02_run", "03_start_stop_turn", "07_combo_backhand", "08_combo_forehand",
    "12_ironbark_ward", "13_anima_spark_cast", "14_anima_lance_channel", "15_emberwick",
    "19_thorn_line", "20_memory_siphon", "21_damage", "22_death", "23_heal_rest", "24_rescue_interact",
}

# Sheets where only the first N frames are used (the sap-gum bubble scene in
# 01b_idle_long was cut: the bubble grew bigger than her head).
KEEP = {"01b_idle_long": 8}

# file stem -> (rows, mode). mode: "ground" snaps feet to the anchor,
# "air" keeps in-cell motion, "fx" centres the effect.
SHEETS = {
    "01_idle": (3, "ground"), "01b_idle_long": (4, "ground"), "02_run": (3, "ground"), "03_start_stop_turn": (3, "ground"),
    "04_jump_rise": (2, "air"), "05_fall_land": (3, "air"), "06_ledge": (4, "ledge"),
    "07_combo_backhand": (3, "ground"), "08_combo_forehand": (3, "ground"),
    "09_combo_overhead": (3, "ground"), "10_combo_finisher": (4, "air"),
    "11_directional_strikes": (3, "air"), "12_ironbark_ward": (3, "ground"),
    "13_anima_spark_cast": (3, "ground"), "14_anima_lance_channel": (3, "ground"),
    "15_emberwick": (2, "ground"), "16_wall": (3, "air"), "17_wing_cloak": (3, "air"),
    "18_underwater": (3, "air"), "19_thorn_line": (3, "air"), "20_memory_siphon": (2, "ground"),
    "21_damage": (4, "air"), "22_death": (4, "ground"), "23_heal_rest": (3, "ground"),
    "24_rescue_interact": (2, "ground"),
    "25_fx_slashes": (2, "fx"), "26_fx_spark": (2, "fx"), "27_fx_lance": (2, "fx"), "28_fx_small": (2, "fx"),
}


def drop_key_green(im):
    """Remove the flat key-green (#00FF00) wall and ledge guides."""
    a = np.asarray(im).copy()
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    a[(g > 180) & (r < 110) & (b < 110)] = 0
    return Image.fromarray(a, "RGBA")


def cells(path, rows):
    im = drop_key_green(Image.open(path).convert("RGBA"))
    cw, ch = im.width / 4, im.height / rows
    for r in range(rows):
        for c in range(4):
            yield im.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch)))


def mask_bbox(im):
    a = np.asarray(im)[..., 3] > 128
    ys, xs = np.nonzero(a)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def hair_area(frame):
    """Pixels of Kleo's navy hair: it is about the same size in every pose."""
    a = np.asarray(frame).astype(int)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    return int(((al > 128) & (b > r + 25) & (b > g + 15) & (b < 190) & (r < 90)).sum())


def sheet_scale(raw, ref_area, ref_scale):
    """Scale a sheet so her hair has the same area as in the idle sheet."""
    areas = sorted(hair_area(f) for f in raw)
    med = areas[len(areas) // 2]
    return ref_scale * (ref_area / med) ** 0.5


def scale_of(src_dir):
    first = next(cells(os.path.join(src_dir, "01_idle.png"), 3))
    x0, y0, x1, y1 = mask_bbox(first)
    return HEIGHT / (y1 - y0)


def shrink(frame, s):
    w, h = max(1, round(frame.width * s)), max(1, round(frame.height * s))
    small = frame.resize((w, h), Image.BOX)
    arr = np.asarray(small).copy()
    arr[..., 3] = np.where(arr[..., 3] >= 128, 255, 0)
    return Image.fromarray(arr, "RGBA")


def build_palette(frames):
    strip = Image.new("RGB", (sum(f.width for f in frames), max(f.height for f in frames)))
    x = 0
    for f in frames:
        strip.paste(f.convert("RGB"), (x, 0), f)
        x += f.width
    return strip.quantize(colors=64, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


def snap(frame, pal):
    q = frame.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGBA")
    q.putalpha(frame.getchannel("A"))
    return q


def torso_x(frame):
    """Horizontal centre of the upper body, so swords and capes don't pull it."""
    a = np.asarray(frame)[..., 3] > 0
    ys, xs = np.nonzero(a)
    top, bottom = ys.min(), ys.max()
    band = (ys >= top) & (ys <= top + (bottom - top) * 0.7)
    return int(np.median(xs[band]))


def place(frame, mode, ref, index=0):
    out = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    if not np.asarray(frame)[..., 3].any():
        return out
    x0, y0, x1, y1 = mask_bbox(frame)
    if mode == "ledge" and index < 7:
        # hanging: her hands (the top of her) grip the ledge corner at y 6
        dx, dy = ANCHOR[0] - torso_x(frame), 6 - y0
    elif mode in ("ground", "ledge"):
        # on top of the ledge, whatever touches it (feet or hands) is on the anchor
        dx, dy = ANCHOR[0] - torso_x(frame), ANCHOR[1] - y1
    elif mode == "air":
        dx, dy = ref  # one offset for the whole sheet: keeps the animator's motion
    else:
        dx, dy = CELL // 2 - (x0 + x1) // 2, CELL // 2 - (y0 + y1) // 2
    out.paste(frame, (int(dx), int(dy)), frame)
    return out


def main(src_dir, out_dir, preview_dir=None):
    os.makedirs(out_dir, exist_ok=True)
    s = scale_of(src_dir)
    print(f"scale {s:.4f}")
    idle = list(cells(os.path.join(src_dir, "01_idle.png"), 3))
    idle_areas = sorted(hair_area(f) for f in idle)
    ref_area = idle_areas[len(idle_areas) // 2]
    sheets = {}
    for stem, (rows, mode) in SHEETS.items():
        path = os.path.join(src_dir, stem + ".png")
        if os.path.exists(path):
            raw = list(cells(path, rows))[:KEEP.get(stem)]
            k = s if mode == "fx" else sheet_scale(raw, ref_area, s)
            sheets[stem] = [shrink(f, k) for f in raw]
    pal = build_palette([f for k, fs in sheets.items() if not k.startswith("25") for f in fs])
    for stem, frames in sheets.items():
        mode = SHEETS[stem][1]
        frames = [snap(f, pal) for f in frames]
        ref = None
        if mode == "air":
            x0, y0, x1, y1 = mask_bbox(frames[0])
            ref = (ANCHOR[0] - torso_x(frames[0]), ANCHOR[1] - y1)
        placed = [place(f, mode, ref, i) for i, f in enumerate(frames)]
        strip = Image.new("RGBA", (CELL * len(placed), CELL), (0, 0, 0, 0))
        for i, f in enumerate(placed):
            strip.alpha_composite(f, (i * CELL, 0))
        name = stem.split("_", 1)[1]
        strip.save(os.path.join(out_dir, name + ".png"))
        if preview_dir:
            os.makedirs(preview_dir, exist_ok=True)
            big = [f.resize((CELL * 4, CELL * 4), Image.NEAREST) for f in placed]
            bg = [Image.alpha_composite(Image.new("RGBA", b.size, (36, 30, 48, 255)), b).convert("RGB") for b in big]
            bg[0].save(os.path.join(preview_dir, name + ".gif"), save_all=True, append_images=bg[1:], duration=1000 // 12, loop=0)
        print(f"{stem}: {len(placed)} frames")


if __name__ == "__main__":
    main(*sys.argv[1:])
