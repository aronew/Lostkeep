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
## A one-pixel line just outside every wall face, separating the playfield from
## the background behind it. Transparent for none.
@export var outline_color := Color(0.03, 0.02, 0.05, 0.9)
