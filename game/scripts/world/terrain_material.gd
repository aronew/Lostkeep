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
@export var fade_tiles := 3.0

@export_group("Walking tops")
## A horizontal band whose `top_line` row sits exactly on the walking line.
@export var top_band: Texture2D
@export var top_line := 22

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
