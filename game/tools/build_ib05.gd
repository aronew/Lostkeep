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
const SH := ENV + "sh_"
const PLAT := SH + "platforms.png"
const FLORA2 := SH + "flora.png"
const DOORS := SH + "doorways.png"
const ARC := SH + "arcades.png"
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
	# The hall's masonry: the creative lead's SH1 and SH2 (pale blue-grey blocks).
	_stone = _material("sh", 8, 48, 37, 0.0, Color(0, 0, 0, 0))
	_stone.corner_top = load(TERRAIN + "sh_corner_top.png")
	_stone.corner_top_anchor = Vector2(36, 29)
	_stone.corner_under = load(TERRAIN + "sh_corner_under.png")
	_stone.corner_under_anchor = Vector2(42, 42)
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


## SH8: the distant hall in blue mist, behind everything.
func _build_far() -> void:
	var far := _node(Parallax2D.new(), "Far", _root) as Parallax2D
	far.scroll_scale = Vector2(0.2, 0.2)
	far.repeat_size = Vector2(768, 0)
	far.repeat_times = 3
	far.z_index = -10
	for row in 2:
		_sprite(far, SH + "far.png", Rect2(0, 0, 768, 360), Vector2(0, -40 + row * 358)).name = "Art"
	var fog := _node(Parallax2D.new(), "FogMid", _root) as Parallax2D
	fog.scroll_scale = Vector2(0.55, 0.6)
	fog.z_index = -10
	_fog(fog, Rect2(-200, 200, 1500, 320), Color("#7a88b8"), 0.16, Vector2(0.005, 0.0))


## A painting on its collision: `line` is the walking line's row in the region,
## and [x0, x1] its extent there. Centred on the mass [tile_x, row, tiles].
func _on_mass(parent: Node, tex: String, region: Rect2, line: int, x0: int, x1: int, tile_x: int, row: int, tiles: int) -> Sprite2D:
	var x: float = tile_x * TILE + (tiles * TILE - float(x1 - x0 + 1)) * 0.5 - x0
	return _sprite(parent, tex, region, Vector2(x, row * TILE - line))


# The creative lead's SH3 and SH4 pieces: [region, walking line row, line x0, line x1].
const SHRINE_ISLAND := [Rect2(0, 0, 384, 192), 80, 73, 310]
const ARCH_ISLAND := [Rect2(8, 8, 96, 88), 50, 0, 95]
const PLATES := [[Rect2(144, 24, 32, 32), 7, 5, 27], [Rect2(208, 24, 32, 32), 7, 4, 30], [Rect2(272, 24, 32, 32), 5, 2, 30]]
const WALL_LEDGE_FLOWERS := [Rect2(8, 120, 64, 56), 16, 0, 63]
const WALL_LEDGE_POTS := [Rect2(104, 120, 64, 56), 16, 0, 63]
const BROKEN_LEDGE := [Rect2(208, 128, 32, 32), 3, 0, 31]
const PEDESTAL := [Rect2(304, 96, 32, 80), 7, 2, 29]


func _piece_on(parent: Node, tex: String, spec: Array, m: Array, flip := false) -> Sprite2D:
	var sp := _on_mass(parent, tex, spec[0], spec[1], spec[2], spec[3], m[0], m[1], m[2])
	sp.flip_h = flip
	return sp


func _build_islands(placed: Node) -> void:
	_piece_on(placed, SH + "shrine_island.png", SHRINE_ISLAND, MASSES[0]).name = "ShrineIsland"
	_piece_on(placed, PLAT, BROKEN_LEDGE, MASSES[1]).name = "WestIsland"
	_piece_on(placed, PLAT, PEDESTAL, MASSES[2]).name = "Pedestal"
	_piece_on(placed, PLAT, WALL_LEDGE_FLOWERS, MASSES[3]).name = "WestWallLedge"
	_piece_on(placed, PLAT, BROKEN_LEDGE, MASSES[4], true).name = "Nook"
	_piece_on(placed, PLAT, PLATES[0], MASSES[5], true).name = "PitLedge"
	for i in 3:
		_piece_on(placed, PLAT, PLATES[i], MASSES[6 + i]).name = "Plate"
	_piece_on(placed, PLAT, ARCH_ISLAND, MASSES[9]).name = "ArchIsland"
	_piece_on(placed, PLAT, PLATES[1], MASSES[10], true).name = "GapLedge"
	_piece_on(placed, PLAT, WALL_LEDGE_POTS, MASSES[11], true).name = "EastShelf"


func _prop(parent: Node, region: Rect2, x: float, floor_y: float, prop_name: String) -> Sprite2D:
	return _ground(parent, PROPS, region, x, floor_y + 1.0, 1.0, prop_name)


func _brazier(parent: Node, x: float, floor_y: float) -> void:
	_prop(parent, Rect2(102, 165, 16, 26), x, floor_y, "Brazier")
	_light(parent, Vector2(x + 8, floor_y - 22), FLAME, 1.1, 1.0, "BrazierLight")


func _candle(parent: Node, x: float, floor_y: float) -> void:
	_prop(parent, Rect2(133, 163, 9, 28), x, floor_y, "Candle")
	_light(parent, Vector2(x + 4, floor_y - 26), FLAME, 0.8, 0.6, "CandleLight")


func _sh(parent: Node, tex: String, region: Rect2, x: float, floor_y: float, piece_name: String, flip := false) -> Sprite2D:
	var sp := _ground(parent, tex, region, x, floor_y + 1.0, 1.0, piece_name)
	sp.flip_h = flip
	return sp


func _torch(parent: Node, x: float, y: float) -> void:
	_sprite(parent, DOORS, Rect2(48, 160, 16, 32), Vector2(x, y)).name = "Torch"
	_light(parent, Vector2(x + 8, y + 6), FLAME, 1.0, 0.8, "TorchLight")


## A lit doorway at a door: the arch, the blue corridor beyond, a torch beside it.
func _doorway(parent: Node, x: float, floor_y: float, flip: bool, ruined := false) -> void:
	_sh(parent, DOORS, Rect2(144 if ruined else 16, 16, 80, 96), x, floor_y, "Doorway", flip)
	_light(parent, Vector2(x + 40, floor_y - 40), Color(0.55, 0.7, 1.0), 0.6, 0.9, "DoorwayGlow")
	_torch(parent, x + (-14.0 if flip else 82.0), floor_y - 56)


func _dress(behind: Node) -> void:
	var bag := ENV + "props_guard_belongings.png"
	# The four doorways.
	_doorway(behind, -18, WEST, false)
	_doorway(behind, 58 * 16 - 62, LANDING, true)
	_doorway(behind, -18, FLOOR, false, true)
	_doorway(behind, 58 * 16 - 62, FLOOR, true)
	# The west gallery: a single arch, pots, crystals and flowers.
	_sh(behind, ARC, Rect2(144, 32, 64, 80), 120, WEST, "Arch")
	_sh(behind, ARC, Rect2(304, 88, 40, 24), 200, WEST, "Pots")
	_sh(behind, FLORA2, Rect2(8, 72, 32, 20), 250, WEST, "Flowers")
	# The east gallery: the arcade, pillars, the chest, pots, crystals.
	_sh(behind, ARC, Rect2(4, 32, 128, 80), 430, EAST, "Arcade")
	_sh(behind, ARC, Rect2(272, 32, 20, 80), 380, EAST, "Pillar")
	_sh(behind, ARC, Rect2(352, 96, 24, 16), 600, EAST, "Chest")
	_sh(behind, FLORA2, Rect2(64, 64, 48, 28), 630, EAST, "Flowers")
	_breakable(bag, POT, 690.0, EAST, CLAY)
	_breakable(bag, POT_SMALL, 706.0, EAST, CLAY)
	_sh(behind, FLORA2, Rect2(8, 16, 32, 24), 830, LANDING, "Crystals")
	# The lower floor: pillars and arches, crystal heaps, flowers, the dead on their biers.
	_sh(behind, ARC, Rect2(144, 32, 64, 80), 640, FLOOR, "Arch")
	_sh(behind, ARC, Rect2(248, 56, 16, 56), 120, FLOOR, "Pillar")
	_sh(behind, ARC, Rect2(224, 80, 16, 32), 560, FLOOR, "Pillar")
	_sh(behind, FLORA2, Rect2(152, 0, 64, 40), 540, FLOOR, "Crystals")
	_sh(behind, FLORA2, Rect2(64, 8, 48, 32), 230, DIP, "Crystals")
	_sh(behind, FLORA2, Rect2(152, 56, 64, 36), 290, DIP, "Flowers")
	_sh(behind, FLORA2, Rect2(64, 64, 48, 28), 740, FLOOR, "Flowers")
	_sh(behind, FLORA2, Rect2(16, 208, 48, 24), 40, FLOOR, "Grass")
	_sh(behind, FLORA2, Rect2(112, 208, 48, 24), 880, FLOOR, "WhiteFlowers")
	_prop(behind, Rect2(2, 91, 77, 28), 360, DIP, "Bier")
	_prop(behind, Rect2(41, 46, 46, 21), 700, FLOOR, "Bones")
	_breakable(bag, POT, 800.0, FLOOR, CLAY)
	_breakable(bag, POT_BIG, 820.0, FLOOR, CLAY)
	# Something left on the ledges.
	_breakable(bag, POT_SMALL, 80.0, 256.0, CLAY)
	_breakable(bag, POT_SMALL, 368.0, 352.0, CLAY)
	# Ivy and roots hanging from the galleries' undersides.
	for r in [[Rect2(88, 112, 24, 64), 90.0], [Rect2(184, 112, 16, 32), 230.0], [Rect2(48, 112, 16, 32), 300.0],
			[Rect2(224, 112, 20, 64), 400.0], [Rect2(88, 112, 24, 64), 560.0], [Rect2(184, 112, 16, 32), 650.0],
			[Rect2(48, 112, 16, 32), 860.0]]:
		_sprite(behind, FLORA2, r[0], Vector2(r[1], 11 * TILE - 2)).name = "Hanging"


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
