"""Bring the creative lead's Shrine Hall kit (SH1 to SH8) into the game.

The sheets in art/source/ironbark/shrine_hall/ are the generator's exports at
8x (SH8 at 4x), in flat blocks. Each is reduced to game scale by sampling one
pixel per block, with nothing else done to it, and the terrain bands and
corners the skin needs are cut from SH1 and SH2 as they are.

Usage: python3 tools/make_crypt_sh.py
"""
from PIL import Image

SRC = "art/source/ironbark/shrine_hall/"
ENV = "game/assets/environment/ironbark/"
SHEETS = {
    "SH1_masonry_bands": ("sh_masonry_bands", 8),
    "SH2_wall_and_corners": ("sh_walls_corners", 8),
    "SH3_shrine_island": ("sh_shrine_island", 8),
    "SH4_platforms_and_pedestal": ("sh_platforms", 8),
    "SH5_crystals_flowers_vines": ("sh_flora", 8),
    "SH6_doorways_and_lights": ("sh_doorways", 8),
    "SH7_arcades_pillars_props": ("sh_arcades", 8),
    "SH8_distant_hall": ("sh_far", 4),
}


DARK = 40


def clear_void(path):
    im = Image.open(path).convert("RGBA")
    px = im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r, g, b, a = px[x, y]
            if a and (r + g + b) / 3 < DARK:
                px[x, y] = (0, 0, 0, 0)
    im.save(path)


def ragged_top(path, depth=10, shade=5, lit=60):
    """Break a band's top edge back along whole blocks. Per column, the lit
    bricks start at the first pixel brighter than `lit`; everything above is
    cleared, then each 8 x 4 px block is cleared a further 0 to `depth` px, and
    the bricks just below the break are shaded."""
    import random
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    def lum(c):
        return (c[0] + c[1] + c[2]) / 3 if c[3] else -1
    start = []
    for x in range(w):
        y = 0
        while y < h and lum(px[x, y]) < lit:
            y += 1
        start.append(y)
    rnd = random.Random(7)
    cut = {}
    for x in range(w):
        for y in range(h):
            if px[x, y][3] == 0:
                continue
            key = (x // 8, (y - start[x]) // 4)
            if key not in cut:
                cut[key] = rnd.choice([0, 0, 4, 4, 8, depth])
            edge = start[x] + cut[key]
            if y < edge:
                px[x, y] = (0, 0, 0, 0)
            elif y < edge + shade:
                r, g, b, a = px[x, y]
                k = 0.5 + 0.5 * (y - edge) / shade
                px[x, y] = (int(r * k), int(g * k), int(b * k), a)
    im.save(path)


def ragged_bottom(path):
    im = Image.open(path).convert("RGBA")
    im.transpose(Image.FLIP_TOP_BOTTOM).save(path)
    ragged_top(path)
    Image.open(path).transpose(Image.FLIP_TOP_BOTTOM).save(path)


def main():
    small = {}
    for name, (out, scale) in SHEETS.items():
        im = Image.open(SRC + name + ".png").convert("RGBA")
        s = im.resize((im.size[0] // scale, im.size[1] // scale), Image.NEAREST)
        s.save(ENV + out + ".png")
        small[out] = s
        print(out, s.size)
    bands = small["sh_masonry_bands"]
    bands.crop((0, 0, 384, 56)).save(ENV + "terrain/sh_top.png")      # walking line row 8
    bands.crop((0, 72, 384, 128)).save(ENV + "terrain/sh_under.png")  # ceiling line row 48
    walls = small["sh_walls_corners"]
    walls.crop((0, 0, 46, 256)).save(ENV + "terrain/sh_wall.png")     # faces right, face column 37
    walls.crop((88, 32, 152, 96)).save(ENV + "terrain/sh_corner_top.png")      # anchor (36, 29)
    walls.crop((176, 32, 240, 96)).save(ENV + "terrain/sh_corner_under.png")   # anchor (42, 42)
    # The bands were painted ending in the void. In the crypts the creative lead's
    # mockup fills each mass with masonry instead, so the void is cut away along
    # the blocks' own outlines (every pixel darker than DARK becomes clear) and
    # the fill below shows through.
    for name in ("sh_top", "sh_under", "sh_wall"):
        clear_void(ENV + "terrain/" + name + ".png")
    # The ceiling band's lit bricks began along one straight course, a hard line
    # against the fill above (the creative lead: "a hard cut line, not blending
    # into the shadow or the stone above"). Its top edge is broken back by
    # whole blocks (8 x 4 px) by a varying depth, and the bricks just below the
    # break are shaded, so it steps into the shadow as the floor band does.
    ragged_top(ENV + "terrain/sh_under.png")
    # The floor band's dark tail ended in a straight row where a thin slab's
    # floor met its ceiling. Its lit bricks are broken off below the same way.
    ragged_bottom(ENV + "terrain/sh_top.png")
    # The fill: SH1's lit blocks (floor band rows 11 to 34), stacked with a
    # half-width offset so the courses don't line up, darkened toward reference
    # Y's plum-grey masonry under the lit rim (about #2F283D on screen).
    # (Only the evenly lit courses, rows 13 to 28: above is the carved cap row, below the band darkens,
    # and a fill cut deeper carried that dark stripe into every repeat.)
    blocks = bands.crop((0, 13, 384, 29))
    fill = Image.new("RGBA", (384, 32))
    fill.paste(blocks, (0, 0))
    fill.paste(blocks.crop((192, 0, 384, 16)), (0, 16))
    fill.paste(blocks.crop((0, 0, 192, 16)), (192, 16))
    px = fill.load()
    for y in range(32):
        for x in range(384):
            r, g, b, a = px[x, y]
            px[x, y] = (int(r * 0.63), int(g * 0.56), int(b * 0.68), 255)
    fill.save(ENV + "terrain/sh_fill.png")
    print("terrain: sh_top (line 8), sh_under (line 48), sh_wall (face 37), corners, sh_fill")


if __name__ == "__main__":
    main()
