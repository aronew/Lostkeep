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
## to 25); its lower West door (rows 32 to 36) leads to the pit shaft under
## IB-05 (IB-07); its lower East door leads on toward the Lost Keep.

const ROOM_PATH := "res://scenes/rooms/ironbark_06_undercroft.tscn"
const IB05 := "res://scenes/rooms/ironbark_05_shrine_hall.tscn"
const IB07 := "res://scenes/rooms/ironbark_07_pit_shaft.tscn"

# --- The room plan (tiles) ---------------------------------------------------------
## "The guard's cellars under the clearing, broken open by the Great Ironbark's
##  roots: three floors stacked like a ploughed field (east, back west, east
##  again), a tall root chamber at the turn, a lift that folds the bottom back
##  to the door you came in by."
const ROOM := Rect2i(0, 0, 96, 40)
const ROCK := [[0, 0, 96, 40, 1]]
const SPACES := [
	[0, 11, 46, 5],     # F1, the storeroom gallery: in from the Shrine Hall, east (floor row 16)
	[46, 4, 30, 22],    # the root chamber: the turn, its floor row 26
	[76, 4, 20, 5],     # high in the chamber's east wall: a passage on (Barkgrip, far above any jump)
	[10, 21, 36, 5],    # F2, the root passage: back west under F1 (floor row 26)
	[10, 26, 4, 6],     # F2 ends in a collapse, down into F3
	[0, 32, 96, 5],     # F3, the cistern walk: east again (floor row 37)
	[2, 16, 4, 16],     # the lift's shaft: F3 up to F1, beside the door (a shortcut)
	[57, 37, 4, 3],     # the sump in F3's floor: dark water, going on down (Deep-Glow Breath)
]
## The chamber's two root masses: the climb back up from its floor to F1,
## each beside the next, never over it (floor 26 -> 22 -> 19 -> F1's 16).
const MASSES := [
	[62, 22, 8, 2, 1],
	[50, 19, 8, 2, 1],
]
const STONE := [[0, 0, 96, 40]]
const SKIP := []
const SPAWN := Vector2(8 * 16, 16 * 16)
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
	_crypt_foreground()
	_edge_shades()
	_door("West", Rect2i(0, 12, 8, 4), -1, IB05, "EastLower")
	_door("WestLower", Rect2i(0, 32, 8, 5), -1, IB07, "East")
	# High in the chamber's east wall (Barkgrip), and the lower East door on
	# toward the Lost Keep: neither room is built.
	_door("EastHigh", Rect2i(88, 4, 8, 5), 1, "", "")
	_door("EastLower", Rect2i(88, 32, 8, 5), 1, "", "")
	_finish()
	quit()


func _build_machines() -> void:
	# The cellar lift: jammed at the top (its deck plugs F1's floor beside the
	# door); from F3, the winch frees it, and it carries her back up to F1.
	_lift("CellarLift", Vector2(4 * TILE, 16 * TILE), 21.0 * TILE, 4.0 * TILE, "ib06_lift")
	# The sump: dark water she can't swim yet, a glint going on down.
	_water("Sump", Vector2(57 * TILE, 37 * TILE + 4), Vector2(4 * TILE, 3 * TILE - 4), Vector2(59.0 * TILE, 39 * TILE))


## Blockout light only: enough to read the spaces in the review shots.
func _build_lights(behind: Node) -> void:
	for p in [Vector2(20, 13), Vector2(38, 13), Vector2(60, 15), Vector2(30, 23), Vector2(16, 34),
			Vector2(44, 34), Vector2(76, 34), Vector2(90, 6)]:
		_light(behind, Vector2(p.x * TILE, p.y * TILE), LAMP, 0.9, 1.4, "BlockoutLight")
