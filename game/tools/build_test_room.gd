extends SceneTree
## Builds the Ironbark test room from the room plan below, along with Kleo's
## scene, the black-box TileSet and the terrain materials, and saves them as
## ordinary scenes. After that, edit them in the editor as usual. Re-running
## this script overwrites scenes/rooms/ironbark_test_room.tscn.
##
##   godot --headless --path game --script res://tools/build_test_room.gd
##
## The plan follows the blockout method: rock first, spaces carved out of it,
## masses put back, placed pieces last. Every number is in tiles (16 px).

const TILE := 16
const ENV := "res://assets/environment/ironbark/"
const TERRAIN := ENV + "terrain/"
const PARALLAX := ENV + "parallax/"
const ROOM_PATH := "res://scenes/rooms/ironbark_test_room.tscn"
const KLEO_PATH := "res://scenes/player/kleo.tscn"

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
const STONE := [[0, 28, 30, 12], [30, 31, 61, 9], [91, 28, 4, 12]]
## Cells painted by placed art instead of the skin.
const SKIP := [[33, 21, 15, 2], [52, 17, 22, 2], [95, 28, 7, 2], [113, 28, 7, 2]]
## Back walls behind enclosed spaces.
const BACK := [[8, 32, 22, 5], [0, 32, 8, 5], [30, 32, 56, 5], [86, 32, 5, 5], [24, 24, 4, 8]]
## Back walls of raw earth: the collapse that drops into the crypt.
const BACK_EARTH := [[78, 28, 4, 4]]

const SPAWN := Vector2(232, 384)
## The colour under the mid forest layer, where its mist meets the floors
## (printed by tools/make_terrain.py as "mid base colour").
const MID_BASE := Color("#24535b")

var _root: Node2D


func _initialize() -> void:
	# Fade 0: the inside of every mass is the void; only the edge bands are painted.
	# Line rows as tools/make_terrain.py prints them; the painted kits' face columns
	# and corner anchors come from the file it writes.
	var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN + "kit_anchors.json"))
	var earth := _material("earth", 22, 22, int(kit["earth_wall_face"]), 0.0, Color(0, 0, 0, 0))
	earth.corner_top = load(TERRAIN + "earth_corner_top.png")
	earth.corner_top_anchor = _vec(kit["earth_corner_top"])
	earth.corner_under = load(TERRAIN + "earth_corner_under.png")
	earth.corner_under_anchor = _vec(kit["earth_corner_under"])
	ResourceSaver.save(earth, earth.resource_path)
	var stone := _material("stone", int(kit.get("stone_top_line", 13)), int(kit["stone_under_line"]), int(kit["stone_wall_face"]), 0.0, Color("#b3a2b9"))
	stone.corner_top = load(TERRAIN + "stone_corner_top.png")
	stone.corner_top_anchor = _vec(kit["stone_corner_top"])
	stone.corner_under = load(TERRAIN + "stone_corner_under.png")
	stone.corner_under_anchor = _vec(kit["stone_corner_under"])
	stone.corner_under_reach = float(kit["stone_corner_under_reach"])
	# (corner_under_inner stays off: where a crypt ends at a wall, the arcade's own
	# pier meets it; an end arch laid over that pier doubles the stonework.)
	ResourceSaver.save(stone, stone.resource_path)
	var tileset := _tileset()
	_build_kleo()
	_build_room(tileset, earth, stone)
	print("built ", ROOM_PATH)
	quit()


# --- Resources --------------------------------------------------------------------------

func _material(kind: String, top_line: int, under_line: int, wall_face: int, fade: float, lip: Color) -> Resource:
	var m: Resource = load("res://scripts/world/terrain_material.gd").new()
	m.fill = load(TERRAIN + kind + "_fill.png")
	m.top_band = load(TERRAIN + kind + "_top.png")
	m.top_line = top_line
	m.under_band = load(TERRAIN + kind + "_under.png")
	m.under_line = under_line
	m.wall_band = load(TERRAIN + kind + "_wall.png")
	m.wall_face = wall_face
	m.fade_tiles = fade
	m.lip_color = lip
	m.top_lit = 64  # the whole band: it ends in the void
	m.outline_color = Color(0, 0, 0, 0)  # faces outline themselves: their proud stones are shaded
	ResourceSaver.save(m, "res://scenes/world/terrain_%s.tres" % kind)
	return load("res://scenes/world/terrain_%s.tres" % kind)


func _vec(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


func _tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/world/blockout_tiles.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var h := TILE * 0.5
	for x in 2:  # 0 earth, 1 stone
		src.create_tile(Vector2i(x, 0))
		var td := src.get_tile_data(Vector2i(x, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))
	ResourceSaver.save(ts, "res://scenes/world/blockout_tileset.tres")
	return load("res://scenes/world/blockout_tileset.tres")


func _light_texture(size := 128) -> GradientTexture2D:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.36, 0.55, 0.75, 0.92])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.78), Color(1, 1, 1, 0.55),
		Color(1, 1, 1, 0.34), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t


# --- Kleo -------------------------------------------------------------------------------

func _build_kleo() -> void:
	var k := CharacterBody2D.new()
	k.name = "Kleo"
	k.set_script(load("res://scripts/player/kleo.gd"))
	k.collision_layer = 2
	k.collision_mask = 1 | 64  # the rock, and one-way platforms
	k.floor_snap_length = 4.0
	k.z_index = 10
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 26)
	shape.shape = rect
	shape.position = Vector2(0, -13)
	_add(k, shape, k)
	var spr := AnimatedSprite2D.new()
	spr.name = "Sprite"
	spr.sprite_frames = load("res://scenes/player/kleo_frames.tres")
	spr.animation = &"idle"
	spr.offset = Vector2(0, -24)
	_add(k, spr, k)
	var hit := Area2D.new()
	hit.name = "Hitbox"
	hit.collision_layer = 8
	hit.collision_mask = 4
	hit.monitorable = false
	_add(k, hit, k)
	var hs := CollisionShape2D.new()
	hs.name = "Shape"
	hs.shape = RectangleShape2D.new()
	_add(hit, hs, k)
	var inter := Area2D.new()
	inter.name = "Interact"
	inter.collision_layer = 0
	inter.collision_mask = 32
	inter.monitorable = false
	_add(k, inter, k)
	var is_ := CollisionShape2D.new()
	is_.name = "Shape"
	var ir := RectangleShape2D.new()
	ir.size = Vector2(18, 26)
	is_.shape = ir
	is_.position = Vector2(0, -13)
	_add(inter, is_, k)
	var lamp := PointLight2D.new()
	lamp.name = "Lantern"
	lamp.texture = _light_texture()
	lamp.texture_scale = 0.75
	lamp.color = Color(1.0, 0.78, 0.48)
	lamp.energy = 0.55
	lamp.position = Vector2(-5, -10)
	lamp.set_script(load("res://scripts/world/lantern_light.gd"))
	_add(k, lamp, k)
	var ps := PackedScene.new()
	ps.pack(k)
	ResourceSaver.save(ps, KLEO_PATH)
	k.free()


# --- The room ---------------------------------------------------------------------------

func _build_room(tileset: TileSet, earth: Resource, stone: Resource) -> void:
	_root = Node2D.new()
	_root.name = "IronbarkTestRoom"
	_root.set_script(load("res://scripts/world/room.gd"))
	_root.set("room_rect", ROOM)
	_root.set("spawn", SPAWN)

	_build_parallax()
	var back := _node(Node2D.new(), "BackWalls", _root)
	back.set_script(load("res://scripts/world/back_wall.gd"))
	back.z_index = -2
	back.set("fill", load(TERRAIN + "stone_fill.png"))
	back.set("course", load(TERRAIN + "stone_course.png"))
	var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN + "kit_anchors.json"))
	back.set("brightness", float(kit.get("back_brightness", 0.24)))
	back.set("course_brightness", float(kit.get("back_brightness", 0.34)))
	back.set("course_height", int(kit.get("back_course_height", 6)))
	var back_earth := _node(Node2D.new(), "EarthBackWalls", _root)
	back_earth.set_script(load("res://scripts/world/back_wall.gd"))
	back_earth.z_index = -2
	back_earth.set("fill", load(TERRAIN + "earth_fill.png"))
	back_earth.set("brightness", 0.4)
	back_earth.set("regions", _rects(BACK_EARTH))
	back.set("regions", _rects(BACK))

	var behind := _node(Node2D.new(), "Behind", _root)  # landmarks and props behind Kleo
	behind.z_index = 2
	var layers := _build_solid(tileset)
	var solid: TileMapLayer = layers[0]
	var skin := _node(Node2D.new(), "TerrainSkin", _root)
	skin.set_script(load("res://scripts/world/terrain_skin.gd"))
	skin.z_index = 4
	skin.set("room_rect", ROOM)
	skin.set("materials", Array([earth, stone], TYPE_OBJECT, &"Resource", load("res://scripts/world/terrain_material.gd")))
	skin.set("skip_regions", _rects(SKIP))
	skin.set("solid_layer", solid)
	skin.set("mass_layer", layers[1])
	var placed := _node(Node2D.new(), "PlacedArt", _root)  # art that replaces the skin
	placed.z_index = 5
	var front := _node(Node2D.new(), "Front", _root)  # in front of Kleo
	front.z_index = 20

	_build_landmarks(behind, placed)
	_build_props(behind, placed, front)
	_build_machines()
	_build_atmosphere(front)
	_build_foreground()
	_edge_shades()

	var kleo: Node = load(KLEO_PATH).instantiate()
	kleo.name = "Kleo"
	_node(kleo, "Kleo", _root, false)
	kleo.position = SPAWN
	var cam := _node(Camera2D.new(), "Camera", _root)
	cam.set_script(load("res://scripts/core/camera_rig.gd"))
	cam.position = SPAWN

	var screen := _node(CanvasLayer.new(), "Screen", _root)
	screen.layer = 50
	var vig := _node(ColorRect.new(), "Vignette", screen)
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.size = Vector2(640, 360)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = load("res://shaders/vignette.gdshader")
	vig.material = vm

	var ps := PackedScene.new()
	ps.pack(_root)
	ResourceSaver.save(ps, ROOM_PATH)
	_root.free()


func _build_solid(tileset: TileSet) -> Array:
	var layer := _node(TileMapLayer.new(), "Solid", _root) as TileMapLayer
	layer.tile_set = tileset
	layer.add_to_group("solid_tiles", true)
	var masses := _node(TileMapLayer.new(), "Masses", _root) as TileMapLayer
	masses.tile_set = tileset
	masses.add_to_group("solid_tiles", true)
	var cells := {}
	var mass_cells := {}
	for r in ROCK:
		_fill_cells(cells, r, r[4])
	for s in SPACES:
		for x in range(s[0], s[0] + s[2]):
			for y in range(s[1], s[1] + s[3]):
				cells.erase(Vector2i(x, y))
	for m in MASSES:
		_fill_cells(mass_cells, m, m[4])
	for st in STONE:
		for x in range(st[0], st[0] + st[2]):
			for y in range(st[1], st[1] + st[3]):
				var c := Vector2i(x, y)
				if cells.has(c):
					cells[c] = 1
	for c in cells:
		layer.set_cell(c, 0, Vector2i(cells[c], 0))
	for c in mass_cells:
		masses.set_cell(c, 0, Vector2i(mass_cells[c], 0))
	# The room's side walls: nothing passes the west or east edge.
	for side in [[Vector2(0, 0), Vector2(1, 0)], [Vector2(ROOM.end.x * TILE, 0), Vector2(-1, 0)]]:
		var wall := _node(StaticBody2D.new(), "Edge", _root)
		var ws := CollisionShape2D.new()
		var wb := WorldBoundaryShape2D.new()
		wb.normal = side[1]
		ws.shape = wb
		_node(ws, "Shape", wall)
		wall.position = side[0]
	return [layer, masses]


func _fill_cells(cells: Dictionary, r: Array, mat: int) -> void:
	for x in range(r[0], r[0] + r[2]):
		for y in range(r[1], r[1] + r[3]):
			cells[Vector2i(x, y)] = mat


func _rects(list: Array) -> Array:
	var out := []
	for r in list:
		out.append(Rect2i(r[0], r[1], r[2], r[3]))
	return Array(out, TYPE_RECT2I, &"", null)


# --- Parallax ---------------------------------------------------------------------------

func _parallax(name: String, scale: Vector2, tex_path: String, y: float, base_color := Color(0, 0, 0, 0)) -> Parallax2D:
	var p := _node(Parallax2D.new(), name, _root) as Parallax2D
	p.scroll_scale = scale
	var tex: Texture2D = load(tex_path)
	p.repeat_size = Vector2(tex.get_width(), 0)
	p.repeat_times = 4
	p.z_index = -10
	var s := _node(Sprite2D.new(), "Art", p) as Sprite2D
	s.texture = tex
	s.centered = false
	s.position = Vector2(0, y)
	if base_color.a > 0.0:
		var base := _node(ColorRect.new(), "Base", p) as ColorRect
		base.color = base_color
		base.mouse_filter = Control.MOUSE_FILTER_IGNORE
		base.position = Vector2(0, y + tex.get_height() - 1)
		base.size = Vector2(tex.get_width(), 420)
	return p


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


func _fog(parent: Node, rect: Rect2, tint: Color, density: float, drift: Vector2) -> void:
	var r := _node(ColorRect.new(), "Fog", parent) as ColorRect
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/fog.gdshader")
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 128
	nt.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = 0.012
	n.fractal_octaves = 3
	nt.noise = n
	m.set_shader_parameter("noise", nt)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("density", density)
	m.set_shader_parameter("drift", drift)
	m.set_shader_parameter("scale", Vector2(rect.size.x / 512.0, rect.size.y / 256.0))
	r.material = m


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

	# The floating island (upper line), its flat top on the collision.
	_sprite(placed, ENV + "ironbark_islands.png", Rect2(130, 2, 246, 85), Vector2(33 * TILE - 3, 21 * TILE - 31)).name = "Island"
	# The root shelf: IB4's big island with its sapling. Its walking line is row 33
	# of the region (the sapling rises above it), and its flat top (x 10 to 374) is
	# centred on the 22-tile mass.
	_sprite(placed, ENV + "ironbark_islands.png", Rect2(9, 86, 366, 101), Vector2(52 * TILE + 176 - 183, 17 * TILE - 33)).name = "RootShelf"

	# The broken bridge: its west span with the torn banner, the east span beyond the gap.
	# The sheet's west end is an earth abutment that stops in a hard line at the
	# water; the bank is the skin's masonry quay instead, so only the arches and,
	# above the deck, the lantern post and banner are placed.
	# One tile west of the gap's edge, so the bank under its post is four tiles wide
	# (its two faces meet) and the span reaches the gap at x 102.
	var bw := Vector2(101 * TILE - 144, 28 * TILE - 63)
	_sprite(placed, ENV + "landmark_arch_bridge.png", Rect2(49, 2, 96, 126), bw + Vector2(48, 0)).name = "BridgeWest"
	_sprite(placed, ENV + "landmark_arch_bridge.png", Rect2(1, 2, 48, 61), bw).name = "BridgePost"
	_light(placed, bw + Vector2(44, 28), Color(1.0, 0.78, 0.45), 0.8, 0.8, "BridgeLantern")
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
	var timber := ENV + "keep_timber_kit.png"
	# The guard's rope lift (the shortcut), at the top of its shaft, jammed.
	var lift := _node(Node2D.new(), "GuardLift", _root)
	lift.set_script(load("res://scripts/world/guard_lift.gd"))
	lift.position = Vector2(26 * TILE, 24 * TILE)
	lift.z_index = 6
	lift.set("bottom_y", 13.0 * TILE)
	lift.set("rope_top", -34.0)
	var frame := _node(Node2D.new(), "Frame", lift)
	_sprite(frame, timber, Rect2(10, 22, 25, 36), Vector2(-40, -36))
	_sprite(frame, timber, Rect2(10, 22, 25, 36), Vector2(15, -36))
	# The crossbeam's solid top (the sprite's row 2) is 3 tiles up: a jump reaches it.
	_sprite(frame, timber, Rect2(42, 13, 96, 29), Vector2(-48, -50))
	var beam := _node(StaticBody2D.new(), "Crossbeam", lift) as StaticBody2D
	beam.collision_layer = 64  # one-way platforms: drop through with down + jump
	beam.collision_mask = 0
	var bc := CollisionShape2D.new()
	var br := RectangleShape2D.new()
	br.size = Vector2(92, 8)
	bc.shape = br
	bc.position = Vector2(0, -44)
	bc.one_way_collision = true
	_node(bc, "Shape", beam)
	var plat := _node(AnimatableBody2D.new(), "Platform", lift) as AnimatableBody2D
	plat.collision_layer = 1
	plat.collision_mask = 0
	plat.sync_to_physics = true
	var pc := CollisionShape2D.new()
	var pr := RectangleShape2D.new()
	pr.size = Vector2(64, 8)
	pc.shape = pr
	pc.position = Vector2(0, 4)
	_node(pc, "Shape", plat)
	_sprite(plat, timber, Rect2(42, 13, 64, 16), Vector2(-32, -2)).name = "Deck"
	var rider := _node(Area2D.new(), "Rider", plat) as Area2D
	rider.collision_layer = 0
	rider.collision_mask = 2
	var rc := CollisionShape2D.new()
	var rr := RectangleShape2D.new()
	rr.size = Vector2(56, 10)
	rc.shape = rr
	rc.position = Vector2(0, -6)
	_node(rc, "Shape", rider)
	var winch := _node(Area2D.new(), "Winch", lift) as Area2D
	winch.set_script(load("res://scripts/world/winch.gd"))
	winch.position = Vector2(-3.5 * TILE, 13 * TILE)
	var wc := CollisionShape2D.new()
	var wr := RectangleShape2D.new()
	wr.size = Vector2(28, 30)
	wc.shape = wr
	wc.position = Vector2(0, -15)
	_node(wc, "Shape", winch)
	_sprite(winch, timber, Rect2(201, 57, 35, 31), Vector2(-17, -31)).name = "Art"
	winch.set("prompt_offset", Vector2(0, -42))

	# The moat: deep water under the bridge (Deep-Glow Breath lock D1).
	var water := _node(Node2D.new(), "Moat", _root)
	water.set_script(load("res://scripts/world/moat_water.gd"))
	water.position = Vector2(95 * TILE, 31 * TILE)
	water.z_index = 12
	var area := _node(Area2D.new(), "Area", water) as Area2D
	area.collision_layer = 0
	area.collision_mask = 2
	var ash := CollisionShape2D.new()
	ash.shape = RectangleShape2D.new()
	_node(ash, "Shape", area)
	var surf := _node(ColorRect.new(), "Surface", water) as ColorRect
	surf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wm := ShaderMaterial.new()
	wm.shader = load("res://shaders/water.gdshader")
	surf.material = wm
	var glint := _sprite(water, "res://assets/characters/kleo/fx_small.png", Rect2(0, 0, 64, 64), Vector2(156, 34))
	glint.name = "Glint"
	glint.scale = Vector2(0.5, 0.5)
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	gm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glint.material = gm
	glint.modulate = Color(0.6, 1.0, 0.95)
	glint.z_index = 1
	glint.set_script(load("res://scripts/fx/pulse.gd"))
	water.set("size", Vector2(25 * TILE, 6 * TILE))
	surf.size = Vector2(25 * TILE, 6 * TILE)
	(ash.shape as RectangleShape2D).size = Vector2(25 * TILE, 6 * TILE - 10)
	ash.position = Vector2(12.5 * TILE, 3 * TILE + 5)


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


## The room's west and east edges fade into darkness, in front of Kleo, so the
## room ends in passages leading on instead of an invisible wall.
func _edge_shades() -> void:
	var w := float(ROOM.size.x * TILE)
	var h := float(ROOM.size.y * TILE)
	var void_col := Color(0.043, 0.031, 0.071)
	for side in [[0.0, 1.0], [w, -1.0]]:
		var x: float = side[0]
		var inward: float = side[1]
		var shade := _node(Polygon2D.new(), "EdgeShade", _root) as Polygon2D
		shade.z_index = 25
		var depth := 64.0
		# Four bands, stepped like the rest of the pixel art.
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in 5:
			var t := float(i) / 4.0
			var a := pow(1.0 - t, 1.6)
			pts.append(Vector2(x + inward * depth * t, 0))
			cols.append(Color(void_col, a))
		for i in range(4, -1, -1):
			var t := float(i) / 4.0
			var a := pow(1.0 - t, 1.6)
			pts.append(Vector2(x + inward * depth * t, h))
			cols.append(Color(void_col, a))
		shade.polygon = pts
		shade.vertex_colors = cols


func _particles(name: String, tex: Texture2D, amount: int, life: float, box: Rect2) -> CPUParticles2D:
	var p := _node(CPUParticles2D.new(), name, _root) as CPUParticles2D
	p.texture = tex
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = box.size * 0.5
	p.position = box.get_center()
	p.direction = Vector2(1, 0.3)
	p.spread = 60.0
	return p


# --- Breakables -------------------------------------------------------------------

# The guard's belongings, cut from props_guard_belongings.png.
const CRATE_A := Rect2(3, 15, 33, 31)
const CRATE_B := Rect2(37, 23, 32, 23)
const CRATE_C := Rect2(71, 21, 30, 25)
const BARREL_BIG := Rect2(103, 11, 30, 35)
const BARREL := Rect2(135, 18, 24, 28)
const KEG := Rect2(161, 25, 19, 21)
const POT_BIG := Rect2(184, 16, 27, 30)
const POT := Rect2(212, 24, 20, 22)
const POT_SMALL := Rect2(235, 30, 15, 20)
const WOOD := Color(0.6, 0.42, 0.28)
const CLAY := Color(0.7, 0.45, 0.32)


## A breakable prop standing on the floor: `x` is its centre, `floor_y` the walking line.
func _breakable(tex_path: String, region: Rect2, x: float, floor_y: float, chips: Color) -> Node2D:
	var b := _node(Node2D.new(), "Breakable", _root) as Node2D
	b.set_script(load("res://scripts/world/breakable.gd"))
	b.position = Vector2(x, floor_y).round()
	b.z_index = 6
	b.set("chip_color", chips)
	b.set("piece_mask", _piece_mask(tex_path, region))
	var art := _sprite(b, tex_path, region, Vector2(-roundf(region.size.x * 0.5), -region.size.y + 1))
	art.name = "Art"
	var hb := _node(Area2D.new(), "Hurtbox", b) as Area2D
	hb.collision_layer = 4
	hb.collision_mask = 0
	hb.monitoring = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = region.size - Vector2(4, 2)
	hs.shape = hr
	hs.position = Vector2(0, -region.size.y * 0.5)
	_node(hs, "Shape", hb)
	return b


## Which grid pieces of a sprite region have pixels (see Breakable.grid_for).
func _piece_mask(tex_path: String, region: Rect2) -> int:
	var img := Image.load_from_file(ProjectSettings.globalize_path(tex_path))
	if img == null:
		return 0
	var grid := Vector2i(3 if region.size.x >= 26.0 else 2, 3 if region.size.y >= 26.0 else 2)
	var pw := floorf(region.size.x / grid.x)
	var ph := floorf(region.size.y / grid.y)
	var mask := 0
	for i in grid.x:
		for j in grid.y:
			var count := 0
			for x in range(int(region.position.x + i * pw), int(region.position.x + (i + 1) * pw)):
				for y in range(int(region.position.y + j * ph), int(region.position.y + (j + 1) * ph)):
					if img.get_pixel(x, y).a > 0.5:
						count += 1
			if count >= 6:
				mask |= 1 << (i * grid.y + j)
	return mask


# --- Helpers ------------------------------------------------------------------------------

func _add(parent: Node, child: Node, owner: Node) -> void:
	parent.add_child(child, true)
	child.owner = owner


func _node(n: Node, name: String, parent: Node, set_owner := true) -> Node:
	n.name = name
	parent.add_child(n, true)
	n.owner = _root
	return n


func _sprite(parent: Node, tex_path: String, region: Rect2, pos: Vector2) -> Sprite2D:
	var s := _node(Sprite2D.new(), "Sprite", parent) as Sprite2D
	s.texture = load(tex_path)
	s.region_enabled = true
	s.region_rect = region
	s.centered = false
	s.position = pos.round()
	return s


## A prop standing on the ground: `x` is its left edge, `floor_y` the walking line.
func _ground(parent: Node, tex_path: String, region: Rect2, x: float, floor_y: float, brightness: float, name: String) -> Sprite2D:
	var s := _sprite(parent, tex_path, region, Vector2(x, floor_y - region.size.y + 1))
	s.name = name
	if brightness < 1.0:
		s.modulate = Color(brightness, brightness, brightness)
	return s


func _light(parent: Node, pos: Vector2, color: Color, energy: float, scale: float, name: String) -> PointLight2D:
	var l := _node(PointLight2D.new(), name, parent) as PointLight2D
	l.texture = _light_texture()
	l.texture_scale = scale
	l.color = color
	l.energy = energy
	l.position = pos.round()
	l.set_script(load("res://scripts/world/lantern_light.gd"))
	return l
