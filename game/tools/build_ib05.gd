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
const IB06 := "res://scenes/rooms/ironbark_06_undercroft.tscn"

const ROOM := Rect2i(0, 0, 58, 34)
const ROCK := [[0, 0, 58, 34, 1]]
const SPACES := [
	# The galleries step, floor and ceiling, as in the creative lead's moody
	# mockup of this room (docs/mockups/mood/shrine_hall_moody.webp), never one
	# straight corridor.
	[0, 3, 14, 5],      # the west gallery (its floor row 8), to the upper West door
	[8, 2, 5, 1],       # its ceiling rises a course in the middle
	[14, 3, 5, 4],      # and its floor steps up toward the gap (row 7)
	[19, 0, 3, 3],      # the shaft above the galleries' gap, going up out of sight
	[19, 3, 3, 8],      # the gap between the galleries, open down into the hall
	[22, 3, 4, 5],      # the east gallery: its west end, floor row 8, ceiling row 3
	[26, 4, 3, 4],      # under a bulkhead (ceiling row 4)
	[29, 3, 9, 6],      # the tall bay with the arcade, a step down (floor row 9)
	[38, 4, 8, 5],      # on to the gap by the East door (floor row 9)
	[46, 2, 4, 9],      # the gap by the East door, open down into the hall
	[50, 2, 8, 5],      # the landing at the East door (floor row 7)
	[3, 11, 51, 15],    # the hall (its floor row 26)
	[0, 21, 3, 5],      # the lower West door
	[54, 22, 4, 4],     # the lower East door, under the shelf
	[15, 26, 10, 1],    # the dip in the lower floor (row 27)
	[29, 26, 4, 5],     # the pit
	[0, 13, 3, 3],      # a secret room behind the hall's west wall, off the west wall's ledge
	[29, 31, 4, 3],     # under the pit's cracked plate (Ironbark Ward, W1b): the shaft down to the Undercroft
]
## Islands, plates and ledges: one tile of collision under each painting's
## walking line. Each ledge stands beside what it leads to, never over it.
const MASSES := [
	[13, 17, 15, 1, 1],   # the shrine island: the hooded statue
	[7, 20, 2, 1, 1],     # the small island west of the shrine
	[10, 22, 2, 1, 1],    # the pedestal on its column
	[3, 16, 3, 1, 1],     # the ledge on the west wall (CH2's corbel)
	[22, 22, 2, 1, 1],    # the nook under the shrine
	[29, 22, 2, 1, 1],    # the ledge over the pit
	[31, 18, 2, 1, 1],    # three small stone plates, rising east
	[34, 17, 2, 1, 1],
	[37, 16, 2, 1, 1],
	[41, 18, 6, 1, 1],    # the arch island
	[47, 13, 2, 1, 1],    # the ledge under the east gap (the way back up)
	[51, 21, 3, 1, 1],    # the shelf on the east wall, over the lower East door (CH2's corbel)
]
const SKIP := [[13, 17, 15, 1], [7, 20, 2, 1], [10, 22, 2, 1], [3, 16, 3, 1], [22, 22, 2, 1], [29, 22, 2, 1],
	[31, 18, 2, 1], [34, 17, 2, 1], [37, 16, 2, 1], [41, 18, 6, 1], [47, 13, 2, 1], [51, 21, 3, 1]]
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
	skip = SKIP + (CH9_SKIP if USE_CH9 else [])
	detail_skip = SKIP
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
	_use_crypt_y_stone()
	_begin("IronbarkShrineHall")
	_build_far()
	var t := _terrain(tileset)
	var behind: Node = t["behind"]
	var placed: Node = t["placed"]
	_build_islands(placed)
	_galleries(placed)
	_grade_stone()
	_hide_island_tiles()
	_dress(behind)
	_build_air(t["front"])
	_build_pit_plate(behind)
	_build_secrets()
	_edge_shades()
	_door("East", Rect2i(50, 2, 8, 5), 1, IB01, "WestLower")
	_door("West", Rect2i(0, 3, 8, 5), -1, IB02, "East")
	_door("WestLower", Rect2i(0, 21, 8, 5), -1, IB02, "EastLower")
	# The lower East door leads on under the clearing, into the Undercroft (IB-06).
	_door("EastLower", Rect2i(50, 22, 8, 4), 1, IB06, "West")
	_finish()
	quit()


func _build_far() -> void:
	_shrine_far()


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
	_piece_on(placed, PLAT, PEDESTAL, MASSES[2]).name = "Pedestal"
	_piece_on(placed, PLAT, ARCH_ISLAND, MASSES[9]).name = "ArchIsland"
	# The small plates and ledges are CH1's slab (the creative lead found the SH
	# plates "just look weird"); the wall ledges are CH2's corbel.
	var slabs := [[1, "WestIsland"], [4, "Nook"], [5, "PitLedge"], [6, "Plate"], [7, "Plate"], [8, "Plate"], [10, "GapLedge"]]
	for i in slabs.size():
		var m: Array = MASSES[slabs[i][0]]
		var sp := _sprite(placed, CH1_SHEET, CH1_SLAB, Vector2(m[0] * TILE + (m[2] * TILE - CH1_SLAB.size.x) * 0.5, m[1] * TILE - CH1_SLAB_LINE))
		sp.flip_h = i % 2 == 1
		sp.name = slabs[i][1]
	# West wall: the corbel's pier in the hall's west wall (x 48), its ledge east.
	var west: Array = MASSES[3]
	_sprite(placed, CH2_SHEET, CH2_CORBEL, Vector2(west[0] * TILE - CH2_PIER, west[1] * TILE - CH2_CORBEL_LINE)).name = "WestWallLedge"
	# East wall: mirrored, its pier in the east wall (x 864), its ledge west.
	var east: Array = MASSES[11]
	var shelf := _sprite(placed, CH2_SHEET, CH2_CORBEL, Vector2((east[0] + east[2]) * TILE + CH2_PIER - CH2_CORBEL.size.x, east[1] * TILE - CH2_CORBEL_LINE))
	shelf.flip_h = true
	shelf.name = "EastShelf"


## CH1 (ch_platforms.png): the small slab, its walking line on row 8, 38 px wide.
const CH1_SHEET := ENV + "ch_platforms.png"
const CH1_SLAB := Rect2(228, 21, 38, 30)
const CH1_SLAB_LINE := 8
## CH2 (ch_supports.png): the large corbel, a pier 8 px wide going into the
## wall, then a ledge 47 px long, its walking line on row 10.
const CH2_SHEET := ENV + "ch_supports.png"
const CH2_CORBEL := Rect2(104, 54, 55, 44)
const CH2_CORBEL_LINE := 10
const CH2_PIER := 8


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
	# The shrine island's braziers and the statue's orb, lit as in the mockup
	# (the creative lead: "add lights to the shrine on the island"). The flames
	# are painted on SH3; these are their light.
	_light(behind, Vector2(297, 255), FLAME, 0.55, 0.42, "ShrineBrazierLight")
	_light(behind, Vector2(387, 255), FLAME, 0.55, 0.42, "ShrineBrazierLight2")
	_light(behind, Vector2(328, 234), Color(1.0, 0.78, 0.45), 0.4, 0.28, "ShrineOrbLight")
	# The four doorways.
	_doorway(behind, -18, WEST, false)
	_doorway(behind, 58 * 16 - 62, LANDING, true)
	_doorway(behind, -18, FLOOR, false, true)
	_doorway(behind, 58 * 16 - 62, FLOOR, true)
	# The west gallery: a single arch, pots, crystals and flowers.
	_sh(behind, ARC, Rect2(144, 32, 64, 80), 120, WEST, "Arch")
	_sh(behind, ARC, Rect2(304, 88, 40, 24), 200, WEST, "Pots")
	_sh(behind, FLORA2, Rect2(8, 72, 32, 20), 250, WEST - TILE, "Flowers")
	# The east gallery: the arcade, pillars, the chest, pots, crystals.
	_sh(behind, ARC, Rect2(4, 32, 128, 80), 474, EAST, "Arcade")
	_sh(behind, ARC, Rect2(272, 32, 20, 80), 380, EAST - TILE, "Pillar")
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
	mod.color = Color(0.9, 0.9, 0.96)
	_mood = true
	_ch_detail = true
	_fog(_root, Rect2(48, 350, 800, 70), Color("#66647e"), 0.16, Vector2(0.005, 0.0))
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
	_crypt_foreground()


## W1b: the pit's floor is a cracked bark plate (Ironbark Ward lock), the
## horizontal plate from the plate sheet; under it the shaft drops on into the
## Undercroft, where wall ledges taking turns on each wall step down (the
## creative lead's reference: docs/mockups/undercroft/shaft_reference.webp).
## Its tells: motes rising through the cracks, a faint cool light from below.
func _build_pit_plate(behind: Node) -> void:
	var plate := _node(StaticBody2D.new(), "BarkPlateW1b", _root) as StaticBody2D
	plate.position = Vector2(29 * TILE, 31 * TILE)
	plate.z_index = 8
	var pc := CollisionShape2D.new()
	var pr := RectangleShape2D.new()
	pr.size = Vector2(4 * TILE, TILE)
	pc.shape = pr
	pc.position = Vector2(2 * TILE, 0.5 * TILE)
	_node(pc, "Shape", plate)
	_sprite(plate, ENV + "gate_bark_plate.png", Rect2(65, 97, 63, 29), Vector2(0, -4)).name = "Art"
	_light(behind, Vector2(31 * TILE, 33 * TILE), Color(0.55, 0.75, 1.0), 0.5, 0.7, "ShaftGlow")
	var draught := _particles("ShaftDraught", load("res://assets/fx/mote.png"), 6, 3.0, Rect2(29.6 * TILE, 30.4 * TILE, 2.8 * TILE, 0.4 * TILE))
	draught.direction = Vector2(0, -1)
	draught.spread = 14.0
	draught.gravity = Vector2.ZERO
	draught.initial_velocity_min = 5.0
	draught.initial_velocity_max = 10.0
	draught.color = Color(0.8, 0.92, 1.0, 0.75)
	draught.scale_amount_min = 0.5
	draught.scale_amount_max = 0.5
	draught.material = _add_mat
	draught.z_index = 21


## A secret room behind the hall's west wall, off the west wall's ledge: the
## wall over it is a false wall. Tell: motes drifting into the wall.
func _build_secrets() -> void:
	_false_wall("WestWallSecret", Rect2i(0, 13, 3, 3), 3, Vector2i(13, 3), 1, "ib05_west_secret")
	_draught("WestWallDraught", Rect2(3.2 * TILE, 13.3 * TILE, 2.0 * TILE, 2.4 * TILE), Vector2(-1, 0))
	_resin_cache(_root, 0.6 * TILE, 2.4 * TILE, 16.0 * TILE, 3, "ib05_west_resin")


# --- The galleries after the moody mockup ------------------------------------------------
## The creative lead's moody mockup of this room (docs/mockups/mood/
## shrine_hall_moody.webp): the galleries' walking lines and ceilings run
## straight and only step ("the top hallways in the mockup are straight"), a
## brick wall stands behind them, and only the slabs' undersides are ragged,
## hanging into the hall. The skin draws the straight edges; CH7's cave strips
## (ch_cave.png), cut below their cap, hang under each slab.
const CAVE := ENV + "ch_cave.png"
## CH7's long strips, the stretches clear of their roots: [x, y, w, h, cap row].
const STRIPS := [[71, 105, 370, 66, 10], [66, 9, 375, 82, 12], [241, 191, 200, 71, 13], [11, 191, 150, 71, 13], [11, 275, 130, 77, 15]]
## Floor runs [x0, x1, row] and ceiling runs [x0, x1, row of the underside].
const GALLERY_FLOORS := [[0, 14, 8], [14, 19, 7], [22, 29, 8], [29, 46, 9], [50, 54, 7]]
const GALLERY_CEILINGS := [[0, 8, 3], [8, 13, 2], [13, 19, 3], [22, 26, 3], [26, 29, 4], [29, 38, 3], [38, 46, 4], [46, 50, 2], [50, 58, 2]]
## The skin's straight band keeps the line; the strip starts this far from it.
const BAND := 8
## CH9 (the creative lead's gallery bands, the generator's own export, brought
## in by tools/make_crypt_ch9.py): straight floor and ceiling bands in cobble and
## an underside strip, each repeating. With them on, they paint the galleries'
## lines in place of the skin and CH7's strips.
const USE_CH9 := true
const CH9_FLOOR := ENV + "ch9_floor.png"       # walking line on its first row
const CH9_CEILING := ENV + "ch9_ceiling.png"   # underside on its last row
const CH9_UNDER := ENV + "ch9_under.png"       # straight top on its first row
const CH9_LIFT := Color(1.7, 1.65, 1.6)
## CH9's floor step (ch9_steps.png): from its face (column 93) to its end, the
## upper floor's cap on row 1. Painted 18 px tall where a step is 16, so only
## the face and the upper floor are used, lined up on the upper walking line;
## the lower floor's own band runs in under it. Flipped upside down it is a
## ceiling step (its lit cap then on the underside, as the ceiling band's).
## The sheet's second piece joins a ceiling to a floor and is not used.
const CH9_STEPS := ENV + "ch9_steps.png"
const CH9_STEP := Rect2(93, 1, 82, 43)
const CH9_CEILING_STEP_TINT := Color(0.62, 0.66, 0.8)
## Floor steps [face x, upper row, upper side +1 east / -1 west] and ceiling
## steps [face x, lower row (the lower underside), lower side +1 east / -1 west].
## A fourth number, where given, is how many tiles of the upper floor (lower
## ceiling) the piece may cover: where two steps face each other across a short
## run (the bulkhead, x 26 to 29, 3 tiles), each takes its half, so neither
## paints over the other's face.
const CH9_FLOOR_STEPS := [[14, 7, 1], [29, 8, -1]]
const CH9_CEILING_STEPS := [[8, 3, -1], [13, 3, 1], [26, 4, 1, 1.5], [29, 4, -1, 1.5], [38, 4, 1]]
## The skin leaves the galleries' slabs and ceilings to CH9.
const CH9_SKIP := [[0, 0, 19, 3], [8, 2, 5, 1], [0, 8, 19, 3], [14, 7, 5, 1], [22, 0, 24, 3], [26, 3, 3, 1], [38, 3, 8, 1],
	[22, 8, 24, 3], [46, 0, 4, 2], [50, 0, 8, 2], [50, 7, 4, 4]]
const GALLERY_BACK := [[0, 3, 14, 5], [8, 2, 5, 1], [14, 3, 5, 4], [22, 3, 4, 5], [26, 4, 3, 4], [29, 3, 9, 6], [38, 4, 8, 5], [50, 2, 8, 5]]


func _galleries(placed: Node) -> void:
	var wall := _node(Node2D.new(), "GalleryBackWall", _root) as Node2D
	wall.set_script(load("res://scripts/world/back_wall.gd"))
	wall.z_index = -2
	wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall.set("fill", load(TERRAIN + "sh_fill.png"))
	wall.set("brightness", 0.62)
	var regions: Array[Rect2i] = []
	for r in GALLERY_BACK:
		regions.append(Rect2i(r[0], r[1], r[2], r[3]))
	wall.set("regions", regions)
	if USE_CH9:
		_ch9_galleries(placed)
		return
	var strips := _node(Node2D.new(), "GalleryStrips", placed) as Node2D
	var i := 0
	for f in GALLERY_FLOORS:
		_strip(strips, f[0], f[1], f[2] * TILE, false, i)
		i += 1
	for c in GALLERY_CEILINGS:
		_strip(strips, c[0], c[1], c[2] * TILE, true, i)
		i += 1


## The masonry of a CH7 strip, below its cap, from tile x0 to x1. Under a
## floor's walking line (y) it fills the slab and its ragged underside hangs
## into the hall; over a ceiling's underside (y), upside down, it rises into the
## dark. Either way the skin's straight band keeps the line itself.
func _strip(parent: Node, x0: int, x1: int, y: float, ceiling: bool, n: int) -> void:
	var w := (x1 - x0) * TILE
	var st: Array = STRIPS[0]
	for k in STRIPS.size():
		var cand: Array = STRIPS[(n + k) % STRIPS.size()]
		if int(cand[2]) >= w:
			st = cand
			break
	var off := (n * 97) % maxi(1, int(st[2]) - w)
	var top := int(st[4]) + 3
	var region := Rect2(st[0] + off, st[1] + top, w, int(st[3]) - top)
	var sp := _sprite(parent, CAVE, region, Vector2(x0 * TILE, y + BAND))
	if ceiling:
		sp.name = "CeilingStrip"
		sp.flip_v = true
		sp.position.y = y - BAND - region.size.y
	else:
		sp.name = "FloorStrip"


## CH9's bands along the galleries: a floor band on every floor run, a ceiling
## band on every ceiling run, the underside strip under each slab.
func _ch9_galleries(placed: Node) -> void:
	# On the root, not under PlacedArt, so _grade_stone() leaves them as painted.
	var node := _node(Node2D.new(), "GalleryBands", _root) as Node2D
	node.z_index = 5
	# CH9 is painted about half as bright as the CY bands beside it, and the
	# room's murk multiplies both: lifted here (the art is unchanged) so the
	# galleries read as the mockup's do.
	node.modulate = CH9_LIFT
	for f in GALLERY_FLOORS:
		_band(node, CH9_FLOOR, f[0], f[1], f[2] * TILE, false, "FloorBand")
	for c in GALLERY_CEILINGS:
		_band(node, CH9_CEILING, c[0], c[1], c[2] * TILE, true, "CeilingBand")
	# Under the slabs: the strip hangs from the hall's ceiling line (row 11),
	# overlapping the floor band's dark by a few pixels.
	for u in [[0, 19], [22, 46], [50, 54]]:
		_band(node, CH9_UNDER, u[0], u[1], 11 * TILE - 6, false, "Underside")
	for st in CH9_FLOOR_STEPS:
		_ch9_step(node, st[0], st[1] * TILE, st[2], false, float(st[3]) if st.size() > 3 else 0.0)
	for st in CH9_CEILING_STEPS:
		_ch9_step(node, st[0], st[1] * TILE, st[2], true, float(st[3]) if st.size() > 3 else 0.0)


## A step's face on the tile line x, its higher floor (or lower ceiling) on the
## line y, on the side `side` of the face.
func _ch9_step(parent: Node, x: int, y: float, side: int, ceiling: bool, run := 0.0) -> void:
	var region := CH9_STEP
	if run > 0.0:
		region.size.x = minf(region.size.x, roundf(run * TILE) + 1)
	var w := region.size.x
	var h := region.size.y
	var px: float = x * TILE - 1 if side > 0 else x * TILE - w + 1
	var py: float = y - h if ceiling else y
	var sp := _sprite(parent, CH9_STEPS, region, Vector2(px, py))
	sp.flip_h = side < 0
	sp.flip_v = ceiling
	if ceiling:
		# The piece is the floor's step: its cap is painted warm and about twice
		# as bright as the ceiling band's lit edge, so it is cooled and dimmed
		# toward the ceiling band (the creative lead: "the ceiling is a different
		# color for the step").
		sp.modulate = CH9_CEILING_STEP_TINT
	sp.name = "CeilingStep" if ceiling else "FloorStep"


## A band repeated from tile x0 to x1: its first row on the line y, or (ceiling)
## its last row just above it.
func _band(parent: Node, tex_path: String, x0: int, x1: int, y: float, ceiling: bool, band_name: String) -> void:
	var tex: Texture2D = load(tex_path)
	var h := tex.get_height()
	var sp := _sprite(parent, tex_path, Rect2(x0 * TILE, 0, (x1 - x0) * TILE, h), Vector2(x0 * TILE, y - h if ceiling else y))
	sp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sp.name = band_name
