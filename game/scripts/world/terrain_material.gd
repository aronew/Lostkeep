@tool
class_name TerrainMaterial
extends Resource
## How one terrain material is painted onto the black-box collision.
##
## Every band is drawn in world-aligned slices, so long bands continue across
## cells without seams. All measurements are in pixels of the band textures.

## The inside of a mass, repeating; it fades to the void with depth.
@export var fill: Texture2D
## How many tiles deep the fill takes to fade from full brightness to the void.
## 0 paints the whole inside as the void, so a slab between a floor and the
## ceiling below it is black between its two painted bands (the house style).
@export var fade_tiles := 0.0

@export_group("Walking tops")
## A horizontal band whose `top_line` row sits exactly on the walking line.
@export var top_band: Texture2D
@export var top_line := 22
## How many pixels below the walking line the band may reach. The bands end in
## the void, so this is normally the whole band.
@export var top_lit := 64
## A one-pixel highlight along every walking line, so ledges read at a glance.
## Transparent for none (earth's moss lip already reads).
@export var lip_color := Color(0, 0, 0, 0)

@export_group("Ceilings")
## A horizontal band whose `under_line` row sits exactly on the ceiling line.
## Rows below `under_line` hang under the ceiling (roots, corbels).
@export var under_band: Texture2D
@export var under_line := 38

@export_group("Walls")
## A vertical band facing right; column `wall_face` is the wall's face.
## It is mirrored for walls that face left.
@export var wall_band: Texture2D
@export var wall_face := 55
## On a slab thinner than the skin looks through (5 tiles), how far in from the
## face the wall band is drawn (its face stones only), so its inward fade never
## covers the floor and ceiling bands' lit bricks. 0: the whole band.
@export var thin_wall_depth := 0
@export_group("Corners")
## Painted outer corners: where a walking top turns down into a face, and where a
## ceiling turns up into one. Each faces right (mirrored for left), and its anchor
## is the pixel where its walking or ceiling line meets its face. The skin clips
## each piece to the mass it sits on, so two corners on a narrow column meet in
## the middle.
@export var corner_top: Texture2D
@export var corner_top_anchor := Vector2.ZERO
@export var corner_under: Texture2D
@export var corner_under_anchor := Vector2.ZERO
## For a ceiling corner that stands on the floor (an arcade's end pier): how far
## it reaches below the ceiling line. It is placed only where the floor lies
## within 16 px of that, so it never hangs in mid-air. 0: it hangs freely.
@export var corner_under_reach := 0.0
## Also place the ceiling corner where a ceiling meets a wall that runs down to
## the floor (an arcade ending on a pier set against the wall), not only where a
## ceiling turns up into a face.
@export var corner_under_inner := false

@export_group("Walls")
## A one-pixel line just outside every wall face, separating the playfield from
## the background behind it. Transparent for none.
@export var outline_color := Color(0.03, 0.02, 0.05, 0.9)
