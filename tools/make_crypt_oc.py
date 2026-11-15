"""Bring the creative lead's crypt kit (OC1 to OC8) into the game.

The sheets in art/source/ironbark/crypt_oc/ are the generator's exports at 8x
(4x for the three backdrop sheets), in flat blocks. Each is reduced to game
scale by sampling one pixel per block, with nothing else done to it, and the
terrain bands the skin needs are cut from OC1 and OC2 as they are.

Usage: python3 tools/make_crypt_oc.py
"""
from PIL import Image

SRC = "art/source/ironbark/crypt_oc/"
ENV = "game/assets/environment/ironbark/"
SHEETS = {
    "OC1_masonry_bands": ("oc_masonry_bands", 8),
    "OC2_walls_corners_pillar": ("oc_walls_corners", 8),
    "OC3_floating_ruins": ("oc_floating_ruins", 8),
    "OC4_gallery_ledges": ("oc_gallery_ledges", 8),
    "OC5_distant_well": ("oc_far_well", 4),
    "OC6_middle_arcades": ("oc_mid_arcades", 4),
    "OC7_foreground_strips": ("oc_foreground", 4),
    "OC8_crypt_props": ("oc_props", 8),
}


def main():
    small = {}
    for name, (out, scale) in SHEETS.items():
        im = Image.open(SRC + name + ".png").convert("RGBA")
        s = im.resize((im.size[0] // scale, im.size[1] // scale), Image.NEAREST)
        s.save(ENV + out + ".png")
        small[out] = s
        print(out, s.size)
    bands = small["oc_masonry_bands"]
    # The floor band: its walking line is row 8. The ceiling band: its ceiling
    # line is row 120 of the sheet (row 48 of the cut); what hangs below it is
    # under the ceiling.
    bands.crop((0, 0, 384, 56)).save(ENV + "terrain/oc_top.png")
    bands.crop((0, 72, 384, 128)).save(ENV + "terrain/oc_under.png")
    # The wall strip faces right; its face is column 37.
    small["oc_walls_corners"].crop((0, 0, 46, 256)).save(ENV + "terrain/oc_wall.png")
    Image.new("RGBA", (16, 16), (11, 8, 18, 255)).save(ENV + "terrain/oc_fill.png")
    # An outer corner where a walking top turns down into a face (facing right):
    # its walking line is row 8 and its face column 60 of the cut.
    small["oc_walls_corners"].crop((64, 32, 128, 96)).save(ENV + "terrain/oc_corner_top.png")
    print("terrain bands: oc_top (line 8), oc_under (line 48), oc_wall (face 37), oc_fill, oc_corner_top (anchor 60, 8)")


if __name__ == "__main__":
    main()
