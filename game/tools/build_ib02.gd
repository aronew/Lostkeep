extends "res://tools/room_builder.gd"
## Builds room IB-02, the Old Crypt, from the plan below, with the shared tools
## in room_builder.gd, and saves it as an ordinary scene. Re-running this script
## overwrites scenes/rooms/ironbark_02_old_crypt.tscn.
##
##   godot --headless --path game --script res://tools/build_ib02.gd
##
## Spec and validation: design/rooms/ironbark_02_old_crypt.md.
## In the world grid this room lies west of IB-01 and 27 tiles lower: its East
## door (rows 5 to 9) is IB-01's hall door (rows 32 to 36).

const ROOM_PATH := "res://scenes/rooms/ironbark_02_old_crypt.tscn"
const IB05 := "res://scenes/rooms/ironbark_05_shrine_hall.tscn"

# --- The room plan (tiles) ---------------------------------------------------------
## "The guard's burial galleries, stacked beside a root-choked well that has
##  broken through them; the way on is down, and the hoist brings you back."
const ROOM := Rect2i(0, 0, 112, 40)
## Rock: the whole room starts solid.
const ROCK := [[0, 0, 112, 40, 0]]
## Spaces carved out of the rock.
const SPACES := [
	[47, 0, 8, 4],     # the well's mouth, up to the Guard Post (a lip far above a jump)
	[41, 4, 21, 33],   # the Root Well: the cavern the galleries open onto
	[62, 5, 50, 5],    # E1, the vestibule: the East door, the hoist's head, the balcony
	[62, 14, 27, 5],   # E2, the niche walk
	[85, 19, 4, 4],    # the collapse at E2's east end, down into E3
	[62, 23, 50, 5],   # E3, the long gallery: the winch, the hoist's foot, the lower East door
	[96, 10, 4, 13],   # the bier hoist's shaft, E1 down to E3
	[62, 32, 28, 5],   # the flooded gallery under E3 (Deep-Glow Breath)
	[8, 11, 33, 5],    # W1, the west gallery
	[0, 11, 8, 5],     # the West door, behind the plated door (Ironbark Ward, W2)
	[24, 16, 4, 5],    # the collapse in W1's floor, down into the cave
	[14, 21, 27, 7],   # the root cave: a hideout
	[3, 19, 11, 5],    # the walled-off vault behind the cave's west wall (a secret)
]
## Masses put back: [x, y, w, h, material]
const MASSES := [
	[45, 17, 15, 2, 1],   # the grave island: E1 down to E2 and across to W1 (a slab of masonry)
	[45, 28, 6, 2, 1],    # the lower well's two islands: E3 across to the cave
	[54, 28, 5, 2, 1],
	[23, 26, 6, 2, 0],    # the fallen rock under W1's collapse
]
## Masonry: the east galleries, the west gallery, the vault's walls, and the
## Root Well (the creative lead: "make the well stone too"). The cave is earth.
const STONE := [[62, 0, 50, 40], [0, 7, 41, 12], [0, 19, 14, 10], [41, 0, 21, 40], [0, 0, 41, 7], [39, 28, 2, 12]]
## Cells painted by placed art instead of the skin: the west low island is SH4's
## arch island. The grave island and the east low island are masonry slabs the
## skin paints.
const SKIP := [[45, 28, 6, 2]]
## Back walls: masonry behind the galleries, raw earth behind the well and cave.
const BACK := [[62, 5, 50, 5], [62, 14, 27, 5], [85, 19, 4, 4], [62, 23, 50, 5], [96, 10, 4, 13],
	[62, 32, 28, 5], [0, 11, 41, 5], [3, 19, 11, 5]]
const BACK_EARTH := [[24, 16, 4, 5], [14, 21, 27, 7]]

## Where Kleo stands if the room is run on its own: just inside the East door.
const SPAWN := Vector2(112 * 16 - 40, 10 * 16)

const LAN := ENV + "props_lanterns.png"
const GRAVE := ENV + "props_graveyard.png"
const FLORA := ENV + "props_flora.png"
const STUFF := ENV + "props_guard_belongings.png"
const ISLANDS := ENV + "ironbark_islands.png"
const SILK := ENV + "gate_silk_and_cocoon.png"
const LAMP := Color(1.0, 0.72, 0.4)


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
	# The same stone as the Shrine Hall next door (the creative lead's SH kit).
	_use_crypt_y_stone()
	_begin("IronbarkOldCrypt")
	_shrine_far()
	_back_walls()
	# The galleries open onto the misty hall behind, as in the Shrine Hall: no
	# plum masonry back wall. The well and the cave keep their raw earth.
	_root.get_node("BackWalls").set("regions", Array([], TYPE_RECT2I, &"", null))
	_root.get_node("EarthBackWalls").set("brightness", 0.85)
	var t := _terrain(tileset)
	_build_well(t["behind"], t["placed"])
	_grade_stone()
	_build_galleries(t["behind"])
	_build_west(t["behind"])
	_build_machines()
	_build_atmosphere()
	_crypt_foreground()
	_edge_shades()
	# The East door: back up to the Lantern Clearing's hall (IB-01).
	_door("East", Rect2i(104, 5, 8, 5), 1, IB05, "West")
	# The lower East door leads on under the clearing (the Undercroft, not built
	# yet), so it has a marker to arrive at but no way through.
	_door("EastLower", Rect2i(104, 23, 8, 5), 1, IB05, "WestLower")
	_finish()
	quit()


# --- The Root Well ------------------------------------------------------------------------

func _build_well(behind: Node, placed: Node) -> void:
	# The grave island (IB4's middle island), its flat top on the collision.
	# The grave on the masonry slab in the moonlight, crystals and flowers.
	_ground(behind, GRAVE, Rect2(165, 2, 35, 45), 51.4 * TILE, 17 * TILE, 0.95, "IslandGrave")
	_ground(behind, ENV + "sh_flora.png", Rect2(64, 8, 48, 32), 46.0 * TILE, 17 * TILE, 1.0, "IslandCrystals")
	_ground(behind, ENV + "sh_flora.png", Rect2(64, 64, 48, 28), 55.5 * TILE, 17 * TILE, 1.0, "IslandFlowers")
	_ground(behind, ENV + "sh_flora.png", Rect2(8, 72, 32, 20), 55.2 * TILE, 28 * TILE, 1.0, "LowFlowers")
	# The west low island: SH4's arch island, its walking line (row 50) on the collision.
	_sprite(placed, ENV + "sh_platforms.png", Rect2(8, 8, 96, 88), Vector2(45 * TILE, 28 * TILE - 50)).name = "LowIslandWest"

	# The hanging cocoon (Emberwick lock E2): someone wrapped in silk, hung over
	# the gap by W1's mouth on a strand no blade reaches.
	var strand := _node(Line2D.new(), "CocoonStrand", behind) as Line2D
	strand.points = PackedVector2Array([Vector2(43.5 * TILE, 4 * TILE), Vector2(43.5 * TILE, 9 * TILE + 4)])
	strand.width = 1.0
	strand.default_color = Color(0.74, 0.72, 0.8)
	_sprite(behind, SILK, Rect2(167, 26, 35, 82), Vector2(43.5 * TILE - 17, 9 * TILE)).name = "HangingCocoon"

	# Vines from the cavern's shoulders; lily pads on the dark water.
	for v in [[Rect2(198, 126, 16, 71), 42.0], [Rect2(171, 126, 15, 51), 45.2], [Rect2(227, 126, 14, 88), 56.4],
			[Rect2(171, 126, 15, 51), 59.6]]:
		_sprite(behind, FLORA, v[0], Vector2(v[1] * TILE, 4 * TILE - 2)).name = "WellVine"
	for pad in [[Rect2(15, 227, 48, 17), 42.6], [Rect2(77, 231, 35, 13), 51.4], [Rect2(15, 227, 48, 17), 57.2]]:
		var lily := _sprite(behind, FLORA, pad[0], Vector2(pad[1] * TILE, 33 * TILE - 8))
		lily.name = "LilyPads"
		lily.z_index = 11  # on the water


# --- The east galleries ---------------------------------------------------------------------

func _wall_lantern(parent: Node, tile_x: float, ceiling_row: int) -> void:
	var y := (ceiling_row + 0.6) * TILE
	_sprite(parent, LAN, Rect2(110, 4, 42, 56), Vector2(tile_x * TILE, y)).name = "WallLantern"
	_light(parent, Vector2(tile_x * TILE, y) + Vector2(31, 42), LAMP, 0.95, 0.9, "WallLanternLight")


func _build_galleries(behind: Node) -> void:
	var e1 := 10 * TILE
	var e2 := 19 * TILE
	var e3 := 28 * TILE
	# E1, the vestibule: the guard's banner by the door, stores, lanterns.
	_ground(behind, STUFF, Rect2(208, 49, 45, 69), 104.6 * TILE, e1, 1.0, "Banner")
	_ground(behind, GRAVE, Rect2(202, 94, 51, 29), 88.0 * TILE, e1 - 24, 0.8, "Plaque")
	_breakable(STUFF, CRATE_A, 91.0 * TILE, e1, WOOD)
	_breakable(STUFF, BARREL, 93.0 * TILE, e1, WOOD)
	_breakable(STUFF, POT, 72.0 * TILE, e1, CLAY)
	for x in [68.0, 82.0, 107.0]:
		_wall_lantern(behind, x, 5)
	# E2, the niche walk: memorial stones and offerings left for the dead.
	_ground(behind, GRAVE, Rect2(17, 2, 50, 45), 69.0 * TILE, e2, 0.95, "Memorial")
	_ground(behind, GRAVE, Rect2(116, 11, 43, 36), 73.2 * TILE, e2, 0.95, "MemorialCrest")
	_ground(behind, GRAVE, Rect2(73, 14, 37, 33), 78.4 * TILE, e2, 0.95, "MemorialBroken")
	_breakable(STUFF, POT_SMALL, 72.3 * TILE, e2, CLAY)
	_breakable(STUFF, POT, 76.6 * TILE, e2, CLAY)
	_breakable(STUFF, POT_SMALL, 81.4 * TILE, e2, CLAY)
	for x in [65.0, 79.0]:
		_wall_lantern(behind, x, 14)
	# Roots hanging into the collapse at E2's east end.
	for v in [[Rect2(171, 126, 15, 51), 85.4], [Rect2(198, 126, 16, 71), 87.6]]:
		var root := _sprite(behind, FLORA, v[0], Vector2(v[1] * TILE, 19 * TILE + 4))
		root.name = "CollapseRoots"
		root.modulate = Color(0.8, 0.8, 0.85)
	# E3, the long gallery: the gravediggers' stores by the hoist, a rack by the door.
	_ground(behind, STUFF, Rect2(3, 52, 58, 65), 100.6 * TILE, e3, 1.0, "WeaponRack")
	_breakable(STUFF, CRATE_B, 72.0 * TILE, e3, WOOD)
	_breakable(STUFF, KEG, 74.0 * TILE, e3, WOOD)
	_breakable(STUFF, BARREL_BIG, 90.8 * TILE, e3, WOOD)
	_breakable(STUFF, CRATE_C, 92.6 * TILE, e3, WOOD)
	for x in [66.0, 80.0, 101.0]:
		_wall_lantern(behind, x, 23)


# --- The west gallery, the cave and the vault ------------------------------------------------

func _build_west(behind: Node) -> void:
	var w1 := 16 * TILE
	var cave := 28 * TILE
	# W1: the plated door (Ironbark Ward lock W2) across the gallery; the West
	# door lies beyond it.
	var plate := _node(StaticBody2D.new(), "BarkPlateW2", _root) as StaticBody2D
	plate.position = Vector2(16 * TILE, 11 * TILE)
	plate.z_index = 8
	var pc := CollisionShape2D.new()
	var pr := RectangleShape2D.new()
	pr.size = Vector2(2 * TILE, 5 * TILE)
	pc.shape = pr
	pc.position = Vector2(TILE, 2.5 * TILE)
	_node(pc, "Shape", plate)
	_sprite(plate, ENV + "gate_bark_plate.png", Rect2(13, 2, 41, 82), Vector2(-4, -1)).name = "Art"
	_breakable(STUFF, POT, 30.0 * TILE, w1, CLAY)
	_breakable(STUFF, POT_SMALL, 31.2 * TILE, w1, CLAY)
	_breakable(STUFF, BARREL_BIG, 36.0 * TILE, w1, WOOD)
	_ground(behind, GRAVE, Rect2(202, 94, 51, 29), 20.0 * TILE, w1 - 24, 0.8, "Plaque")
	for x in [11.0, 20.0, 33.0]:
		_wall_lantern(behind, x, 11)

	# The cave: someone hid here. A cold fire, a meal, boots left behind.
	_ground(behind, STUFF, Rect2(152, 61, 56, 57), 31.0 * TILE, cave, 0.95, "ColdCampfire")
	_ground(behind, STUFF, Rect2(120, 100, 28, 17), 35.2 * TILE, cave, 1.0, "Boots")
	_ground(behind, STUFF, Rect2(65, 69, 60, 36), 16.2 * TILE, cave, 0.95, "UnfinishedMeal")
	_ground(behind, LAN, Rect2(26, 1, 45, 61), 37.0 * TILE, cave, 1.0, "CampLantern")
	_light(behind, Vector2(37.0 * TILE, cave - 61) + Vector2(33, 45), Color(1.0, 0.75, 0.42), 1.0, 1.0, "CampLanternLight")
	_breakable(STUFF, KEG, 20.6 * TILE, cave, WOOD)
	_breakable(STUFF, CRATE_B, 30.0 * TILE, cave, WOOD)
	for tuft in [[Rect2(91, 24, 49, 24), 26.0, 26], [Rect2(22, 101, 32, 17), 33.6, 28], [Rect2(215, 22, 32, 26), 38.6, 28]]:
		_ground(behind, FLORA, tuft[0], tuft[1] * TILE, tuft[2] * TILE, 1.0, "Plants")
	for v in [[Rect2(171, 126, 15, 51), 24.4], [Rect2(171, 126, 15, 51), 27.0]]:
		var root := _sprite(behind, FLORA, v[0], Vector2(v[1] * TILE, 16 * TILE + 4))
		root.name = "CollapseRoots"
		root.modulate = Color(0.8, 0.8, 0.85)

	# The vault: offerings, a guard's helmet, and an empty Prism socket (Anima
	# Siphon lock) in the back wall.
	var vault := 24 * TILE
	_sprite(behind, ENV + "gate_prism_socket.png", Rect2(9, 7, 51, 50), Vector2(6.5 * TILE - 25, vault - 62)).name = "PrismSocket"
	_sprite(behind, STUFF, Rect2(126, 60, 29, 26), Vector2(10.4 * TILE, vault - 60)).name = "Helmet"
	_breakable(STUFF, POT_BIG, 4.6 * TILE, vault, CLAY)
	_breakable(STUFF, POT_SMALL, 9.0 * TILE, vault, CLAY)

	# The false wall. From the cave it is unbroken masonry: black over the vault,
	# and the wall's own face running on across the opening (rows 21 to 23), read
	# from the same band at the same height as the skin reads it, so nothing
	# shows. Tell: masonry in a raw cave, moss where the air moves.
	_false_wall("VaultCover", Rect2i(3, 19, 11, 5), 14, Vector2i(21, 5), 1, "ib02_vault")
	_resin_cache(_root, 5.0 * TILE, 12.5 * TILE, vault, 6, "ib02_vault_resin")
	# Moss on the wall over the hidden opening, in front of the cover.
	var moss := _sprite(_root, FLORA, Rect2(89, 162, 70, 37), Vector2(14 * TILE - 30, 21 * TILE - 6))
	moss.name = "VaultMoss"
	moss.z_index = 23


# --- Machines and water ------------------------------------------------------------------------

func _build_machines() -> void:
	# The bier hoist: the gravediggers' rope lift, jammed at its head in E1. The
	# winch at its foot in E3 frees it: the way back up to the door.
	_lift("BierHoist", Vector2(98 * TILE, 10 * TILE), 18.0 * TILE, -3.5 * TILE, "ib02_hoist")
	# The cistern: the well's dark water, running on east into the flooded gallery
	# (Deep-Glow Breath). A glint lies deep inside it.
	_water("Cistern", Vector2(41 * TILE, 33 * TILE), Vector2(49 * TILE, 4 * TILE), Vector2(36 * TILE, 30))


# --- Atmosphere -----------------------------------------------------------------------------------

func _build_atmosphere() -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.9, 0.9, 0.96)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	# Moonlight down the well from the Guard Post's mouth, far above.
	# Three nested beams, each narrower and fainter at its edge, so the light has
	# a soft side without a smooth gradient.
	var c := Color(0.72, 0.86, 1.0)
	for i in 3:
		var shaft := _node(Polygon2D.new(), "MoonShaft", _root) as Polygon2D
		shaft.z_index = 3
		var inset := i * 14.0
		var xl := 47.0 * TILE + inset
		var xr := 55.0 * TILE - inset
		var spread := 56.0 - i * 16.0
		shaft.polygon = PackedVector2Array([Vector2(xl, 0), Vector2(xr, 0), Vector2(xr + spread, 33 * TILE), Vector2(xl - spread, 33 * TILE)])
		shaft.vertex_colors = PackedColorArray([Color(c, 0.08), Color(c, 0.08), Color(c, 0.0), Color(c, 0.0)])
		shaft.material = add
	_light(_root, Vector2(51 * TILE, 3 * TILE), Color(0.7, 0.85, 1.0), 0.7, 2.6, "MoonLight").set_script(null)
	# The mouth goes up into darkness.
	var top := _node(Polygon2D.new(), "MouthShade", _root) as Polygon2D
	top.z_index = 25
	var void_col := Color(0.043, 0.031, 0.071)
	top.polygon = PackedVector2Array([Vector2(46 * TILE, 0), Vector2(56 * TILE, 0), Vector2(56 * TILE, 56), Vector2(46 * TILE, 56)])
	top.vertex_colors = PackedColorArray([Color(void_col, 0.85), Color(void_col, 0.85), Color(void_col, 0.0), Color(void_col, 0.0)])
	# Mist lying on the cistern.
	_fog(_root, Rect2(41 * TILE, 27 * TILE, 21 * TILE, 6 * TILE), Color("#5f8a8c"), 0.3, Vector2(0.006, 0.0))
	# Dust in the moonlight, and a draught of motes at the cave's west wall.
	var dust := _particles("WellDust", load("res://assets/fx/mote.png"), 26, 9.0, Rect2(43 * TILE, 2 * TILE, 17 * TILE, 30 * TILE))
	dust.color = Color(0.8, 0.9, 1.0, 0.7)
	dust.gravity = Vector2(0, 3)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 6.0
	dust.spread = 180.0
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.0
	dust.material = add
	dust.z_index = 14
	var draught := _particles("VaultDraught", load("res://assets/fx/mote.png"), 7, 2.6, Rect2(14.2 * TILE, 21 * TILE, 3.5 * TILE, 3 * TILE))
	draught.preprocess = 2.6
	draught.direction = Vector2(-1, 0)
	draught.spread = 12.0
	draught.gravity = Vector2.ZERO
	draught.initial_velocity_min = 10.0
	draught.initial_velocity_max = 18.0
	draught.color = Color(0.85, 0.95, 0.8, 0.8)
	draught.scale_amount_min = 0.5
	draught.scale_amount_max = 0.5
	draught.material = add
	draught.z_index = 21
