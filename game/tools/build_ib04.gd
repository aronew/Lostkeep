extends "res://tools/surface_builder.gd"
## Builds room IB-04, the Gate Road, and saves it as an ordinary scene.
## Re-running overwrites scenes/rooms/ironbark_04_gate_road.tscn.
##
##   godot --headless --path game --script res://tools/build_ib04.gd
##
## Spec and validation: design/rooms/ironbark_04_gate_road.md. After the
## creative lead's mockup "Moonlit Ruin Gardens Above the Forest": she comes in
## high on the west hill and winds back down its terraces, with the great
## islands hanging over them; then the straight road east, a jump over the
## water, and the way on to the guard's clearing (IB-01).
##
## World grid: origin at IB-01's (-112, -13). Its East door (rows 32 to 36) is
## IB-01's west upper exit (rows 19 to 23); its West door (rows 11 to 15) is
## IB-03's East door.

const ROOM_PATH := "res://scenes/rooms/ironbark_04_gate_road.tscn"
const IB01 := "res://scenes/rooms/ironbark_test_room.tscn"
const IB03 := "res://scenes/rooms/ironbark_03_ruin_gardens.tscn"

const ROOM := Rect2i(0, 0, 112, 40)
const ROCK := [
	[0, 37, 112, 3, 0],    # the ground: the road east
	[0, 16, 10, 21, 0],    # the west hill, winding down east
	[10, 19, 8, 18, 0],
	[18, 22, 8, 15, 0],
	[26, 26, 8, 11, 0],
	[34, 29, 8, 8, 0],
	[42, 34, 8, 3, 0],
]
const SPACES := [
	[88, 37, 4, 2],        # the water across the road
]
## The islands: one tile of collision under each painting's grass line.
const MASSES := [
	[21, 17, 3, 1, 0],     # the stepping island (bush chunk)
	[27, 16, 19, 1, 0],    # the great island, over the terraces (the tree)
	[50, 20, 16, 1, 0],    # the second island (root-held)
	[76, 17, 9, 1, 0],     # the far island (the ruin): Wing-Cloak
]
const SKIP := [[21, 17, 3, 1], [27, 16, 19, 1], [50, 20, 16, 1], [76, 17, 9, 1]]
const SPAWN := Vector2(4 * 16, 16 * 16)

const GROUND := 592.0


func _initialize() -> void:
	room = ROOM
	rock = ROCK
	spaces = SPACES
	masses = MASSES
	skip = SKIP
	spawn = SPAWN
	room_path = ROOM_PATH
	var t := _surface_begin("IronbarkGateRoad")
	var behind: Node = t["behind"]
	var placed: Node = t["placed"]
	_island(placed, "chunk_bush", 21, 17, 3)
	_island(placed, "tree", 27, 16, 19)
	_island(placed, "root_held", 50, 20, 16)
	_island(placed, "ruin", 76, 17, 9)
	_hide_island_tiles()
	# The flights down the hill.
	_flight(placed, 160, 19 * TILE, true)
	_flight(placed, 288, 22 * TILE, true)
	_flight(placed, 544, 29 * TILE, true)
	_flight(placed, 800, GROUND, true)
	# The water: she can't swim yet. A four-tile jump.
	var brook := _water("Brook", Vector2(88 * TILE, GROUND + 5), Vector2(4 * TILE, 2 * TILE - 5), Vector2(32, 14))
	brook.get_node("Glint").visible = false
	_dress(behind, placed)
	_surface_finish()
	_door("West", Rect2i(0, 11, 8, 5), -1, IB03, "East")
	_door("East", Rect2i(104, 32, 8, 5), 1, IB01, "WestUpper")
	_finish()
	quit()


func _dress(behind: Node, placed: Node) -> void:
	# The hilltop she arrives on: the arch from the gardens, its lantern.
	_arch_door(behind, -30, 16 * TILE, false)
	# The terraces: graves and fences all the way down.
	_row(behind, GRAVE, 19 * TILE, [[GRAVE_CROSS, 236.0]])
	_row(behind, GRAVE, 22 * TILE, [[GRAVE_CELTIC, 372.0]])
	_row(behind, GRAVE, 26 * TILE, [[FENCE, 424.0], [GRAVE_CREST, 470.0]])
	_lantern_post(behind, 620, 29 * TILE)
	_row(behind, GRAVE, 34 * TILE, [[GRAVE_BROKEN, 690.0], [GRAVE_CROSS, 730.0]])
	# Something glints on the far island (Wing-Cloak).
	_glint(behind, Vector2(1280, 17 * TILE - 44), Color(1.0, 0.85, 0.5))
	# The road east: graves, a ruin, a crystal shrine, the timber gate over the water.
	_row(behind, GRAVE, GROUND, [[GRAVE_CREST, 930.0], [FENCE, 1090.0]])
	_piece(behind, DOOR_RUINED, 960, GROUND, "RoadRuin").modulate = Color(0.9, 0.9, 0.95)
	_piece(behind, CRYSTAL_SHRINE, 1210, GROUND, "CrystalShrine")
	_row(behind, FLORA, GROUND, [[TUFTS[1], 1060.0], [TUFTS[0], 1560.0]])
	_lantern_post(behind, 1340, GROUND)
	_piece(behind, TIMBER_GATE, 1400, GROUND, "TimberGate")
	# The Great Ironbark's kin at the road's end, toward the clearing.
	var tree := _sprite(behind, ENV + "landmark_great_ironbark.png", Rect2(1, 1, 255, 252), Vector2(1580, GROUND - 248))
	tree.name = "RoadTree"
	tree.flip_h = true
