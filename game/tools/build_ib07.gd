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
## (rows 36 to 40) is the Undercroft's plated West door (IB-06, rows 60 to 64),
## also the Ward's: the room is closed until Kleo has the Ward's slam.
## After the creative lead's vertical-level mockups
## (docs/mockups/undercroft/vertical_levels.webp, the far left one) and their
## shaft reference (docs/mockups/undercroft/shaft_reference.webp).

const ROOM_PATH := "res://scenes/rooms/ironbark_07_pit_shaft.tscn"
const IB06 := "res://scenes/rooms/ironbark_06_undercroft.tscn"

# --- The room plan (tiles) ---------------------------------------------------------
## Laid out piece by piece after the creative lead's far-left vertical-level
## mockup (docs/mockups/undercroft/vertical_levels.webp; about 40 x 60 tiles):
## the cave opening at the top (the pit), the walkway bridging the chasm between
## two masonry masses, the alcove beside it, the arched-door room down the left,
## the tall wall on the right with a ledge out to it, the zig-zag mass down the
## middle with a niche and small ledges off it, the lantern room low on the
## right, and the stepped floor at the bottom.
const ROOM := Rect2i(0, 0, 44, 64)
const ROCK := [[0, 0, 44, 64, 1]]
const SPACES := [
	[15, 1, 4, 2],      # the cave opening at the top: the pit, under the cracked plate (W1b)
	[1, 3, 38, 57],     # the shaft: one tall cave, the masses put back into it (bottom floor row 60)
	[34, 36, 10, 5],    # the passage east to the Undercroft's plated door (floor row 41)
	[39, 55, 5, 5],     # out of the lantern room, east: on to the deep (not built; floor row 60)
]
## The masses as in the mockup. The upper half (the walkway, the chasm, the
## landing, the arched-door room, the west cave) is reached only by dropping
## through the plate: a descent. Low on the right, three ledges climb from the
## bottom to the niche and the passage out, each beside the one below.
const MASSES := [
	[12, 12, 5, 2, 1],   # the walkway, west of the gap over the chasm (floor row 12)
	[20, 12, 12, 2, 1],  # and east of it, to the alcove
	[0, 3, 8, 18, 1],    # the building over the arched-door room
	[8, 14, 7, 7, 1],    # the left mass under the walkway
	[21, 14, 9, 8, 1],   # the right mass under it
	[21, 22, 5, 8, 1],   # stepping on down
	[34, 9, 5, 27, 1],   # the tall wall on the right
	[0, 28, 10, 4, 1],   # the arched-door room's floor (row 28)
	[4, 32, 2, 24, 1],   # the wall under it
	[1, 32, 3, 20, 1],   # and the rock behind it, down to the secret room at its foot
	[14, 28, 10, 13, 1], # the zig-zag mass: the landing on top (row 28)
	[12, 36, 2, 2, 1],   # a ledge off its west side (row 36)
	[17, 41, 5, 11, 1],  # the mass going on down
	[15, 52, 7, 6, 1],   # its foot
	[9, 50, 4, 2, 1],    # a ledge low in the west cave (row 50)
	[25, 41, 4, 2, 1],   # the niche (row 41)
	[31, 41, 8, 8, 1],   # the passage out's floor (row 41), over the lantern room
	[22, 46, 3, 2, 1],   # the climb from the bottom: 46
	[26, 50, 3, 2, 1],   # 50
	[22, 54, 3, 2, 1],   # 54
	[9, 58, 5, 2, 1],    # the bottom floor's west step (row 58)
	[26, 58, 6, 2, 1],   # and its east step
]
const STONE := [[0, 0, 44, 64]]
const SKIP := []
const SPAWN := Vector2(40 * 16, 41 * 16)
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
	_dress(t["behind"])
	_build_air()
	_build_secrets()
	_crypt_foreground()
	_edge_shades()
	# The passage east ends at the Undercroft's plated door (Ironbark Ward).
	_door("East", Rect2i(36, 36, 8, 5), 1, IB06, "WestLower")
	# Out of the lantern room, on to the deep under the clearing (not built).
	_door("EastLower", Rect2i(36, 55, 8, 5), 1, "", "")
	_finish()
	quit()


## The underside of the Shrine Hall's cracked plate (W1b), at the top of the
## shaft, out of reach: the lock seen from below.
func _build_plate(behind: Node) -> void:
	var art := _sprite(behind, ENV + "gate_bark_plate.png", Rect2(65, 97, 63, 29), Vector2(15 * TILE, -10))
	art.name = "PlateFromBelow"
	art.flip_v = true
	art.z_index = 8
	_light(behind, Vector2(17 * TILE, 2 * TILE), Color(0.55, 0.75, 1.0), 0.6, 0.8, "PlateLight")


## Dressed after the mockup: torches on two stubs on the walkway and pillars
## rising from it, a lantern in the alcove, the arched door with its torches,
## crystals on the landing, roots and ivy down the west cave, a chest in the
## niche, the lantern room with its doorway on, crystals and flowers below.
func _dress(behind: Node) -> void:
	var bag := ENV + "props_guard_belongings.png"
	var T := float(TILE)
	# The walkway: two broken stubs with torches on them, two tall pillars.
	_sh_piece(behind, "arcades", Rect2(272, 32, 20, 80), 12.4 * T, 12 * T, "Pillar")
	_sh_piece(behind, "arcades", Rect2(272, 32, 20, 80), 28.6 * T, 12 * T, "Pillar")
	_sh_piece(behind, "arcades", Rect2(224, 80, 16, 32), 14.6 * T, 12 * T, "Stub")
	_sh_torch(behind, 14.6 * T, 12 * T - 44)
	_sh_piece(behind, "arcades", Rect2(224, 80, 16, 32), 21.2 * T, 12 * T, "Stub")
	_sh_torch(behind, 21.2 * T, 12 * T - 44)
	# The alcove top right: a lantern on its chain.
	_hanging_lantern(behind, 26.5 * T, 3 * T)
	# The arched-door room: the door and its torches.
	_sh_doorway(behind, 1.6 * T, 28 * T, false)
	_sh_torch(behind, 0.4 * T, 28 * T - 56)
	# The landing: crystals and flowers.
	_sh_piece(behind, "flora", Rect2(8, 16, 32, 24), 15.2 * T, 28 * T, "Crystals")
	_sh_piece(behind, "flora", Rect2(8, 72, 32, 20), 18.0 * T, 28 * T, "Flowers")
	# Down the west cave: ivy under the arched room's floor, roots under the ledges.
	_hang(behind, 2, 7.0 * T, 32 * T)
	_hang(behind, 4, 12.0 * T, 38 * T)
	_hang(behind, 1, 9.6 * T, 52 * T)
	_hang(behind, 5, 22.0 * T, 30 * T)
	# The niche: a chest, crystals beside it.
	_sh_piece(behind, "arcades", Rect2(352, 96, 24, 16), 26.0 * T, 41 * T, "Chest")
	_sh_piece(behind, "flora", Rect2(8, 16, 32, 24), 27.6 * T, 41 * T, "Crystals")
	# The passage out: a lantern.
	_hanging_lantern(behind, 38.0 * T, 36 * T)
	# The bottom: crystals, flowers on the west step, pots, a stub on the east step.
	_sh_piece(behind, "flora", Rect2(152, 0, 64, 40), 21.6 * T, 60 * T, "Crystals")
	_sh_piece(behind, "flora", Rect2(152, 56, 64, 36), 9.0 * T, 58 * T, "Flowers")
	_sh_piece(behind, "arcades", Rect2(304, 88, 40, 24), 6.2 * T, 60 * T, "Pots")
	_sh_piece(behind, "arcades", Rect2(224, 80, 16, 32), 28.6 * T, 58 * T, "Stub")
	# The lantern room: its lantern, the doorway on east, a crate.
	_hanging_lantern(behind, 35.2 * T, 43 * T + 6 * T)
	_sh_doorway(behind, 44 * T - 62, 60 * T, true)
	_breakable(bag, CRATE_B, 32.2 * T, 60 * T, WOOD)


## The air: the darkness, dust down the shaft, the plate's light from above.
func _build_air() -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.8, 0.8, 0.9)
	_dust("ShaftDust", Rect2(4 * TILE, 3 * TILE, 32 * TILE, 56 * TILE), 30)
	_fog(_root, Rect2(2 * TILE, 56 * TILE, 36 * TILE, 5 * TILE), Color("#66647e"), 0.2, Vector2(0.005, 0.0))


## A secret room at the foot of the west wall: from the bottom floor the wall
## seems to run on down to it; its foot is a false wall. Tell: motes.
func _build_secrets() -> void:
	_false_wall("WestFootSecret", Rect2i(1, 52, 5, 8), 6, Vector2i(56, 4), 1, "ib07_foot_secret")
	_draught("WestFootDraught", Rect2(6.2 * TILE, 56.5 * TILE, 2.0 * TILE, 3.0 * TILE), Vector2(-1, 0))
	_resin_cache(_root, 1.4 * TILE, 3.6 * TILE, 60.0 * TILE, 5, "ib07_foot_resin")
