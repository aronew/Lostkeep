"""Recolour the old amethyst Prism to the canon icy blue.

Moves strongly saturated purple pixels (the crystals) to icy blue and leaves
the low-saturation plum stone alone. Usage: recolor_prism.py <in> <out>
"""
import colorsys
import sys

from PIL import Image


def recolor(im):
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if 0.70 <= h <= 0.88 and s >= 0.42 and v >= 0.30:
                nr, ng, nb = colorsys.hsv_to_rgb(0.54, min(1, s * 0.85), min(1, v * 1.12))
                px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    return im


def main(src, dst):
    recolor(Image.open(src).convert("RGBA")).save(dst)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
