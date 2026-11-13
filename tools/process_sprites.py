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

# Sheets whose first frame is Kleo standing upright: each is scaled on its own
# so she is exactly HEIGHT px tall (the generator drew some sheets larger).
STANDING_FIRST = {
    "01_idle", "02_run", "03_start_stop_turn", "07_combo_backhand", "08_combo_forehand",
    "12_ironbark_ward", "13_anima_spark_cast", "14_anima_lance_channel", "15_emberwick",
    "19_thorn_line", "20_memory_siphon", "21_damage", "22_death", "23_heal_rest", "24_rescue_interact",
}

# file stem -> (rows, mode). mode: "ground" snaps feet to the anchor,
# "air" keeps in-cell motion, "fx" centres the effect.
SHEETS = {
    "01_idle": (3, "ground"), "02_run": (3, "ground"), "03_start_stop_turn": (3, "ground"),
    "04_jump_rise": (2, "air"), "05_fall_land": (3, "air"), "06_ledge": (3, "air"),
    "07_combo_backhand": (3, "ground"), "08_combo_forehand": (3, "ground"),
    "09_combo_overhead": (3, "ground"), "10_combo_finisher": (4, "air"),
    "11_directional_strikes": (3, "air"), "12_ironbark_ward": (3, "ground"),
    "13_anima_spark_cast": (3, "ground"), "14_anima_lance_channel": (3, "ground"),
    "15_emberwick": (2, "ground"), "16_wall": (3, "air"), "17_wing_cloak": (3, "air"),
    "18_underwater": (3, "air"), "19_thorn_line": (3, "air"), "20_memory_siphon": (2, "ground"),
    "21_damage": (2, "air"), "22_death": (4, "ground"), "23_heal_rest": (3, "ground"),
    "24_rescue_interact": (2, "ground"),
    "25_fx_slashes": (2, "fx"), "26_fx_spark": (2, "fx"), "27_fx_lance": (2, "fx"), "28_fx_small": (2, "fx"),
}


def cells(path, rows):
    im = Image.open(path).convert("RGBA")
    cw, ch = im.width / 4, im.height / rows
    for r in range(rows):
        for c in range(4):
            yield im.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch)))


def mask_bbox(im):
    a = np.asarray(im)[..., 3] > 128
    ys, xs = np.nonzero(a)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


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


def place(frame, mode, ref):
    out = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    if not np.asarray(frame)[..., 3].any():
        return out
    x0, y0, x1, y1 = mask_bbox(frame)
    if mode == "ground":
        dx, dy = ANCHOR[0] - torso_x(frame), ANCHOR[1] - y1
    elif mode == "air":
        dx, dy = ref  # one offset for the whole sheet: keeps the animator's motion
    else:
        dx, dy = CELL // 2 - (x0 + x1) // 2, CELL // 2 - (y0 + y1) // 2
    out.alpha_composite(frame, (int(dx), int(dy))) if dx >= 0 and dy >= 0 else out.paste(frame, (int(dx), int(dy)), frame)
    return out


def main(src_dir, out_dir, preview_dir=None):
    os.makedirs(out_dir, exist_ok=True)
    s = scale_of(src_dir)
    print(f"scale {s:.4f}")
    sheets = {}
    for stem, (rows, mode) in SHEETS.items():
        path = os.path.join(src_dir, stem + ".png")
        if os.path.exists(path):
            raw = list(cells(path, rows))
            k = s
            if stem in STANDING_FIRST:
                x0, y0, x1, y1 = mask_bbox(raw[0])
                k = HEIGHT / (y1 - y0)
            sheets[stem] = [shrink(f, k) for f in raw]
    pal = build_palette([f for k, fs in sheets.items() if not k.startswith("25") for f in fs])
    for stem, frames in sheets.items():
        mode = SHEETS[stem][1]
        frames = [snap(f, pal) for f in frames]
        ref = None
        if mode == "air":
            x0, y0, x1, y1 = mask_bbox(frames[0])
            ref = (ANCHOR[0] - torso_x(frames[0]), ANCHOR[1] - y1)
        placed = [place(f, mode, ref) for f in frames]
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
