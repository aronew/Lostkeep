extends "res://tools/room_builder.gd"
## Builds room IB-01, the Lantern Clearing (the Ironbark test room), from the
## plan below, with the shared tools in room_builder.gd, and saves it as an
## ordinary scene. After that, edit it in the editor as usual. Re-running this
## script overwrites scenes/rooms/ironbark_test_room.tscn.
##
##   godot --headless --path game --script res://tools/build_test_room.gd
##
## The plan follows the blockout method: rock first, spaces carved out of it,
## masses put back, placed pieces last. Every number is in tiles (16 px).

const ROOM_PATH := "res://scenes/rooms/ironbark_test_room.tscn"

# --- The room plan (tiles) ---------------------------------------------------------
## "Under the Great Ironbark, a mossy clearing runs east to the broken bridge,
##  with the guard's crypt beneath it."
const ROOM := Rect2i(0, 0, 138, 40)
## Rock: [x, y, w, h, material]  (0 earth, 1 stone)
const ROCK := [
	[0, 24, 30, 16, 0],   # the tree terrace (west)
	[30, 28, 65, 12, 0],  # the clearing and the ground beneath it, to the moat
	[95, 37, 25, 3, 0],   # the moat's bed
	[120, 28, 18, 12, 0], # the far bank, under the Lost Keep's gate (beyond the gap)
]
## Spaces carved out of the rock.
const SPACES := [
	[8, 32, 22, 5],   # the west hall, five tiles tall like the crypt it runs on into
	[0, 32, 8, 5],    # the west door (the main way on, to the Old Crypt)
	[30, 32, 56, 5],  # the crypt under the clearing
	[86, 32, 5, 5],   # the sealed pocket (silk: Emberwick lock E1): the arcade's last pier meets its wall
	[78, 28, 4, 4],   # the drop into the crypt
	[24, 24, 4, 8],   # the lift shaft, down to the hall
]
## Masses put back: [x, y, w, h, material]
const MASSES := [
	[33, 21, 15, 2, 0],   # the floating island (upper line)
	[52, 17, 22, 2, 0],   # the root shelf (upper line, its pocket): IB4's big island
	[95, 28, 7, 2, 0],    # the bridge's west span
	[113, 28, 7, 2, 0],   # the bridge's east span (the gap: Wing-Cloak lock G1)
]
## Solid cells inside these become stone (the crypts' masonry). They start at
## the crypts' ceilings, so a slab is earth from the grass down and only the
## arches under it are masonry: one material per face, never two stacked.
## The moat bank (x 91 to 94) is masonry from its walking line down: the bridge's
## quay, its approach paved where the clearing's grass ends.
const STONE := [[0, 28, 30, 12], [30, 31, 61, 9]]
## Cells painted by placed art instead of the skin.
## (x 94 under the walking line: the moat bank's face, painted by L6. West of it
## the bank goes into the room's own black.)
const SKIP := [[33, 21, 15, 2], [52, 17, 22, 2], [95, 28, 7, 2], [94, 28, 1, 9], [113, 28, 7, 2]]
## Back walls behind enclosed spaces.
const BACK := [[8, 32, 22, 5], [0, 32, 8, 5], [30, 32, 56, 5], [86, 32, 5, 5], [24, 24, 4, 8]]
## Back walls of raw earth: the collapse that drops into the crypt.
const BACK_EARTH := [[78, 28, 4, 4]]

const SPAWN := Vector2(232, 384)
## The colour under the mid forest layer, where its mist meets the floors
## (printed by tools/make_terrain.py as "mid base colour").
const MID_BASE := Color("#24535b")


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
	_begin("IronbarkTestRoom")
	_build_parallax()
	_back_walls()
	var t := _terrain(tileset)
	_build_landmarks(t["behind"], t["placed"])
	_build_props(t["behind"], t["placed"], t["front"])
	_build_machines()
	_build_atmosphere(t["front"])
	_build_foreground()
	_edge_shades()
	# The hall's west door: the main way on, down into the Old Crypt (IB-02).
	_door("WestLower", Rect2i(0, 32, 8, 5), -1, "res://scenes/rooms/ironbark_02_old_crypt.tscn", "East")
	# The terrace's west end: the Gate Road (IB-04), the way she came from the Ruin Gardens.
	_door("WestUpper", Rect2i(0, 19, 8, 5), -1, "res://scenes/rooms/ironbark_04_gate_road.tscn", "East")
	_finish()
	quit()


# --- Parallax ---------------------------------------------------------------------------


func _build_parallax() -> void:
	var sky := _parallax("Sky", Vector2(0.05, 0.0), PARALLAX + "sky.png", -96.0, Color("#3b6d70"))
	sky.get_node("Art").modulate = Color(0.78, 0.76, 0.86)
	_parallax("Far", Vector2(0.15, 0.08), PARALLAX + "far.png", 92.0, Color("#3d7070"))
	var fog_far := _node(Parallax2D.new(), "FogFar", _root) as Parallax2D
	fog_far.scroll_scale = Vector2(0.25, 0.12)
	fog_far.z_index = -10
	_fog(fog_far, Rect2(-200, 210, 2400, 150), Color("#6f9a9a"), 0.32, Vector2(0.004, 0.0))
	# P3 v2: whole crowns on a transparent sky. Placed so the crowns' tops sit about
	# 90 px down the screen at the shrine; the trunks run down behind the floors.
	_parallax("Mid", Vector2(0.35, 0.22), PARALLAX + "mid.png", 52.0, MID_BASE)
	var fog_mid := _node(Parallax2D.new(), "FogMid", _root) as Parallax2D
	fog_mid.scroll_scale = Vector2(0.5, 0.35)
	fog_mid.z_index = -10
	_fog(fog_mid, Rect2(-200, 260, 2600, 160), Color("#5f8a8c"), 0.26, Vector2(0.007, 0.0))
	var ruins := _parallax("Ruins", Vector2(0.72, 0.6), PARALLAX + "wall.png", 470.0 - 256.0)
	ruins.get_node("Art").modulate = Color(0.6, 0.64, 0.74)  # hazier than the playfield


# --- Landmarks ----------------------------------------------------------------------------

func _build_landmarks(behind: Node, placed: Node) -> void:
	# The Great Ironbark, rooted on the terrace. Its hanging lantern lights the shrine.
	var tree := _sprite(behind, ENV + "landmark_great_ironbark.png", Rect2(1, 1, 255, 252), Vector2(-56, 384 - 248))
	tree.name = "GreatIronbark"
	_light(behind, Vector2(-56, 136) + Vector2(193, 130), Color(1.0, 0.74, 0.42), 1.0, 1.1, "TreeLantern")

	# The Prism-shard shrine: the save point.
	var shrine := _node(Area2D.new(), "PrismShrine", _root) as Area2D
	shrine.set_script(load("res://scripts/world/prism_shrine.gd"))
	shrine.position = Vector2(232, 384)
	shrine.z_index = 3
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(72, 40)
	ss.shape = sr
	ss.position = Vector2(0, -20)
	_node(ss, "Shape", shrine)
	var sprite := _sprite(shrine, ENV + "landmark_prism_shrine.png", Rect2(4, 3, 184, 119), Vector2(-92, -117))
	sprite.name = "Art"
	var glow := _light(shrine, Vector2(0, -50), Color(0.62, 0.88, 1.0), 0.45, 1.3, "Glow")
	shrine.set("sprite", sprite)
	shrine.set("glow", glow)
	shrine.set("dormant_region", Rect2(4, 3, 184, 119))
	shrine.set("awake_region", Rect2(196, 3, 184, 119))
	shrine.set("prompt_offset", Vector2(0, -88))
	shrine.set("flag", "ib01_shrine")

	# The floating island (upper line), its flat top on the collision.
	_sprite(placed, ENV + "ironbark_islands.png", Rect2(130, 2, 246, 85), Vector2(33 * TILE - 3, 21 * TILE - 31)).name = "Island"
	# The root shelf: IB4's big island with its sapling. Its walking line is row 33
	# of the region (the sapling rises above it), and its flat top (x 10 to 374) is
	# centred on the 22-tile mass.
	_sprite(placed, ENV + "ironbark_islands.png", Rect2(9, 86, 366, 101), Vector2(52 * TILE + 176 - 183, 17 * TILE - 33)).name = "RootShelf"

	# The broken bridge: its west span with the torn banner, the east span beyond the gap.
	# The west end is L6: the moat bank and the span as one painting, its walking
	# line on row 28 and its first water arch opening where the moat begins (x 95).
	# The piece and its anchors are cut by tools/make_terrain.py.
	var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN + "kit_anchors.json"))
	var bank := Vector2(95 * TILE - int(kit["bridge_opening"]), 28 * TILE - int(kit["bridge_line"]))
	_sprite(placed, ENV + "landmark_bridge_bank_game.png", Rect2(0, 0, 172, 206), bank).name = "BridgeWest"
	_light(placed, bank + _vec(kit["bridge_lantern"]), Color(1.0, 0.78, 0.45), 0.8, 0.8, "BridgeLantern")
	_sprite(placed, ENV + "landmark_arch_bridge.png", Rect2(241, 52, 142, 76), Vector2(113 * TILE, 28 * TILE - 12)).name = "BridgeEast"

	# The Lost Keep's gate on the far bank: the goal, seen across the gap.
	var gate_pos := Vector2(129 * TILE - 127, 28 * TILE - 204)
	var gate := _sprite(behind, ENV + "landmark_keep_gate.png", Rect2(1, 18, 254, 206), gate_pos)
	gate.name = "KeepGate"
	gate.modulate = Color(0.86, 0.86, 0.92)
	_light(behind, gate_pos + Vector2(75, 122), Color(1.0, 0.74, 0.42), 0.8, 0.9, "GateLanternL")
	_light(behind, gate_pos + Vector2(177, 123), Color(1.0, 0.74, 0.42), 0.8, 0.9, "GateLanternR")


# --- Props --------------------------------------------------------------------------------

func _build_props(behind: Node, placed: Node, front: Node) -> void:
	var floor_y := 28 * TILE
	var lan := ENV + "props_lanterns.png"
	var grave := ENV + "props_graveyard.png"
	var flora := ENV + "props_flora.png"
	var stuff := ENV + "props_guard_belongings.png"
	var timber := ENV + "keep_timber_kit.png"

	# The graveyard by the terrace: the guard's dead, and one fresh, empty grave.
	_ground(behind, grave, Rect2(3, 89, 115, 34), 32.4 * TILE, floor_y, 0.9, "Fence")
	_ground(behind, grave, Rect2(124, 86, 21, 37), 39.6 * TILE, floor_y, 0.9, "FencePost")
	_ground(behind, grave, Rect2(151, 89, 43, 34), 41.0 * TILE, floor_y, 0.9, "FenceBroken")
	_ground(behind, grave, Rect2(17, 2, 50, 45), 33.0 * TILE, floor_y, 1.0, "Headstone")
	_ground(behind, grave, Rect2(116, 11, 43, 36), 36.6 * TILE, floor_y, 1.0, "HeadstoneCrest")
	_ground(behind, grave, Rect2(165, 2, 35, 45), 39.0 * TILE, floor_y, 1.0, "HeadstoneCross")
	_ground(behind, grave, Rect2(57, 50, 137, 33), 41.4 * TILE, floor_y + 2, 1.0, "FreshGrave")
	_ground(behind, lan, Rect2(26, 1, 45, 61), 30.4 * TILE, floor_y, 1.0, "GraveLantern")
	_light(behind, Vector2(30.4 * TILE, floor_y - 61) + Vector2(33, 45), Color(1.0, 0.75, 0.42), 1.0, 1.0, "GraveLanternLight")

	# Ironbark-plate floor over the crypt (Ironbark Ward lock W1).
	_sprite(placed, ENV + "gate_bark_plate.png", Rect2(1, 97, 64, 29), Vector2(50 * TILE, floor_y - 2)).name = "BarkPlateW1"

	# The training yard under the root shelf: lived in, then abandoned.
	_ground(behind, stuff, Rect2(208, 49, 45, 69), 55.0 * TILE, floor_y, 1.0, "Banner")
	_ground(behind, stuff, Rect2(3, 52, 58, 65), 69.0 * TILE, floor_y, 1.0, "WeaponRack")
	_ground(behind, stuff, Rect2(65, 69, 60, 36), 73.0 * TILE, floor_y, 1.0, "UnfinishedMeal")
	_ground(behind, stuff, Rect2(152, 61, 56, 57), 33.0 * TILE, 37 * TILE, 0.9, "ColdCampfire")
	for i in 2:
		var post := _node(Node2D.new(), "PracticePost%d" % (i + 1), _root)
		post.set_script(load("res://scripts/world/practice_post.gd"))
		post.position = Vector2([60.5, 65.5][i] * TILE, floor_y)
		post.z_index = 6
		var art := _node(Node2D.new(), "Art", post)
		var flash := ShaderMaterial.new()
		flash.shader = load("res://shaders/hit_flash.gdshader")
		art.material = flash
		_sprite(art, timber, Rect2(10, 6, 25, 30), Vector2(-12, -30 - 22)).use_parent_material = true
		_sprite(art, timber, Rect2(201, 57, 35, 31), Vector2(-17, -31)).use_parent_material = true
		if i == 1:
			_sprite(art, stuff, Rect2(126, 60, 29, 26), Vector2(-14, -70)).use_parent_material = true
		var hb := _node(Area2D.new(), "Hurtbox", post) as Area2D
		hb.collision_layer = 4
		hb.collision_mask = 0
		hb.monitoring = false
		var hs := CollisionShape2D.new()
		var hr := RectangleShape2D.new()
		hr.size = Vector2(18, 46)
		hs.shape = hr
		hs.position = Vector2(0, -24)
		_node(hs, "Shape", hb)

	# The root shelf's pocket: a lookout someone kept.
	_ground(behind, stuff, Rect2(120, 100, 28, 17), 64.2 * TILE, 17 * TILE, 1.0, "Boots")
	_breakable(stuff, POT_BIG, 54.8 * TILE, 17 * TILE, CLAY)
	_breakable(stuff, KEG, 57.0 * TILE, 17 * TILE, WOOD)
	_sprite(behind, lan, Rect2(201, 1, 21, 60), Vector2(61.5 * TILE, 19 * TILE - 6)).name = "ShelfLantern"
	_light(behind, Vector2(61.5 * TILE, 19 * TILE - 6) + Vector2(10, 46), Color(1.0, 0.76, 0.44), 0.9, 1.0, "ShelfLanternLight")

	# The west hall and the crypt: stores, wall lanterns.
	# The hall's stores: crates, barrels and pots, all breakable.
	_breakable(stuff, CRATE_A, 10.0 * TILE, 37 * TILE, WOOD)
	_breakable(stuff, CRATE_B, 12.1 * TILE, 37 * TILE, WOOD)
	_breakable(stuff, BARREL_BIG, 14.2 * TILE, 37 * TILE, WOOD)
	_breakable(stuff, POT, 16.0 * TILE, 37 * TILE, CLAY)
	_breakable(stuff, BARREL, 28.6 * TILE, 37 * TILE, WOOD)
	# The crypt: offerings left by the dead, and stores.
	_breakable(stuff, POT_SMALL, 46.0 * TILE, 37 * TILE, CLAY)
	_breakable(stuff, POT, 47.2 * TILE, 37 * TILE, CLAY)
	_breakable(stuff, CRATE_C, 66.0 * TILE, 37 * TILE, WOOD)
	_breakable(stuff, KEG, 68.0 * TILE, 37 * TILE, WOOD)
	# The clearing: a pot by the graveyard lantern, a barrel by the training yard.
	_breakable(stuff, POT_SMALL, 31.9 * TILE, floor_y, CLAY)
	_breakable(stuff, BARREL, 76.6 * TILE, floor_y, WOOD)
	for x in [13.0, 40.0, 57.0, 74.0]:
		var y := 32.6 * TILE
		_sprite(behind, lan, Rect2(110, 4, 42, 56), Vector2(x * TILE, y)).name = "WallLantern"
		_light(behind, Vector2(x * TILE, y) + Vector2(31, 42), Color(1.0, 0.72, 0.4), 0.95, 0.9, "WallLanternLight")

	# The sealed pocket: silk across its mouth, a shape in a cocoon behind it.
	# The cocoon hangs in the alcove past the silk, in front of the arcade's end pier.
	# The cocoon: someone wrapped in the web itself, so the lock reads at a glance.
	var silk := _node(StaticBody2D.new(), "SilkSealE1", _root) as StaticBody2D
	silk.position = Vector2(86 * TILE, 32 * TILE)
	silk.z_index = 8
	var sc := CollisionShape2D.new()
	var sb := RectangleShape2D.new()
	sb.size = Vector2(2 * TILE, 5 * TILE)
	sc.shape = sb
	sc.position = Vector2(TILE, 2.5 * TILE)
	_node(sc, "Shape", silk)
	_sprite(silk, ENV + "gate_silk_and_cocoon.png", Rect2(2, 26, 75, 82), Vector2(-4, -2)).name = "Silk"
	_sprite(silk, ENV + "gate_silk_and_cocoon.png", Rect2(167, 26, 35, 82), Vector2(22, -2)).name = "Cocoon"

	# Plants: tufts on the floors, vines under the island and the shelf.
	var tufts := [[Rect2(6, 6, 73, 42), 3.0, 24], [Rect2(153, 32, 49, 16), 19.0, 24], [Rect2(91, 24, 49, 24), 47.5, 28],
		[Rect2(215, 22, 32, 26), 71.5, 28], [Rect2(11, 55, 48, 30), 84.0, 28], [Rect2(126, 93, 42, 27), 88.5, 28],
		[Rect2(22, 101, 32, 17), 58.6, 17], [Rect2(77, 104, 27, 14), 30.6, 28], [Rect2(161, 67, 83, 20), 28.0, 37]]
	for t in tufts:
		_ground(behind, flora, t[0], t[1] * TILE, t[2] * TILE, 1.0, "Plants")
	# Hanging art stops at least 2.5 tiles above the floor below it.
	for v in [[Rect2(171, 126, 15, 51), 36.0, 352], [Rect2(171, 126, 15, 51), 44.5, 350]]:
		_sprite(behind, flora, v[0], Vector2(v[1] * TILE, v[2])).name = "Vine"

	# Roots hanging into the collapse over the crypt.
	for v in [[Rect2(171, 126, 15, 51), 77.7], [Rect2(198, 126, 16, 71), 80.9]]:
		var root := _sprite(behind, flora, v[0], Vector2(v[1] * TILE, 28 * TILE + 6))
		root.name = "CollapseRoots"
		root.modulate = Color(0.8, 0.8, 0.85)


func _build_machines() -> void:
	# The guard's rope lift (the shortcut), at the top of its shaft, jammed.
	_lift("GuardLift", Vector2(26 * TILE, 24 * TILE), 13.0 * TILE, -3.5 * TILE, "ib01_lift")
	# The moat: deep water under the bridge (Deep-Glow Breath lock D1).
	_water("Moat", Vector2(95 * TILE, 31 * TILE), Vector2(25 * TILE, 6 * TILE), Vector2(156, 34))


func _build_atmosphere(front: Node) -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.64, 0.63, 0.78)
	# Light falling through the canopy.
	for s in [[300.0, 0.0, 70.0], [880.0, 0.0, 90.0], [1290.0, 0.0, 60.0]]:
		var shaft := _node(Polygon2D.new(), "LightShaft", _root) as Polygon2D
		shaft.z_index = 3
		var x: float = s[0]
		var w: float = s[2]
		shaft.polygon = PackedVector2Array([Vector2(x, 40), Vector2(x + w, 40), Vector2(x + w + 150, 470), Vector2(x + 150, 470)])
		shaft.vertex_colors = PackedColorArray([Color(1, 0.93, 0.7, 0.13), Color(1, 0.93, 0.7, 0.13), Color(1, 0.93, 0.7, 0.0), Color(1, 0.93, 0.7, 0.0)])
		var sm := CanvasItemMaterial.new()
		sm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		shaft.material = sm
	# Fireflies over the clearing and the moat, leaves drifting down.
	var flies := _particles("Fireflies", load("res://assets/fx/mote.png"), 34, 7.0, Rect2(0, 260, 1920, 200))
	flies.color = Color(1.0, 0.82, 0.45)
	flies.gravity = Vector2(0, -2)
	flies.initial_velocity_min = 3.0
	flies.initial_velocity_max = 9.0
	flies.spread = 180.0
	flies.scale_amount_min = 0.5
	flies.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
	flies.color_ramp = ramp
	var fm := CanvasItemMaterial.new()
	fm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	flies.material = fm
	flies.z_index = 14
	var leaves := _particles("Leaves", load("res://assets/fx/leaf.png"), 16, 11.0, Rect2(0, 0, 1920, 60))
	leaves.gravity = Vector2(5, 16)
	leaves.initial_velocity_min = 4.0
	leaves.initial_velocity_max = 12.0
	leaves.angular_velocity_min = -90.0
	leaves.angular_velocity_max = 90.0
	leaves.z_index = 14
	var amber := _particles("LeavesAmber", load("res://assets/fx/leaf_amber.png"), 8, 12.0, Rect2(0, 0, 1920, 60))
	amber.gravity = Vector2(7, 14)
	amber.initial_velocity_min = 4.0
	amber.initial_velocity_max = 10.0
	amber.z_index = 14


# --- Foreground --------------------------------------------------------------------------

## The foreground plane: P5's own foreground art, close to the camera, along the
## room's top and bottom edges only, so it frames the screen and never stands
## among the props on a walking line. It scrolls faster than the playfield
## sideways (FG) and sits in the world vertically, so it never slides when the
## camera rises or falls. Lanterns never light it.
const FG := 1.2


func _build_foreground() -> void:
	var p := _node(Parallax2D.new(), "Foreground", _root) as Parallax2D
	p.scroll_scale = Vector2(FG, 1.0)
	p.repeat_size = Vector2(720, 0)
	p.repeat_times = 4
	p.z_index = 30  # in front of everything in the room, under the screen vignette
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	# Canopy and hanging vines across the room's top edge.
	var top := _sprite(p, PARALLAX + "fg.png", Rect2(0, 0, 720, 132), Vector2(0, -8))
	top.name = "Canopy"
	top.material = mat
	top.modulate = Color(0.55, 0.55, 0.62)
	# Fern tops rising in front of the floor below the crypt: the strip's tallest
	# fronds (row 188) reach 8 px under the crypt's walking line (row 37).
	var ferns := _sprite(p, PARALLAX + "fg.png", Rect2(0, 150, 720, 106), Vector2(0, 37 * TILE + 8 - 38))
	ferns.name = "Ferns"
	ferns.material = mat
	ferns.modulate = Color(0.5, 0.5, 0.58)
