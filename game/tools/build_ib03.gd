extends "res://tools/room_builder.gd"
## Builds room IB-03, the Guard Post (the game's opening room), from the plan
## below, with the shared tools in room_builder.gd, and saves it as an ordinary
## scene. Re-running this script overwrites scenes/rooms/ironbark_03_guard_post.tscn.
##
##   godot --headless --path game --script res://tools/build_ib03.gd
##
## Spec and validation: design/rooms/ironbark_03_guard_post.md.
## THIS IS THE BLOCKOUT: collision, doors, the brook and the two seals. No props,
## no lights, no set pieces until the creative lead approves the shape.
##
## In the world grid this room lies west of IB-01 and 13 tiles higher: its East
## door (rows 32 to 36) is IB-01's west upper exit (rows 19 to 23). The Old
## Crypt (IB-02) lies straight below it: this room's well (x 47 to 54) is the
## mouth of IB-02's Root Well.

const ROOM_PATH := "res://scenes/rooms/ironbark_03_guard_post.tscn"
const IB01 := "res://scenes/rooms/ironbark_test_room.tscn"

# --- The room plan (tiles) ---------------------------------------------------------
## "The guard's post on its hill, empty; three terraces step down to the yard
##  and the road east, under a great branch that crosses the whole sky."
const ROOM := Rect2i(0, 0, 112, 40)
## Rock: [x, y, w, h, material]. The ground is a hill falling east in three
## long terraces, four tiles apiece: floors, not stairs.
const ROCK := [
	[0, 0, 6, 40, 0],      # the hill's back: a cliff rising out of the room
	[6, 25, 24, 15, 0],    # the hilltop: the guardhouse stands here (the start)
	[30, 29, 14, 11, 0],   # the upper terrace
	[44, 33, 16, 7, 0],    # the well terrace
	[60, 37, 52, 3, 0],    # the yard and the road east
]
## Spaces carved out of the rock.
const SPACES := [
	[0, 20, 6, 5],     # the road cut through the cliff: the West door (the forest road)
	[47, 33, 8, 7],    # the well: the mouth of the Old Crypt's Root Well (lidded)
	[76, 37, 4, 2],    # the brook across the yard (the footbridge is down)
]
## Masses put back: [x, y, w, h, material]
const MASSES := [
	[33, 22, 14, 2, 0],   # the ruin island off the hilltop's brink (upper line)
	[51, 21, 34, 2, 0],   # the great branch: a walk across the upper air
	[97, 18, 10, 2, 0],   # the far island past the branch's end (Wing-Cloak)
]
const STONE := []
const SKIP := []
const BACK := []
const BACK_EARTH := [[0, 20, 6, 5], [47, 34, 8, 6]]

## The start of the game: on the hilltop, outside the guardhouse.
const SPAWN := Vector2(14 * 16, 25 * 16)


func _initialize() -> void:
	room = ROOM
	rock = ROCK
	spaces = SPACES
	masses = MASSES
	stone = STONE
	skip = SKIP
	back = BACK
	back_earth = BACK_EARTH
	spawn = SPAWN
	room_path = ROOM_PATH
	var tileset := _shared()
	_begin("IronbarkGuardPost")
	# A flat dusk sky behind the blockout, so the shapes read. Not art.
	var sky := _node(Parallax2D.new(), "Backdrop", _root) as Parallax2D
	sky.scroll_scale = Vector2.ZERO
	sky.z_index = -20
	var fill := _node(ColorRect.new(), "Fill", sky) as ColorRect
	fill.color = Color("#33415f")
	fill.size = Vector2(640, 360)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_walls()
	_terrain(tileset)
	_build_seals()
	# The brook: shallow water she can't cross on foot. A four-tile jump.
	var brook := _water("Brook", Vector2(76 * TILE, 37 * TILE + 5), Vector2(4 * TILE, 2 * TILE - 5), Vector2(32, 14))
	brook.get_node("Glint").visible = false  # nothing lies under it: not a lock
	_edge_shades()
	# East: down the road to the Lantern Clearing's terrace (IB-01).
	_door("East", Rect2i(104, 32, 8, 5), 1, IB01, "WestUpper")
	# West: the forest road. Its room isn't built, so it is a place to arrive at
	# with no way through yet.
	_door("West", Rect2i(0, 20, 6, 5), -1, "", "")
	_finish()
	quit()


## The well's lid (Ironbark Ward: a bark-plate she can't break yet). Below it the
## shaft falls into the Old Crypt.
func _build_seals() -> void:
	var lid := _node(StaticBody2D.new(), "WellLid", _root) as StaticBody2D
	lid.position = Vector2(47 * TILE, 33 * TILE)
	lid.z_index = 8
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8 * TILE, TILE)
	shape.shape = rect
	shape.position = Vector2(4 * TILE, 0.5 * TILE)
	_node(shape, "Shape", lid)
	var slab := _node(ColorRect.new(), "Blockout", lid) as ColorRect
	slab.color = Color("#7a5a3c")
	slab.size = Vector2(8 * TILE, TILE)
	slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
