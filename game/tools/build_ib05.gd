extends "res://tools/surface_builder.gd"
## Builds room IB-05, the Shrine Hall: the first section of the Old Crypt, and
## saves it as an ordinary scene. Re-running overwrites
## scenes/rooms/ironbark_05_shrine_hall.tscn.
##
##   godot --headless --path game --script res://tools/build_ib05.gd
##
## Spec and validation: design/rooms/ironbark_05_shrine_hall.md. After the
## creative lead's mockup docs/mockups/old_crypt/old-crypt-first-section.jpg
## ("exactly how I want that first section of the Old Crypt to look"), built
## from their crypt kit OC1 to OC8: a tall cavern of pale masonry, a gallery
## along its top, the hooded statue's island floating in it, more islands and
## ledges, a lower floor with a pit, misty ruins behind.
##
## World grid: origin at IB-01's (-56, 27). Its East door (rows 5 to 9) is
## IB-01's hall door (rows 32 to 36). Its two West doors (rows 5 to 9 and 23 to
## 27) are IB-02's two East doors; IB-02's origin is at IB-01's (-168, 27).

const ROOM_PATH := "res://scenes/rooms/ironbark_05_shrine_hall.tscn"
const IB01 := "res://scenes/rooms/ironbark_test_room.tscn"
const IB02 := "res://scenes/rooms/ironbark_02_old_crypt.tscn"

const ROOM := Rect2i(0, 0, 56, 36)
const ROCK := [[0, 0, 56, 36, 1]]
const SPACES := [
	[0, 5, 56, 5],      # the gallery along the top, door to door
	[19, 10, 5, 3],     # the break in the gallery's floor, over the shrine
	[3, 13, 50, 15],    # the cavern
	[0, 23, 3, 5],      # the lower West door
	[53, 23, 3, 5],     # the lower East door
	[26, 28, 4, 5],     # the pit in the lower floor
]
## Islands and ledges: one tile of collision under each painting's walking line.
const MASSES := [
	[6, 20, 15, 1, 1],    # the shrine island: the hooded statue
	[36, 22, 6, 1, 1],    # the arch island
	[43, 19, 5, 1, 1],    # the niche island
	[49, 16, 4, 1, 1],    # the balcony on the east wall
	[22, 15, 2, 1, 1],    # the ledge under the gallery's break, past the island's end (the way back up)
	[4, 24, 2, 1, 1],     # the ledge by the west wall, past the island's end (floor to shrine)
	[32, 25, 2, 1, 1],    # the ledge by the pit (floor to arch island)
]
## (No ledge hangs over an island or a floor she must jump from: she would hit
## its underside. Each one stands beside the island it leads to.)
const SKIP := [[6, 20, 15, 1], [36, 22, 6, 1], [43, 19, 5, 1], [49, 16, 4, 1], [22, 15, 2, 1], [4, 24, 2, 1], [32, 25, 2, 1]]
const STONE := [[0, 0, 56, 36]]
const SPAWN := Vector2(56 * 16 - 40, 10 * 16)

const OC := ENV + "oc_"
const RUINS := OC + "floating_ruins.png"
const LEDGES := OC + "gallery_ledges.png"
const PROPS := OC + "props.png"
const GALLERY := 160.0
const FLOOR := 448.0
const FLAME := Color(1.0, 0.7, 0.38)


func _initialize() -> void:
	room = ROOM
	rock = ROCK
	spaces = SPACES
	masses = MASSES
	stone = STONE
	skip = SKIP
	spawn = SPAWN
	room_path = ROOM_PATH
	_unlit = CanvasItemMaterial.new()
	_unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_add_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var tileset := _shared()
	# This room's stone is the crypt kit's pale masonry (OC1, OC2), not the plum kit.
	_stone = _material("oc", 8, 48, 37, 0.0, Color(0, 0, 0, 0))
	_stone.corner_top = load(TERRAIN + "oc_corner_top.png")
	_stone.corner_top_anchor = Vector2(60, 8)
	ResourceSaver.save(_stone, _stone.resource_path)
	_begin("IronbarkShrineHall")
	_build_far()
	var t := _terrain(tileset)
	var behind: Node = t["behind"]
	var placed: Node = t["placed"]
	_build_islands(placed)
	_hide_island_tiles()
	_dress(behind)
	_build_air(t["front"])
	_edge_shades()
	_door("East", Rect2i(48, 5, 8, 5), 1, IB01, "WestLower")
	_door("West", Rect2i(0, 5, 8, 5), -1, IB02, "East")
	_door("WestLower", Rect2i(0, 23, 8, 5), -1, IB02, "EastLower")
	# The lower East door leads on under the clearing (the Undercroft, not built).
	_door("EastLower", Rect2i(48, 23, 8, 5), 1, "", "")
	_finish()
	quit()


## OC5 and OC6: the crypt well far away in blue mist, and nearer arcades.
func _build_far() -> void:
	var far := _node(Parallax2D.new(), "Far", _root) as Parallax2D
	far.scroll_scale = Vector2(0.12, 0.12)
	far.repeat_size = Vector2(768, 0)
	far.repeat_times = 3
	far.z_index = -10
	for row in 2:
		_sprite(far, OC + "far_well.png", Rect2(0, 0, 768, 360), Vector2(0, -20 + row * 356)).name = "Art"
	var mid := _node(Parallax2D.new(), "Mid", _root) as Parallax2D
	mid.scroll_scale = Vector2(0.4, 0.5)
	mid.repeat_size = Vector2(768, 0)
	mid.repeat_times = 3
	mid.z_index = -10
	var arcades := _sprite(mid, OC + "mid_arcades.png", Rect2(0, 0, 768, 360), Vector2(-40, 120))
	arcades.name = "Art"
	arcades.modulate = Color(0.62, 0.66, 0.86, 0.9)
	var fog := _node(Parallax2D.new(), "FogMid", _root) as Parallax2D
	fog.scroll_scale = Vector2(0.55, 0.6)
	fog.z_index = -10
	_fog(fog, Rect2(-200, 200, 1500, 320), Color("#5a6a9a"), 0.3, Vector2(0.005, 0.0))


## A painting on its collision: `line` is the walking line's row in the region,
## and [x0, x1] its extent there. Centred on the mass [tile_x, row, tiles].
func _on_mass(parent: Node, tex: String, region: Rect2, line: int, x0: int, x1: int, tile_x: int, row: int, tiles: int) -> Sprite2D:
	var x: float = tile_x * TILE + (tiles * TILE - float(x1 - x0 + 1)) * 0.5 - x0
	return _sprite(parent, tex, region, Vector2(x, row * TILE - line))


func _build_islands(placed: Node) -> void:
	_on_mass(placed, RUINS, Rect2(16, 11, 240, 79), 32, 1, 239, 6, 20, 15).name = "ShrineIsland"
	_on_mass(placed, RUINS, Rect2(33, 114, 94, 60), 27, 1, 93, 36, 22, 6).name = "ArchIsland"
	_on_mass(placed, RUINS, Rect2(241, 112, 79, 61), 29, 0, 77, 43, 19, 5).name = "NicheIsland"
	var bal := _on_mass(placed, LEDGES, Rect2(17, 16, 78, 62), 31, 6, 69, 49, 16, 4)
	bal.name = "Balcony"
	bal.flip_h = true
	_on_mass(placed, LEDGES, Rect2(144, 22, 47, 29), 12, 8, 38, 22, 15, 2).name = "Ledge"
	_on_mass(placed, LEDGES, Rect2(193, 81, 31, 25), 6, 6, 29, 4, 24, 2).name = "Ledge"
	_on_mass(placed, LEDGES, Rect2(193, 81, 31, 25), 6, 6, 29, 32, 25, 2).flip_h = true


func _prop(parent: Node, region: Rect2, x: float, floor_y: float, prop_name: String) -> Sprite2D:
	return _ground(parent, PROPS, region, x, floor_y + 1.0, 1.0, prop_name)


func _brazier(parent: Node, x: float, floor_y: float) -> void:
	_prop(parent, Rect2(102, 165, 16, 26), x, floor_y, "Brazier")
	_light(parent, Vector2(x + 8, floor_y - 22), FLAME, 1.1, 1.0, "BrazierLight")


func _candle(parent: Node, x: float, floor_y: float) -> void:
	_prop(parent, Rect2(133, 163, 9, 28), x, floor_y, "Candle")
	_light(parent, Vector2(x + 4, floor_y - 26), FLAME, 0.8, 0.6, "CandleLight")


func _dress(behind: Node) -> void:
	# The shrine: the hooded statue between two braziers.
	_prop(behind, Rect2(192, 144, 47, 95), 184, 320, "HoodedStatue")
	_brazier(behind, 148, 320)
	_brazier(behind, 248, 320)
	_prop(behind, Rect2(77, 202, 19, 14), 112, 320, "Mushrooms")
	_prop(behind, Rect2(110, 206, 11, 8), 292, 320, "Mushrooms")
	# The gallery: burial niches along its wall, candles by the doors.
	for x in [96.0, 208.0, 448.0, 560.0, 672.0]:
		_prop(behind, Rect2(1 + 56 * (int(x) / 100 % 3), 1, 46, 39), x, GALLERY, "Niche").modulate = Color(0.86, 0.86, 0.94)
	_candle(behind, 60, GALLERY)
	_candle(behind, 400, GALLERY)
	_candle(behind, 820, GALLERY)
	_breakable(ENV + "props_guard_belongings.png", POT, 520.0, GALLERY, CLAY)
	_breakable(ENV + "props_guard_belongings.png", POT_SMALL, 536.0, GALLERY, CLAY)
	# The lower floor: the dead on their biers, bones, mushrooms.
	_prop(behind, Rect2(2, 91, 77, 28), 150, FLOOR, "Bier")
	_prop(behind, Rect2(89, 92, 78, 26), 600, FLOOR, "Bier")
	_prop(behind, Rect2(41, 46, 46, 21), 300, FLOOR, "Bones")
	_prop(behind, Rect2(1, 52, 30, 13), 700, FLOOR, "Bones")
	_prop(behind, Rect2(77, 202, 19, 14), 250, FLOOR, "Mushrooms")
	_prop(behind, Rect2(77, 202, 19, 14), 560, FLOOR, "Mushrooms")
	_prop(behind, Rect2(110, 206, 11, 8), 690, FLOOR, "Mushrooms")
	_candle(behind, 70, FLOOR)
	_candle(behind, 800, FLOOR)
	_breakable(ENV + "props_guard_belongings.png", POT_BIG, 760.0, FLOOR, CLAY)
	_breakable(ENV + "props_guard_belongings.png", POT, 780.0, FLOOR, CLAY)
	# The balcony: pots someone stored out of reach.
	_breakable(ENV + "props_guard_belongings.png", POT, 820.0, 256.0, CLAY)
	# Roots hanging from the gallery's underside.
	for r in [[Rect2(130, 218, 13, 29), 120.0], [Rect2(102, 224, 8, 22), 470.0], [Rect2(130, 218, 13, 29), 640.0]]:
		_sprite(behind, PROPS, r[0], Vector2(r[1], 13 * TILE + 4)).name = "Roots"


func _build_air(front: Node) -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.74, 0.75, 0.92)
	_fog(_root, Rect2(48, 380, 800, 70), Color("#6a7ab0"), 0.26, Vector2(0.005, 0.0))
	var dust := _particles("Dust", load("res://assets/fx/mote.png"), 30, 9.0, Rect2(48, 80, 800, 380))
	dust.color = Color(0.8, 0.86, 1.0, 0.7)
	dust.gravity = Vector2(0, 3)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 6.0
	dust.spread = 180.0
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.0
	dust.material = _add_mat
	dust.z_index = 14
	# OC7: dark stone and roots nearest the camera, along the room's top and bottom.
	var p := _node(Parallax2D.new(), "Foreground", _root) as Parallax2D
	p.scroll_scale = Vector2(1.15, 1.0)
	p.repeat_size = Vector2(768, 0)
	p.repeat_times = 3
	p.z_index = 30
	var top := _sprite(p, OC + "foreground.png", Rect2(0, 0, 768, 96), Vector2(0, -6))
	top.name = "Top"
	top.material = _unlit
	var bottom := _sprite(p, OC + "foreground.png", Rect2(0, 250, 768, 110), Vector2(0, 36 * TILE - 104))
	bottom.name = "Bottom"
	bottom.material = _unlit
