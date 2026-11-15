extends "res://tools/room_builder.gd"
## Builds room IB-07, the Pit Shaft, from the plan below, with the shared tools
## in room_builder.gd, and saves it as an ordinary scene. Re-running this script
## overwrites scenes/rooms/ironbark_07_pit_shaft.tscn.
##
##   godot --headless --path game --script res://tools/build_ib07.gd
##
## Spec and validation: design/rooms/ironbark_07_pit_shaft.md.
## In the world grid its origin is IB-01's (-44, 64): it lies under the Shrine
## Hall (IB-05), whose pit (world x -29 to -26) opens into the top of its shaft
## through the cracked bark plate (W1b, the Ironbark Ward). Its East door
## (rows 8 to 12) is the Undercroft's lower West door (IB-06, rows 32 to 36).
## After the creative lead's vertical-level mockups
## (docs/mockups/undercroft/vertical_levels.webp, the far left one) and their
## shaft reference (docs/mockups/undercroft/shaft_reference.webp).

const ROOM_PATH := "res://scenes/rooms/ironbark_07_pit_shaft.tscn"
const IB06 := "res://scenes/rooms/ironbark_06_undercroft.tscn"

# --- The room plan (tiles) ---------------------------------------------------------
## "A narrow masonry shaft dropping from the Shrine Hall's pit to the deep:
##  small ledges taking turns across it, and burial pockets opening off it on
##  alternating sides, the deepest chamber at the bottom."
const ROOM := Rect2i(0, 0, 44, 41)
const ROCK := [[0, 0, 44, 41, 1]]
const SPACES := [
	[14, 1, 6, 33],     # the shaft, from under the plate to the deep chamber
	[20, 8, 24, 5],     # the passage east to the Undercroft (floor row 13)
	[2, 17, 12, 5],     # a burial pocket off the shaft's west side (floor row 22)
	[20, 26, 20, 5],    # a longer pocket off its east side (floor row 31)
	[4, 34, 36, 5],     # the deep chamber at the bottom (floor row 39)
]
## The ledges up the shaft, 2 wide, taking turns across it every 4 or 5 rows,
## each beside the one below, never over it. Where a pocket opens, its floor
## runs on into the shaft as the ledge on that side.
const MASSES := [
	[14, 35, 2, 2, 1],   # deep floor 39 -> 35, west
	[18, 31, 2, 2, 1],   # -> 31, east: the east pocket's lip
	[16, 27, 2, 2, 1],   # -> 27, the middle
	[14, 22, 2, 2, 1],   # -> 22, west: the west pocket's lip
	[16, 18, 2, 2, 1],   # -> 18, the middle
	[18, 13, 2, 2, 1],   # -> 13, east: the passage's lip
	[14, 9, 2, 2, 1],    # -> 9, west
	[18, 5, 2, 2, 1],    # -> 5, east, under the plate
]
const STONE := [[0, 0, 44, 41]]
const SKIP := []
const SPAWN := Vector2(40 * 16, 13 * 16)
const LAMP := Color(1.0, 0.72, 0.4)


func _initialize() -> void:
	room = ROOM
	rock = ROCK
	spaces = SPACES
	masses = MASSES
	stone = STONE
	skip = SKIP
	spawn = SPAWN
	room_path = ROOM_PATH
	var tileset := _shared()
	_use_crypt_y_stone()
	_begin("IronbarkPitShaft")
	_shrine_far()
	var t := _terrain(tileset)
	_grade_stone()
	_build_plate(t["behind"])
	_build_lights(t["behind"])
	_crypt_foreground()
	_edge_shades()
	_door("East", Rect2i(36, 8, 8, 5), 1, IB06, "WestLower")
	_finish()
	quit()


## The underside of the Shrine Hall's cracked plate (W1b), at the top of the
## shaft, out of reach: the lock seen from below.
func _build_plate(behind: Node) -> void:
	var art := _sprite(behind, ENV + "gate_bark_plate.png", Rect2(65, 97, 63, 29), Vector2(15 * TILE, -14))
	art.name = "PlateFromBelow"
	art.flip_v = true
	art.z_index = 8
	_light(behind, Vector2(17 * TILE, 2 * TILE), Color(0.55, 0.75, 1.0), 0.6, 0.8, "PlateLight")


## Blockout light only: enough to read the spaces in the review shots.
func _build_lights(behind: Node) -> void:
	for p in [Vector2(30, 10), Vector2(8, 19), Vector2(30, 28), Vector2(12, 36), Vector2(30, 36), Vector2(17, 20)]:
		_light(behind, Vector2(p.x * TILE, p.y * TILE), LAMP, 0.9, 1.4, "BlockoutLight")
