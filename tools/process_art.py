"""Turn generated art masters into true-scale game pixel art.

Generated sheets are soft "pixel-art-looking" paintings at an arbitrary size.
This reduces each to its intended art resolution (one art pixel = one game
pixel), averages each block, snaps colours to a small per-image palette with no
dithering, and makes alpha strictly on/off.

Usage: python3 tools/process_art.py <source_dir> <out_dir>
"""
import os
import sys

from recolor_prism import recolor

from PIL import Image

# Book ID -> (game file name, art width in game pixels, palette size)
# Height follows the source's aspect ratio.
# Sheets made before the colour fix: their purple Prism is moved to icy blue.
OLD_PRISM = {"S3", "G4"}
SPECS = {
    "IB1": ("ironbark_earth_fill", 128, 64),
    "IB2": ("ironbark_earth_edges", 384, 64),
    "IB3": ("ironbark_earth_walls_corners", 256, 64),
    "IB4": ("ironbark_islands", 384, 64),
    "IB6": ("ironbark_earth_shadow_edges", 256, 64),
    "IB5": ("ironbark_earth_faces_corners", 256, 64),
    "K1": ("keep_stone_fill", 128, 64),
    "K2": ("keep_stone_edges", 384, 64),
    "K3": ("keep_timber_kit", 384, 64),
    "K4": ("keep_stone_faces_ends", 256, 64),
    "K5": ("keep_crypt_arcade", 384, 64),
    "L6": ("landmark_bridge_bank", 256, 64),
    "CR1": ("crypt_back_wall", 384, 64),
    "CR2": ("crypt_floor_arcade", 384, 64),
    "CR3": ("crypt_walls_corners_ends", 256, 64),
    "P1": ("ironbark_bg_sky", 768, 64),
    "P2": ("ironbark_bg_far", 768, 64),
    "P3": ("ironbark_bg_mid", 768, 64),
    "P4": ("ironbark_bg_wall", 768, 64),
    "P5": ("ironbark_fg", 768, 64),
    "S1": ("landmark_great_ironbark", 256, 64),
    "S2": ("landmark_keep_gate", 256, 64),
    "S3": ("landmark_prism_shrine", 384, 64),
    "S4": ("landmark_arch_bridge", 384, 64),
    "S5": ("landmark_warden_throne", 384, 64),
    "D1": ("props_lanterns", 256, 64),
    "D2": ("props_graveyard", 256, 64),
    "D3": ("props_flora", 256, 64),
    "D4": ("props_guard_belongings", 256, 64),
    "G1": ("gate_bark_plate", 256, 64),
    "G2": ("gate_silk_and_cocoon", 256, 64),
    "G3": ("gate_thorn_knot", 128, 64),
    "G4": ("gate_prism_socket", 128, 64),
}


def process(src, width, colours, recolour_prism=False):
    im = Image.open(src).convert("RGBA")
    if recolour_prism:
        im = recolor(im)
    height = round(im.height * width / im.width)
    small = im.resize((width, height), Image.BOX)
    alpha = small.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    rgb = small.convert("RGB")
    q = rgb.quantize(colors=colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    out = q.convert("RGBA")
    out.putalpha(alpha)
    return out


def main(src_dir, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    for key, (name, width, colours) in SPECS.items():
        path = os.path.join(src_dir, key + ".png")
        if not os.path.exists(path):
            print("missing", key)
            continue
        out = process(path, width, colours, key in OLD_PRISM)
        out.save(os.path.join(out_dir, name + ".png"))
        print(f"{key:4} -> {name}.png {out.size[0]}x{out.size[1]}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
