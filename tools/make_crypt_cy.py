"""Bring the crypt stone after reference Y (CY1, CY2, CY2b) into the game.

The creative lead's clean 8x exports in art/source/ironbark/crypt_y/ (the
chunky brick, about 11 x 5 px in the game) are reduced 8:1 by sampling one
pixel per block, with nothing else done to them, and the terrain bands and
corners the skin needs are cut from them as they are.

Each band fades into the dark brick by brick itself, so the masses are void
inside (fade 0) and only the bands' near-void pixels are cleared, so the void
behind shows through without a seam.

Usage: python3 tools/make_crypt_cy.py
"""
from PIL import Image

SRC = "art/source/ironbark/crypt_y/"
OUT = "game/assets/environment/ironbark/terrain/"
DARK = 32  # also clears the bands' last flat dark course, so they end along the bricks


def small(name):
    im = Image.open(SRC + name).convert("RGBA")
    return im.resize((im.width // 8, im.height // 8), Image.NEAREST)


def clear_dark(im):
    px = im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r, g, b, a = px[x, y]
            if a and (r + g + b) / 3 < DARK:
                px[x, y] = (0, 0, 0, 0)
    return im


def main():
    cy1 = small("CY1_floor_and_ceiling.png")       # 384 x 128
    cy2 = small("CY2_wall_and_floor_corners.png")  # 384 x 128
    cy2b = small("CY2b_ceiling_corners.png")       # 256 x 128
    # Floor band: moss above, walking line on row 8, into the dark by row 50.
    clear_dark(cy1.crop((0, 0, 384, 56))).save(OUT + "cy_top.png")
    # Ceiling band: from the dark at row 72, ceiling line on row 120 (48 here), moss and roots below.
    clear_dark(cy1.crop((0, 72, 384, 128))).save(OUT + "cy_under.png")
    # Wall band: faces right, face column 55, fading leftward into the dark; 128 tall, repeating.
    clear_dark(cy2.crop((0, 0, 56, 128))).save(OUT + "cy_wall.png")
    # Outer floor corner (CY2's middle cell): walking line row 64, face column 63;
    # cut with 8 rows above the line for the moss: anchor (64, 8).
    clear_dark(cy2.crop((128, 56, 192, 128))).save(OUT + "cy_corner_top.png")
    # Outer ceiling corner (CY2b's left cell): ceiling line row 65, face column 64;
    # moss hangs below the line: anchor (65, 65).
    clear_dark(cy2b.crop((0, 0, 72, 80))).save(OUT + "cy_corner_under.png")
    # Inner ceiling corner (CY2b's right cell): wall on the left of the notch at
    # (59, 65). Cut across the whole stone side of the cell, so its own fade
    # reaches the dark instead of ending on a straight cut, and 48 px along the
    # ceiling (short of the quoins at the cell's far edge): anchor (59, 48).
    clear_dark(cy2b.crop((128, 17, 128 + 107, 128))).save(OUT + "cy_inner_under.png")
    # Inner floor corner (CY2's right cell): wall rising on the left of the notch
    # at (64, 64), cut the same way: anchor (64, 48).
    clear_dark(cy2.crop((256, 16, 256 + 112, 128))).save(OUT + "cy_inner_top.png")
    # The inside of a mass is the void: the bands carry the fade.
    Image.new("RGBA", (16, 16), (11, 8, 18, 255)).save(OUT + "cy_fill.png")
    print("terrain: cy_top (line 8), cy_under (line 48), cy_wall (face 55), corners (64, 8) and (65, 65), inner corners (59, 48) and (64, 48), cy_fill")


if __name__ == "__main__":
    main()
