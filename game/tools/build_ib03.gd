extends "res://tools/surface_builder.gd"
## Builds room IB-03, the Ruin Gardens (the game's opening room), and saves it
## as an ordinary scene. Re-running overwrites scenes/rooms/ironbark_03_ruin_gardens.tscn.
##
##   godot --headless --path game --script res://tools/build_ib03.gd
##
## Spec and validation: design/rooms/ironbark_03_ruin_gardens.md. After the
## creative lead's mockup "Moonlit Forest Ruins and Floating Islands": a place to
## learn to move. Climb the west hill, cross the great floating island, and
## leave by the arch high on the east cliff.
##
## World grid: origin at IB-01's (-196, -13). Its East door (rows 11 to 15) is
## IB-04's West door.

const ROOM_PATH := "res://scenes/rooms/ironbark_03_ruin_gardens.tscn"
const IB04 := "res://scenes/rooms/ironbark_04_gate_road.tscn"

const ROOM := Rect2i(0, 0, 93, 40)
const ROCK := [
	[0, 37, 93, 3, 0],     # the ground
	[8, 34, 8, 3, 0],      # the west hill: three terraces rising east
	[16, 31, 8, 6, 0],
	[24, 28, 6, 9, 0],
	[30, 33, 5, 4, 0],     # the shelf at the hill's foot: the way back up from the garden
	[57, 33, 14, 4, 0],    # the long shelf at the east cliff's foot, by the cave
	[71, 22, 22, 15, 0],   # the east cliff
	[79, 19, 14, 3, 0],
	[85, 16, 8, 3, 0],
]
const SPACES := [
	[71, 28, 9, 5],        # the cave in the cliff's foot
]
## The islands: one tile of collision under each painting's grass line.
const MASSES := [
	[32, 25, 5, 1, 0],     # the stepping island (headstone chunk)
	[39, 22, 27, 1, 0],    # the great island (the graveyard)
	[44, 31, 11, 1, 0],    # the low island over the garden (the crystal shrine)
]
const SKIP := [[32, 25, 5, 1], [39, 22, 27, 1], [44, 31, 11, 1]]
const BACK_EARTH := [[71, 28, 9, 5]]
const SPAWN := Vector2(2.5 * 16, 37 * 16)

const GROUND := 592.0


func _initialize() -> void:
	room = ROOM
	rock = ROCK
	spaces = SPACES
	masses = MASSES
	skip = SKIP
	back_earth = BACK_EARTH
	spawn = SPAWN
	room_path = ROOM_PATH
	var t := _surface_begin("IronbarkRuinGardens")
	var behind: Node = t["behind"]
	var placed: Node = t["placed"]
	# The islands, the stairs, and the log from the great island to the cliff.
	_island(placed, "chunk_headstone", 32, 25, 5)
	_island(placed, "graveyard", 39, 22, 27)
	_island(placed, "shrine", 44, 31, 11)
	_hide_island_tiles()
	_flight(placed, 128, GROUND, false)
	_flight(placed, 384, 31 * TILE, false)
	_flight(placed, 1264, 22 * TILE, false)
	_flight(placed, 1360, 19 * TILE, false)
	_log(placed, 1056, 1136, 22 * TILE)
	_dress(behind)
	_surface_finish()
	# West: the forest road she came by (nothing built beyond it).
	_door("West", Rect2i(0, 32, 4, 5), -1, "", "")
	_door("East", Rect2i(85, 11, 8, 5), 1, IB04, "West")
	_finish()
	quit()


func _dress(behind: Node) -> void:
	# The start: the Great Ironbark at the road's edge, the arch she came through.
	var tree := _sprite(behind, ENV + "landmark_great_ironbark.png", Rect2(1, 1, 255, 252), Vector2(-150, GROUND - 248))
	tree.name = "GreatIronbark"
	tree.modulate = Color(0.8, 0.8, 0.88)
	_arch_door(behind, -40, GROUND, false)
	# The hill's terraces: graves, a fence, a ruined arch at the top.
	_row(behind, GRAVE, 34 * TILE, [[GRAVE_CROSS, 196.0]])
	_row(behind, GRAVE, 31 * TILE, [[GRAVE_CELTIC, 262.0]])
	_piece(behind, DOOR_RUINED, 384, 28 * TILE, "HillRuin").modulate = Color(0.9, 0.9, 0.95)
	# The garden under the islands.
	_row(behind, GRAVE, GROUND, [[GRAVE_BROKEN, 590.0], [GRAVE_CREST, 660.0], [FENCE, 760.0]])
	_row(behind, FLORA, GROUND, [[TUFTS[1], 640.0], [TUFTS[0], 880.0]])
	# The cave: a lantern someone left burning.
	_lantern_post(behind, 1180, 33 * TILE)
	_breakable(ENV + "props_guard_belongings.png", POT, 1250.0, 33 * TILE, CLAY)
	_row(behind, GRAVE, 33 * TILE, [[GRAVE_CROSS, 960.0], [FENCE_POST, 1040.0]])
	# The east cliff: graves, and the arch at the top (the way on).
	_row(behind, GRAVE, 22 * TILE, [[GRAVE_CREST, 1150.0]])
	_row(behind, GRAVE, 19 * TILE, [[GRAVE_CROSS, 1275.0]])
	_arch_door(behind, 1488 - 80, 16 * TILE, true)
