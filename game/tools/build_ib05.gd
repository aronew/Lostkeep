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
## World grid: origin at IB-01's (-58, 30). Its East door (rows 2 to 6) is
## IB-01's hall door (rows 32 to 36). Its two West doors (rows 3 to 7 and 21 to
## 25) are IB-02's two East doors; IB-02's origin is at IB-01's (-170, 28).
##
## The layout follows the mockup's: two upper galleries with a gap between them
## (a shaft above it), the shrine island on the left of the cavern, three small
## stone plates rising to the arch island on the right, ledges on both walls, a
## pedestal on a column, a lower floor that dips and has a pit, four doors.

const ROOM_PATH := "res://scenes/rooms/ironbark_05_shrine_hall.tscn"
const IB01 := "res://scenes/rooms/ironbark_test_room.tscn"
const IB02 := "res://scenes/rooms/ironbark_02_old_crypt.tscn"

const ROOM := Rect2i(0, 0, 58, 34)
const ROCK := [[0, 0, 58, 34, 1]]
const SPACES := [
	[0, 3, 19, 5],      # the west gallery (its floor row 8), to the upper West door
	[19, 0, 3, 3],      # the shaft above the galleries' gap, going up out of sight
	[19, 3, 3, 8],      # the gap between the galleries, open down into the hall
	[22, 4, 24, 5],     # the east gallery (floor row 9)
	[46, 2, 4, 9],      # the gap by the East door, open down into the hall
	[50, 2, 8, 5],      # the landing at the East door (floor row 7)
	[3, 11, 51, 15],    # the hall (its floor row 26)
	[0, 21, 3, 5],      # the lower West door
	[54, 22, 4, 4],     # the lower East door, under the shelf
	[15, 26, 10, 1],    # the dip in the lower floor (row 27)
	[29, 26, 4, 5],     # the pit
]
## Islands, plates and ledges: one tile of collision under each painting's
## walking line. Each ledge stands beside what it leads to, never over it.
const MASSES := [
	[13, 17, 15, 1, 1],   # the shrine island: the hooded statue
	[7, 20, 2, 1, 1],     # the small island west of the shrine
	[10, 22, 2, 1, 1],    # the pedestal on its column
	[3, 16, 4, 1, 1],     # the ledge on the west wall
	[22, 22, 2, 1, 1],    # the nook under the shrine
	[29, 22, 2, 1, 1],    # the ledge over the pit
	[31, 18, 2, 1, 1],    # three small stone plates, rising east
	[34, 17, 2, 1, 1],
	[37, 16, 2, 1, 1],
	[41, 18, 6, 1, 1],    # the arch island
	[47, 13, 2, 1, 1],    # the ledge under the east gap (the way back up)
	[50, 21, 4, 1, 1],    # the shelf on the east wall, over the lower East door
]
const SKIP := [[13, 17, 15, 1], [7, 20, 2, 1], [10, 22, 2, 1], [3, 16, 4, 1], [22, 22, 2, 1], [29, 22, 2, 1],
	[31, 18, 2, 1], [34, 17, 2, 1], [37, 16, 2, 1], [41, 18, 6, 1], [47, 13, 2, 1], [50, 21, 4, 1]]
const STONE := [[0, 0, 58, 34]]
const SPAWN := Vector2(58 * 16 - 40, 7 * 16)

const OC := ENV + "oc_"
const RUINS := OC + "floating_ruins.png"
const LEDGES := OC + "gallery_ledges.png"
const PROPS := OC + "props.png"
const WEST := 128.0     # the west gallery
const EAST := 144.0     # the east gallery
const LANDING := 112.0
const SHRINE := 272.0
const FLOOR := 416.0
const DIP := 432.0
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
	_door("East", Rect2i(50, 2, 8, 5), 1, IB01, "WestLower")
	_door("West", Rect2i(0, 3, 8, 5), -1, IB02, "East")
	_door("WestLower", Rect2i(0, 21, 8, 5), -1, IB02, "EastLower")
	# The lower East door leads on under the clearing (the Undercroft, not built).
	_door("EastLower", Rect2i(50, 22, 8, 4), 1, "", "")
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
	arcades.modulate = Color(0.72, 0.78, 0.98, 0.9)
	var fog := _node(Parallax2D.new(), "FogMid", _root) as Parallax2D
	fog.scroll_scale = Vector2(0.55, 0.6)
	fog.z_index = -10
	_fog(fog, Rect2(-200, 200, 1500, 320), Color("#6a7ab0"), 0.2, Vector2(0.005, 0.0))


## A painting on its collision: `line` is the walking line's row in the region,
## and [x0, x1] its extent there. Centred on the mass [tile_x, row, tiles].
func _on_mass(parent: Node, tex: String, region: Rect2, line: int, x0: int, x1: int, tile_x: int, row: int, tiles: int) -> Sprite2D:
	var x: float = tile_x * TILE + (tiles * TILE - float(x1 - x0 + 1)) * 0.5 - x0
	return _sprite(parent, tex, region, Vector2(x, row * TILE - line))


const ISLAND_BIG := [Rect2(16, 11, 240, 79), 32, 1, 239]
const ISLAND_ARCH := [Rect2(33, 114, 94, 60), 27, 1, 93]
const BALCONY := [Rect2(17, 16, 78, 62), 31, 6, 69]
const LEDGE := [Rect2(144, 22, 47, 29), 12, 8, 38]
const PLATE := [Rect2(193, 81, 31, 25), 6, 6, 29]


func _piece_on(parent: Node, tex: String, spec: Array, m: Array, flip := false) -> Sprite2D:
	var sp := _on_mass(parent, tex, spec[0], spec[1], spec[2], spec[3], m[0], m[1], m[2])
	sp.flip_h = flip
	return sp


func _build_islands(placed: Node) -> void:
	_piece_on(placed, RUINS, ISLAND_BIG, MASSES[0]).name = "ShrineIsland"
	_piece_on(placed, LEDGES, LEDGE, MASSES[1]).name = "WestIsland"
	_piece_on(placed, LEDGES, LEDGE, MASSES[2], true).name = "Pedestal"
	_piece_on(placed, LEDGES, BALCONY, MASSES[3]).name = "WestWallLedge"
	_piece_on(placed, LEDGES, PLATE, MASSES[4]).name = "Nook"
	_piece_on(placed, LEDGES, PLATE, MASSES[5], true).name = "PitLedge"
	for i in 3:
		_piece_on(placed, LEDGES, PLATE, MASSES[6 + i], i == 1).name = "Plate"
	_piece_on(placed, RUINS, ISLAND_ARCH, MASSES[9]).name = "ArchIsland"
	_piece_on(placed, LEDGES, LEDGE, MASSES[10]).name = "GapLedge"
	_piece_on(placed, LEDGES, BALCONY, MASSES[11], true).name = "EastShelf"


func _prop(parent: Node, region: Rect2, x: float, floor_y: float, prop_name: String) -> Sprite2D:
	return _ground(parent, PROPS, region, x, floor_y + 1.0, 1.0, prop_name)


func _brazier(parent: Node, x: float, floor_y: float) -> void:
	_prop(parent, Rect2(102, 165, 16, 26), x, floor_y, "Brazier")
	_light(parent, Vector2(x + 8, floor_y - 22), FLAME, 1.1, 1.0, "BrazierLight")


func _candle(parent: Node, x: float, floor_y: float) -> void:
	_prop(parent, Rect2(133, 163, 9, 28), x, floor_y, "Candle")
	_light(parent, Vector2(x + 4, floor_y - 26), FLAME, 0.8, 0.6, "CandleLight")


func _dress(behind: Node) -> void:
	var bag := ENV + "props_guard_belongings.png"
	# The shrine: the hooded statue between two braziers.
	_prop(behind, Rect2(192, 144, 47, 95), 305, SHRINE, "HoodedStatue")
	_brazier(behind, 262, SHRINE)
	_brazier(behind, 364, SHRINE)
	_prop(behind, Rect2(77, 202, 19, 14), 220, SHRINE, "Mushrooms")
	_prop(behind, Rect2(110, 206, 11, 8), 420, SHRINE, "Mushrooms")
	# The pedestal's column, down to the floor.
	_sprite(behind, OC + "walls_corners.png", Rect2(225, 0, 31, 56), Vector2(161, 360)).name = "PedestalColumn"
	# The west gallery: the doorway's candles, burial niches, the guard's pots.
	_candle(behind, 40, WEST)
	_prop(behind, Rect2(1, 1, 46, 39), 96, WEST, "Niche").modulate = Color(0.88, 0.9, 0.98)
	_prop(behind, Rect2(112, 1, 47, 39), 200, WEST, "Niche").modulate = Color(0.88, 0.9, 0.98)
	_breakable(bag, POT, 160.0, WEST, CLAY)
	_breakable(bag, POT_SMALL, 176.0, WEST, CLAY)
	_candle(behind, 280, WEST)
	# The east gallery.
	for x in [380.0, 500.0, 620.0]:
		_prop(behind, Rect2(1 + 56 * (int(x) / 120 % 3), 1, 46, 39), x, EAST, "Niche").modulate = Color(0.88, 0.9, 0.98)
	_candle(behind, 450, EAST)
	_candle(behind, 690, EAST)
	_breakable(bag, POT, 568.0, EAST, CLAY)
	_breakable(bag, CRATE_B, 590.0, EAST, WOOD)
	# The landing by the East door.
	_candle(behind, 830, LANDING)
	_candle(behind, 900, LANDING)
	# The lower floor: the dead on their biers, bones, mushrooms; pots on the ledges.
	_prop(behind, Rect2(2, 91, 77, 28), 50, FLOOR, "Bier")
	_prop(behind, Rect2(41, 46, 46, 21), 270, DIP, "Bones")
	_prop(behind, Rect2(89, 92, 78, 26), 560, FLOOR, "Bier")
	_prop(behind, Rect2(1, 52, 30, 13), 660, FLOOR, "Bones")
	_prop(behind, Rect2(77, 202, 19, 14), 330, DIP, "Mushrooms")
	_prop(behind, Rect2(110, 206, 11, 8), 720, FLOOR, "Mushrooms")
	_candle(behind, 20, FLOOR)
	_candle(behind, 236, FLOOR)
	_candle(behind, 890, FLOOR)
	_breakable(bag, POT, 72.0, 256.0, CLAY)
	_breakable(bag, POT_SMALL, 360.0, 352.0, CLAY)
	_breakable(bag, POT_BIG, 832.0, 336.0, CLAY)
	_breakable(bag, POT, 852.0, 336.0, CLAY)
	# Roots and vines hanging from the galleries' undersides.
	for r in [[Rect2(130, 218, 13, 29), 100.0, 11], [Rect2(102, 224, 8, 22), 260.0, 11], [Rect2(130, 218, 13, 29), 420.0, 11],
			[Rect2(102, 224, 8, 22), 600.0, 11], [Rect2(130, 218, 13, 29), 870.0, 11]]:
		_sprite(behind, PROPS, r[0], Vector2(r[1], r[2] * TILE + 2)).name = "Roots"


func _build_air(front: Node) -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.88, 0.9, 1.0)
	_fog(_root, Rect2(48, 350, 800, 70), Color("#7a8ac0"), 0.18, Vector2(0.005, 0.0))
	var dust := _particles("Dust", load("res://assets/fx/mote.png"), 30, 9.0, Rect2(48, 60, 820, 360))
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
	var bottom := _sprite(p, OC + "foreground.png", Rect2(0, 250, 768, 110), Vector2(0, 34 * TILE - 96))
	bottom.name = "Bottom"
	bottom.material = _unlit
