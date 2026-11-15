extends "res://tools/room_builder.gd"
## Builds room IB-06, the Undercroft, from the plan below, with the shared
## tools in room_builder.gd, and saves it as an ordinary scene. Re-running this
## script overwrites scenes/rooms/ironbark_06_undercroft.tscn.
##
##   godot --headless --path game --script res://tools/build_ib06.gd
##
## Spec and validation: design/rooms/ironbark_06_undercroft.md.
## In the world grid its origin is IB-01's (0, 40): it lies under the Lantern
## Clearing. Its West door (rows 12 to 15) is IB-05's lower East door (rows 22
## to 25); its lower West door (rows 60 to 64), behind a bark plate (the Ward),
## is the Pit Shaft's East door (IB-07, rows 36 to 40); its lower East door
## leads on toward the Keep's foundations.

const ROOM_PATH := "res://scenes/rooms/ironbark_06_undercroft.tscn"
const IB05 := "res://scenes/rooms/ironbark_05_shrine_hall.tscn"
const IB07 := "res://scenes/rooms/ironbark_07_pit_shaft.tscn"

# --- The room plan (tiles) ---------------------------------------------------------
## After the creative lead's middle vertical-level mockup
## (docs/mockups/undercroft/vertical_levels.webp): the guard's cellar rooms
## stacked down both sides of a tall void under the clearing, a broken root arch
## across it halfway down, a basin at the bottom. The way down crosses the void
## from side to side, room by room; a lift beside the east stack folds the
## bottom back to the top.
const ROOM := Rect2i(0, 0, 44, 72)
const ROCK := [[0, 0, 44, 72, 1]]
const SPACES := [
	[13, 0, 9, 68],     # the void, from the dark far above (toward the clearing's crypt) to the basin
	[0, 8, 13, 8],      # L1, the storeroom: in from the Shrine Hall (floor row 16)
	[22, 1, 6, 4],      # an alcove high in the void's east wall (Barkgrip; floor row 5)
	[22, 7, 20, 11],    # R1, the arcade (floor row 18), the lift's head at its east end
	[7, 19, 6, 6],      # L2, a lantern room (floor row 25)
	[22, 21, 15, 7],    # R2, a lantern room (floor row 28)
	[0, 30, 13, 9],     # L3, the long arcade (floor row 39)
	[22, 31, 15, 8],    # R3, the arcade across from it (floor row 39)
	[6, 43, 7, 10],     # L4, a lantern room (floor row 53), open to the arch's west end
	[22, 41, 15, 12],   # R4, a cellar under the arch's east end (floor row 53)
	[3, 57, 10, 8],     # L5, the bottom-left room (floor row 65): the plated door west
	[0, 60, 3, 5],      # its plated door (Ironbark Ward) into the Pit Shaft
	[22, 57, 20, 8],    # R5, the bottom-right room (floor row 65): the lift's foot, the way on east
	[42, 60, 2, 5],     # on east toward the Keep's foundations
	[13, 65, 11, 3],    # the basin (floor row 68)
	[13, 68, 3, 3],     # the sump in its floor: dark water going on down (Deep-Glow Breath)
	[38, 18, 4, 47],    # the lift's shaft, R5 up to R1
	[2, 21, 5, 4],      # a secret room behind L2's west wall (floor row 25)
	[1, 48, 5, 5],      # a secret room behind L4's west wall (floor row 53)
]
## Each room's floor runs out into the void as a lip, so the rooms across from
## each other are a short jump apart, a little lower each time. Every gap she
## is meant to drop through is 2 tiles wide: she runs straight over a 1-tile gap.
const MASSES := [
	[13, 16, 3, 2, 1],   # L1's lip (row 16): a short drop across to R1's
	[18, 18, 4, 2, 1],   # R1's lip (row 18): off its west end, down onto the step
	[16, 28, 2, 2, 1],   # a step in the void (row 28): up to L2, across to R2
	[13, 25, 3, 2, 1],   # L2's lip (row 25)
	[20, 28, 2, 2, 1],   # R2's lip (row 28): off its west end, down onto R3's
	[18, 39, 4, 2, 1],   # R3's lip (row 39): across to L3's, or off it onto the arch
	[13, 39, 3, 2, 1],   # L3's lip (row 39)
	[13, 46, 14, 2, 1],  # the root arch across the void (row 46): west into L4, east into R4
	[13, 53, 4, 2, 1],   # L4's lip (row 53): off it down to the basin
]
const STONE := [[0, 0, 44, 72]]
const SKIP := []
const SPAWN := Vector2(6 * 16, 16 * 16)
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
	_begin("IronbarkUndercroft")
	_shrine_far()
	var t := _terrain(tileset)
	_grade_stone()
	_build_machines()
	_dress(t["behind"])
	_build_air()
	_build_secrets()
	_crypt_foreground()
	_edge_shades()
	_door("West", Rect2i(0, 12, 8, 4), -1, IB05, "EastLower")
	_door("WestLower", Rect2i(0, 60, 8, 5), -1, IB07, "East")
	# On east toward the Keep's foundations (not built).
	_door("EastLower", Rect2i(36, 60, 8, 5), 1, "", "")
	_finish()
	quit()


func _build_machines() -> void:
	# The cellar lift: jammed at the top (its deck plugs R1's floor at its east
	# end); from R5 at the bottom, the winch frees it, and it folds the whole
	# descent back to the top, a short jump from the Shrine Hall's door.
	_lift("CellarLift", Vector2(40 * TILE, 18 * TILE), 47.0 * TILE, -4.0 * TILE, "ib06_lift")
	# The sump: dark water she can't swim yet, a glint going on down.
	_water("Sump", Vector2(13 * TILE, 68 * TILE + 4), Vector2(3 * TILE, 3 * TILE - 4), Vector2(14.5 * TILE, 70 * TILE))
	# The plated door into the Pit Shaft (Ironbark Ward): shut until the slam.
	var plate := _node(StaticBody2D.new(), "BarkPlateW1c", _root) as StaticBody2D
	plate.position = Vector2(0, 60 * TILE)
	plate.z_index = 8
	var pc := CollisionShape2D.new()
	var pr := RectangleShape2D.new()
	pr.size = Vector2(2 * TILE, 5 * TILE)
	pc.shape = pr
	pc.position = Vector2(TILE, 2.5 * TILE)
	_node(pc, "Shape", plate)
	_sprite(plate, ENV + "gate_bark_plate.png", Rect2(77, 2, 41, 82), Vector2(-6, -2)).name = "Art"


## The cellar rooms, dressed from the kit: a lantern in each lantern room,
## arcades in the arcade rooms (SH7), the guard's stores in crates and barrels
## (they break), crystals and flowers where the light reaches, ivy and roots
## hanging into the void, the doorways at the doors.
func _dress(behind: Node) -> void:
	var bag := ENV + "props_guard_belongings.png"
	var T := float(TILE)
	# L1, the storeroom: the doorway in from the Shrine Hall, its stores.
	_sh_doorway(behind, -18, 16 * T, false)
	_hanging_lantern(behind, 7.0 * T, 8 * T)
	_breakable(bag, CRATE_A, 8.0 * T, 16 * T, WOOD)
	_breakable(bag, BARREL, 10.2 * T, 16 * T, WOOD)
	_breakable(bag, POT_SMALL, 11.8 * T, 16 * T, CLAY)
	# R1, the arcade: the arcade along its back, a pillar, crystals, the lift.
	_sh_piece(behind, "arcades", Rect2(4, 32, 128, 80), 23.5 * T, 18 * T, "Arcade")
	_sh_piece(behind, "arcades", Rect2(272, 32, 20, 80), 32.8 * T, 18 * T, "Pillar")
	_sh_piece(behind, "flora", Rect2(8, 16, 32, 24), 34.6 * T, 18 * T, "Crystals")
	_sh_piece(behind, "flora", Rect2(8, 72, 32, 20), 21.4 * T, 18 * T, "Flowers")
	# L2, a lantern room: its lantern, pots, flowers.
	_hanging_lantern(behind, 10.0 * T, 19 * T)
	_breakable(bag, POT_SMALL, 7.6 * T, 25 * T, CLAY)
	_breakable(bag, POT, 8.8 * T, 25 * T, CLAY)
	_sh_piece(behind, "flora", Rect2(8, 72, 32, 20), 11.0 * T, 25 * T, "Flowers")
	# R2, a lantern room: a lantern on its east wall, stores, crystals.
	_bracket_lantern(behind, 37.0 * T, 22.0 * T, -1)
	_sh_piece(behind, "flora", Rect2(64, 8, 48, 32), 23.0 * T, 28 * T, "Crystals")
	_breakable(bag, CRATE_B, 28.0 * T, 28 * T, WOOD)
	_breakable(bag, BARREL_BIG, 30.4 * T, 28 * T, WOOD)
	_breakable(bag, CRATE_C, 32.6 * T, 28 * T, WOOD)
	# L3, the long arcade: the arcade, its lantern, flowers out to the lip.
	_sh_piece(behind, "arcades", Rect2(4, 32, 128, 80), 0.5 * T, 39 * T, "Arcade")
	_hanging_lantern(behind, 11.0 * T, 30 * T)
	_sh_piece(behind, "flora", Rect2(152, 56, 64, 36), 9.4 * T, 39 * T, "Flowers")
	# R3, the arcade across: an arch, pillars (one broken), crystals, pots.
	_sh_piece(behind, "arcades", Rect2(144, 32, 64, 80), 25.5 * T, 39 * T, "Arch")
	_sh_piece(behind, "arcades", Rect2(248, 56, 16, 56), 30.6 * T, 39 * T, "Pillar")
	_sh_piece(behind, "arcades", Rect2(224, 80, 16, 32), 32.4 * T, 39 * T, "BrokenPillar")
	_sh_piece(behind, "flora", Rect2(64, 8, 48, 32), 33.6 * T, 39 * T, "Crystals")
	_sh_piece(behind, "arcades", Rect2(304, 88, 40, 24), 22.6 * T, 39 * T, "Pots")
	# The root arch: grass and flowers on it, roots and ivy hanging under it.
	_sh_piece(behind, "flora", Rect2(16, 208, 48, 24), 14.0 * T, 46 * T, "Grass")
	_sh_piece(behind, "flora", Rect2(112, 208, 48, 24), 20.6 * T, 46 * T, "WhiteFlowers")
	_hang(behind, 5, 15.6 * T, 48 * T)
	_hang(behind, 2, 19.2 * T, 48 * T)
	_hang(behind, 4, 23.0 * T, 48 * T)
	# L4, a lantern room: its lantern, a bier, a pot.
	_hanging_lantern(behind, 10.4 * T, 43 * T)
	_ground(behind, ENV + "oc_props.png", Rect2(2, 91, 77, 28), 6.2 * T, 53 * T + 1, 1.0, "Bier")
	_breakable(bag, POT_SMALL, 11.6 * T, 53 * T, CLAY)
	# R4, a cellar under the arch's east end: barrels, a crate, a lantern.
	_bracket_lantern(behind, 37.0 * T, 43.0 * T, -1)
	_breakable(bag, BARREL_BIG, 28.0 * T, 53 * T, WOOD)
	_breakable(bag, BARREL, 30.0 * T, 53 * T, WOOD)
	_breakable(bag, CRATE_A, 32.4 * T, 53 * T, WOOD)
	# L5, the bottom-left room, by the plated door: a lantern, bones, crystals.
	_hanging_lantern(behind, 8.0 * T, 57 * T)
	_ground(behind, ENV + "oc_props.png", Rect2(41, 46, 46, 21), 4.6 * T, 65 * T + 1, 1.0, "Bones")
	_sh_piece(behind, "flora", Rect2(64, 8, 48, 32), 9.4 * T, 65 * T, "Crystals")
	# R5, the bottom-right room: the doorway on east, stores, a lantern.
	_sh_doorway(behind, 44 * T - 62, 65 * T, true)
	_hanging_lantern(behind, 29.0 * T, 57 * T)
	_breakable(bag, CRATE_B, 23.2 * T, 65 * T, WOOD)
	_breakable(bag, POT_BIG, 25.6 * T, 65 * T, CLAY)
	# The basin: grass and flowers round the sump.
	_sh_piece(behind, "flora", Rect2(16, 208, 48, 24), 17.0 * T, 68 * T, "Grass")
	_sh_piece(behind, "flora", Rect2(8, 72, 32, 20), 21.0 * T, 68 * T, "Flowers")
	# Ivy and roots hanging from the lips into the void.
	_hang(behind, 1, 13.4 * T, 18 * T)
	_hang(behind, 2, 19.6 * T, 20 * T)
	_hang(behind, 0, 20.2 * T, 30 * T)
	_hang(behind, 4, 13.8 * T, 41 * T)
	_hang(behind, 1, 14.2 * T, 55 * T)


## The air: the darkness, dust drifting down the void, mist on the basin.
func _build_air() -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.82, 0.82, 0.92)
	_dust("VoidDust", Rect2(13 * TILE, 2 * TILE, 9 * TILE, 64 * TILE), 30)
	_fog(_root, Rect2(13 * TILE, 64 * TILE, 11 * TILE, 5 * TILE), Color("#5f8a8c"), 0.3, Vector2(0.006, 0.0))


## Two secret rooms, each behind a false wall at the back of a lantern room on
## the west side. Tells: motes drifting into the wall.
func _build_secrets() -> void:
	_false_wall("L2Secret", Rect2i(2, 21, 5, 4), 7, Vector2i(21, 4), 1, "ib06_l2_secret")
	_draught("L2Draught", Rect2(7.2 * TILE, 21.5 * TILE, 2.0 * TILE, 3.0 * TILE), Vector2(-1, 0))
	_resin_cache(_root, 2.6 * TILE, 6.4 * TILE, 25.0 * TILE, 4, "ib06_l2_resin")
	_false_wall("L4Secret", Rect2i(1, 48, 5, 5), 6, Vector2i(48, 5), 1, "ib06_l4_secret")
	_draught("L4Draught", Rect2(6.2 * TILE, 49.0 * TILE, 2.0 * TILE, 3.5 * TILE), Vector2(-1, 0))
	_resin_cache(_root, 1.6 * TILE, 5.4 * TILE, 53.0 * TILE, 6, "ib06_l4_resin")
