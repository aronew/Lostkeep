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
    Image.new("RGBA", (16, 16), (11, 8, 18, 255)).save(ENV + "terrain/sh_fill.png")
    print("terrain: sh_top (line 8), sh_under (line 48), sh_wall (face 37), corners, sh_fill")


if __name__ == "__main__":
    main()
