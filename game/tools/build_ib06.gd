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
	_build_lights(t["behind"])
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


## Blockout light only: enough to read the spaces in the review shots.
func _build_lights(behind: Node) -> void:
	for p in [Vector2(6, 12), Vector2(30, 12), Vector2(10, 22), Vector2(30, 24), Vector2(6, 34), Vector2(30, 35),
			Vector2(9, 49), Vector2(30, 47), Vector2(7, 61), Vector2(32, 61), Vector2(17, 60), Vector2(17, 30)]:
		_light(behind, Vector2(p.x * TILE, p.y * TILE), LAMP, 0.9, 1.4, "BlockoutLight")


## Two secret rooms, each behind a false wall at the back of a lantern room on
## the west side. Tells: motes drifting into the wall.
func _build_secrets() -> void:
	_false_wall("L2Secret", Rect2i(2, 21, 5, 4), 7, Vector2i(21, 4), 1, "ib06_l2_secret")
	_draught("L2Draught", Rect2(7.2 * TILE, 21.5 * TILE, 2.0 * TILE, 3.0 * TILE), Vector2(-1, 0))
	_resin_cache(_root, 2.6 * TILE, 6.4 * TILE, 25.0 * TILE, 4, "ib06_l2_resin")
	_false_wall("L4Secret", Rect2i(1, 48, 5, 5), 6, Vector2i(48, 5), 1, "ib06_l4_secret")
	_draught("L4Draught", Rect2(6.2 * TILE, 49.0 * TILE, 2.0 * TILE, 3.5 * TILE), Vector2(-1, 0))
	_resin_cache(_root, 1.6 * TILE, 5.4 * TILE, 53.0 * TILE, 6, "ib06_l4_resin")
