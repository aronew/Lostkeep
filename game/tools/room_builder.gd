extends SceneTree
## Shared tools for building rooms from a plan. A room's own builder script
## extends this one, sets the plan (rock, spaces, masses, materials, back walls)
## and calls the steps in order:
##
##   var tileset := _shared()      materials, the black-box TileSet, Kleo's scene
##   _begin("RoomName")            the room's root
##   ... the room's own parallax ...
##   _back_walls()                 the far walls of its enclosed spaces
##   var t := _terrain(tileset)    the collision layers and the skin that paints them
##   ... the room's own landmarks, props, machines, atmosphere, doors ...
##   _finish()                     Kleo, the camera, the vignette; saves the scene
##
## The plan follows the blockout method: rock first, spaces carved out of it,
## masses put back, placed pieces last. Every number is in tiles (16 px).

const TILE := 16
const ENV := "res://assets/environment/ironbark/"
const TERRAIN := ENV + "terrain/"
const PARALLAX := ENV + "parallax/"
const KLEO_PATH := "res://scenes/player/kleo.tscn"

# --- The room plan, set by the room's own script (tiles) ----------------------------
var room := Rect2i(0, 0, 120, 40)
## Rock: [x, y, w, h, material]  (0 earth, 1 stone)
var rock := []
## Spaces carved out of the rock: [x, y, w, h]
var spaces := []
## Masses put back, on their own layer: [x, y, w, h, material]
var masses := []
## Solid cells inside these become stone (masonry).
var stone := []
## Cells painted by placed art instead of the skin.
var skip := []
## Back walls behind enclosed spaces: masonry, and raw earth.
var back := []
var back_earth := []
var spawn := Vector2.ZERO
var room_path := ""

var _root: Node2D
var _earth: Resource
var _stone: Resource


# --- The steps ------------------------------------------------------------------------

## The terrain materials, the black-box TileSet and Kleo's scene. Returns the TileSet.
func _shared() -> TileSet:
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
	var stone_mat := _material("stone", int(kit.get("stone_top_line", 13)), int(kit["stone_under_line"]), int(kit["stone_wall_face"]), 0.0, Color("#b3a2b9"))
	stone_mat.corner_top = load(TERRAIN + "stone_corner_top.png")
	stone_mat.corner_top_anchor = _vec(kit["stone_corner_top"])
	stone_mat.corner_under = load(TERRAIN + "stone_corner_under.png")
	stone_mat.corner_under_anchor = _vec(kit["stone_corner_under"])
	stone_mat.corner_under_reach = float(kit["stone_corner_under_reach"])
	# (corner_under_inner stays off: where a crypt ends at a wall, the arcade's own
	# pier meets it; an end arch laid over that pier doubles the stonework.)
	ResourceSaver.save(stone_mat, stone_mat.resource_path)
	_earth = earth
	_stone = stone_mat
	var tileset := _tileset()
	_build_kleo()
	return tileset


## The Old Crypt's masonry: the creative lead's SH1 and SH2 (pale blue-grey
## blocks, made for the Shrine Hall). A room calls this after _shared() to use
## it as its stone in place of the plum crypt kit.
func _use_shrine_stone() -> void:
	# A masonry fill that darkens with depth (5 tiles): thin slabs are solid
	# stone, as in the mockup, and only deep rock goes to the void.
	var m := _material("sh", 8, 48, 37, 5.0, Color(0, 0, 0, 0))
	m.corner_top = load(TERRAIN + "sh_corner_top.png")
	m.corner_top_anchor = Vector2(36, 29)
	m.corner_under = load(TERRAIN + "sh_corner_under.png")
	m.corner_under_anchor = Vector2(42, 42)
	ResourceSaver.save(m, m.resource_path)
	_stone = m


## The crypt stone after reference Y (CY1, CY2, CY2b: the creative lead's pick,
## the chunky brick). Its bands fade into the dark brick by brick themselves, so
## the inside of every mass is the void (fade 0). Cut by tools/make_crypt_cy.py.
var _cy_stone := false


func _use_crypt_y_stone() -> void:
	var m := _material("cy", 8, 48, 55, 0.0, Color(0, 0, 0, 0))
	m.corner_top = load(TERRAIN + "cy_corner_top.png")
	m.corner_top_anchor = Vector2(64, 8)
	m.corner_under = load(TERRAIN + "cy_corner_under.png")
	m.corner_under_anchor = Vector2(65, 65)
	m.thin_wall_depth = 12  # the quoin column
	m.inner_under = load(TERRAIN + "cy_inner_under.png")
	m.inner_under_anchor = Vector2(59, 48)
	m.inner_top = load(TERRAIN + "cy_inner_top.png")
	m.inner_top_anchor = Vector2(64, 48)
	ResourceSaver.save(m, m.resource_path)
	_stone = m
	_cy_stone = true


## The crypt stone's grade (the creative lead: "too bright"; reference Y's stone):
## SH1 to SH4 as painted are bluer and brighter than Y's grey-lavender, so the
## terrain, the placed islands and the props behind are all multiplied by this.
## Lit faces then measure about (72, 70, 87) on screen, as in Y.
const STONE_GRADE := Color(0.82, 0.76, 0.74)


func _grade_stone() -> void:
	for n in ["TerrainSkin", "PlacedArt", "Behind"]:
		if n == "TerrainSkin" and _cy_stone:
			continue  # the CY stone is painted in Y's colours already
		var node := _root.get_node_or_null(n) as CanvasItem
		if node:
			node.modulate = STONE_GRADE


## The crypts' depth (the creative lead: "more moody colors like in this
## reference" and "more parallaxed layers ... right now the game is looking
## sort of flat"). Back to front, behind the playfield:
##   Far      SH8, the distant hall (scroll 0.12)
##   FogFar   teal mist (0.22)
##   MidFar   OC6's arcades, faint and far (0.32)
##   FogMid   mist (0.45)
##   Mid      OC6's arcades again, nearer and darker (0.58)
##   Ruins    SH7's arches and pillars as dark silhouettes (0.78)
##   Mood     a multiply grade over all of them, in the world: dusky purple
##            high in the room, deep teal low, as in the reference
## The grade only touches the background; the playfield keeps its own colour.
const SHRINE_FAR_TINT := Color(0.74, 1.0, 0.8)
const MOOD_TOP := Color(1.0, 0.52, 1.0)
const MOOD_BOTTOM := Color(0.48, 1.0, 0.92)


func _depth_layer(layer_name: String, scroll: Vector2, repeat: float) -> Parallax2D:
	var p := _node(Parallax2D.new(), layer_name, _root) as Parallax2D
	p.scroll_scale = scroll
	p.repeat_size = Vector2(repeat, 0)
	p.repeat_times = 4
	p.z_index = -10
	return p


func _shrine_far() -> void:
	var h := float(room.size.y * TILE)
	var far := _depth_layer("Far", Vector2(0.12, 0.15), 768)
	for row in 2:
		var art := _sprite(far, ENV + "sh_far.png", Rect2(0, 0, 768, 360), Vector2(0, -40 + row * 358))
		art.name = "Art"
		art.modulate = SHRINE_FAR_TINT
	var fog_far := _node(Parallax2D.new(), "FogFar", _root) as Parallax2D
	fog_far.scroll_scale = Vector2(0.22, 0.25)
	fog_far.z_index = -10
	_fog(fog_far, Rect2(-300, h * 0.3, 2600, h * 0.6), Color("#3f9a86"), 0.34, Vector2(0.004, 0.0))
	var mid_far := _depth_layer("MidFar", Vector2(0.32, 0.35), 768)
	var a1 := _sprite(mid_far, ENV + "oc_mid_arcades.png", Rect2(0, 0, 768, 360), Vector2(-200, h * 0.18))
	a1.name = "Art"
	a1.modulate = Color(0.5, 0.68, 0.64, 0.55)
	var fog_mid := _node(Parallax2D.new(), "FogMid", _root) as Parallax2D
	fog_mid.scroll_scale = Vector2(0.45, 0.5)
	fog_mid.z_index = -10
	_fog(fog_mid, Rect2(-300, h * 0.45, 2800, h * 0.45), Color("#5e6a86"), 0.16, Vector2(0.006, 0.0))
	var mid := _depth_layer("Mid", Vector2(0.58, 0.62), 768)
	var a2 := _sprite(mid, ENV + "oc_mid_arcades.png", Rect2(0, 0, 768, 360), Vector2(150, h * 0.42))
	a2.name = "Art"
	a2.modulate = Color(0.3, 0.46, 0.44, 0.9)
	# The nearest ruins: arches and pillars standing at the bottom of the view, dark.
	var ruins := _depth_layer("Ruins", Vector2(0.78, 0.82), 900)
	var arc := ENV + "sh_arcades.png"
	for r in [[Rect2(4, 32, 128, 80), 40.0], [Rect2(272, 32, 20, 80), 300.0], [Rect2(144, 32, 64, 80), 470.0],
			[Rect2(248, 56, 16, 56), 640.0], [Rect2(272, 32, 20, 80), 760.0]]:
		var reg: Rect2 = r[0]
		var sil := _sprite(ruins, arc, reg, Vector2(r[1], h - reg.size.y * 2.0 - 8.0))
		sil.name = "Ruin"
		sil.scale = Vector2(2, 2)
		sil.modulate = Color(0.12, 0.17, 0.19)
	# The mood: a multiply grade over the whole background, purple above, teal below.
	var mood := _node(Polygon2D.new(), "Mood", _root) as Polygon2D
	mood.z_index = -9
	var w := float(room.size.x * TILE)
	mood.polygon = PackedVector2Array([Vector2(-400, -200), Vector2(w + 400, -200), Vector2(w + 400, h + 200), Vector2(-400, h + 200)])
	mood.vertex_colors = PackedColorArray([MOOD_TOP, MOOD_TOP, MOOD_BOTTOM, MOOD_BOTTOM])
	var mm := CanvasItemMaterial.new()
	mm.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	mm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	mood.material = mm


## In front of everything: OC7's dark rock along the top and bottom of the view.
## Scrolls faster than the playfield; stays put vertically.
func _crypt_foreground() -> void:
	var h := float(room.size.y * TILE)
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var p := _node(Parallax2D.new(), "Foreground", _root) as Parallax2D
	p.scroll_scale = Vector2(1.15, 1.0)
	p.repeat_size = Vector2(768, 0)
	p.repeat_times = 4
	p.z_index = 30
	var top := _sprite(p, ENV + "oc_foreground.png", Rect2(0, 0, 768, 96), Vector2(0, -6))
	top.name = "Top"
	top.material = unlit
	var bottom := _sprite(p, ENV + "oc_foreground.png", Rect2(0, 250, 768, 110), Vector2(0, h - 96))
	bottom.name = "Bottom"
	bottom.material = unlit
	# (A nearer layer of pillars and roots goes here when FG1 and FG2 arrive: the
	# first try, P5 and SH pieces blown up into black shapes, read as holes.)


## The room's root node.
func _begin(node_name: String) -> void:
	_root = Node2D.new()
	_root.name = node_name
	_root.set_script(load("res://scripts/world/room.gd"))
	_root.set("room_rect", room)
	_root.set("spawn", spawn)


## The far walls behind the room's enclosed spaces (`back`, `back_earth`).
func _back_walls() -> void:
	var back_node := _node(Node2D.new(), "BackWalls", _root)
	back_node.set_script(load("res://scripts/world/back_wall.gd"))
	back_node.z_index = -2
	back_node.set("fill", load(TERRAIN + "stone_fill.png"))
	back_node.set("course", load(TERRAIN + "stone_course.png"))
	var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN + "kit_anchors.json"))
	back_node.set("brightness", float(kit.get("back_brightness", 0.24)))
	back_node.set("course_brightness", float(kit.get("back_brightness", 0.34)))
	back_node.set("course_height", int(kit.get("back_course_height", 6)))
	var earth_node := _node(Node2D.new(), "EarthBackWalls", _root)
	earth_node.set_script(load("res://scripts/world/back_wall.gd"))
	earth_node.z_index = -2
	earth_node.set("fill", load(TERRAIN + "earth_fill.png"))
	earth_node.set("brightness", 0.4)
	earth_node.set("regions", _rects(back_earth))
	back_node.set("regions", _rects(back))


## The collision layers, the skin that paints them, and the layers art is placed
## on. Returns {"behind", "placed", "front"}: behind Kleo, art that replaces the
## skin, and in front of Kleo.
func _terrain(tileset: TileSet) -> Dictionary:
	var behind := _node(Node2D.new(), "Behind", _root)  # landmarks and props behind Kleo
	behind.z_index = 2
	var layers := _build_solid(tileset)
	var solid: TileMapLayer = layers[0]
	var skin := _node(Node2D.new(), "TerrainSkin", _root)
	skin.set_script(load("res://scripts/world/terrain_skin.gd"))
	skin.z_index = 4
	skin.set("room_rect", room)
	skin.set("materials", Array([_earth, _stone], TYPE_OBJECT, &"Resource", load("res://scripts/world/terrain_material.gd")))
	skin.set("skip_regions", _rects(skip))
	skin.set("solid_layer", solid)
	skin.set("mass_layer", layers[1])
	var placed := _node(Node2D.new(), "PlacedArt", _root)  # art that replaces the skin
	placed.z_index = 5
	var front := _node(Node2D.new(), "Front", _root)  # in front of Kleo
	front.z_index = 20
	return {"behind": behind, "placed": placed, "front": front}


## Kleo, the camera and the screen vignette; then the scene is saved.
func _finish() -> void:
	var kleo: Node = load(KLEO_PATH).instantiate()
	kleo.name = "Kleo"
	_node(kleo, "Kleo", _root, false)
	kleo.position = spawn
	var cam := _node(Camera2D.new(), "Camera", _root)
	cam.set_script(load("res://scripts/core/camera_rig.gd"))
	cam.position = spawn

	var screen := _node(CanvasLayer.new(), "Screen", _root)
	screen.layer = 50
	var vig := _node(ColorRect.new(), "Vignette", screen)
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.size = Vector2(640, 360)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = load("res://shaders/vignette.gdshader")
	vig.material = vm

	_save_scene(_root, room_path)
	_root.free()
	print("built ", room_path)


## Saves a scene, unless it only differs from the file on disk by the random
## node IDs Godot assigns: a rebuild that changes nothing leaves no diff.
func _save_scene(node: Node, path: String) -> void:
	var ps := PackedScene.new()
	ps.pack(node)
	var tmp := "res://.build_tmp.tscn"
	ResourceSaver.save(ps, tmp)
	var re := RegEx.new()
	re.compile("unique_id=\\d+")
	var fresh := FileAccess.get_file_as_string(tmp)
	var old := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	if old != "" and re.sub(fresh, "", true) == re.sub(old, "", true):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		return
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))


## A door in the room's edge: `rect` (tiles) is the opening. Kleo walking into its
## outer strip goes to `target_door` in `target_scene`; arriving here, she
## appears just inside it. `side` is -1 for a door in the west edge, 1 for east.
func _door(door_name: String, rect: Rect2i, side: int, target_scene: String, target_door: String) -> void:
	var doors := _root.get_node_or_null("Doors")
	if doors == null:
		doors = _node(Node2D.new(), "Doors", _root)
	var floor_y := float(rect.end.y * TILE)
	var edge_x := float((rect.position.x if side < 0 else rect.end.x) * TILE)
	var mark := _node(Marker2D.new(), door_name, doors) as Marker2D
	mark.position = Vector2(edge_x - side * 40.0, floor_y)
	mark.set_meta("facing", -side)
	var exit := _node(Area2D.new(), door_name + "Exit", doors) as Area2D
	exit.set_script(load("res://scripts/world/room_exit.gd"))
	exit.set("target_scene", target_scene)
	exit.set("target_door", target_door)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, rect.size.y * TILE)
	cs.shape = shape
	cs.position = Vector2(edge_x - side * 7.0, floor_y - rect.size.y * TILE * 0.5)
	_node(cs, "Shape", exit)


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
	_save_scene(k, KLEO_PATH)
	k.free()


# --- Collision ----------------------------------------------------------------------------

func _build_solid(tileset: TileSet) -> Array:
	var layer := _node(TileMapLayer.new(), "Solid", _root) as TileMapLayer
	layer.tile_set = tileset
	layer.add_to_group("solid_tiles", true)
	var mass_layer := _node(TileMapLayer.new(), "Masses", _root) as TileMapLayer
	mass_layer.tile_set = tileset
	mass_layer.add_to_group("solid_tiles", true)
	var cells := {}
	var mass_cells := {}
	for r in rock:
		_fill_cells(cells, r, r[4])
	for s in spaces:
		for x in range(s[0], s[0] + s[2]):
			for y in range(s[1], s[1] + s[3]):
				cells.erase(Vector2i(x, y))
	for m in masses:
		_fill_cells(mass_cells, m, m[4])
	for st in stone:
		for x in range(st[0], st[0] + st[2]):
			for y in range(st[1], st[1] + st[3]):
				var c := Vector2i(x, y)
				if cells.has(c):
					cells[c] = 1
	for c in cells:
		layer.set_cell(c, 0, Vector2i(cells[c], 0))
	for c in mass_cells:
		mass_layer.set_cell(c, 0, Vector2i(mass_cells[c], 0))
	# The room's side walls: nothing passes the west or east edge.
	for side in [[Vector2(0, 0), Vector2(1, 0)], [Vector2(room.end.x * TILE, 0), Vector2(-1, 0)]]:
		var wall := _node(StaticBody2D.new(), "Edge", _root)
		var ws := CollisionShape2D.new()
		var wb := WorldBoundaryShape2D.new()
		wb.normal = side[1]
		ws.shape = wb
		_node(ws, "Shape", wall)
		wall.position = side[0]
	return [layer, mass_layer]


func _fill_cells(cells: Dictionary, r: Array, mat: int) -> void:
	for x in range(r[0], r[0] + r[2]):
		for y in range(r[1], r[1] + r[3]):
			cells[Vector2i(x, y)] = mat


func _rects(list: Array) -> Array:
	var out := []
	for r in list:
		out.append(Rect2i(r[0], r[1], r[2], r[3]))
	return Array(out, TYPE_RECT2I, &"", null)


# --- Parallax, fog, particles, edges ----------------------------------------------------

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


## The room's west and east edges fade into darkness, in front of Kleo, so the
## room ends in passages leading on instead of an invisible wall.
func _edge_shades() -> void:
	var w := float(room.size.x * TILE)
	var h := float(room.size.y * TILE)
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


# --- Machines and water -------------------------------------------------------------------

## A rope lift in a shaft: a shortcut that opens from below. `pos` is the centre
## of its deck at the top stop (the floor line it plugs); it travels `drop` px
## down. It starts at the top, jammed; the winch stands at the bottom, `winch_dx`
## px from the shaft's centre. Its crossbeam, 3 tiles above the top stop, is a
## one-way perch.
func _lift(node_name: String, pos: Vector2, drop: float, winch_dx := -3.5 * TILE, flag := "") -> Node2D:
	var timber := ENV + "keep_timber_kit.png"
	var lift := _node(Node2D.new(), node_name, _root)
	lift.set_script(load("res://scripts/world/guard_lift.gd"))
	lift.position = pos
	lift.z_index = 6
	lift.set("bottom_y", drop)
	lift.set("rope_top", -34.0)
	if flag != "":
		lift.set("flag", flag)  # remembered once freed, across rooms
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
	winch.position = Vector2(winch_dx, drop)
	var wc := CollisionShape2D.new()
	var wr := RectangleShape2D.new()
	wr.size = Vector2(28, 30)
	wc.shape = wr
	wc.position = Vector2(0, -15)
	_node(wc, "Shape", winch)
	_sprite(winch, timber, Rect2(201, 57, 35, 31), Vector2(-17, -31)).name = "Art"
	winch.set("prompt_offset", Vector2(0, -42))
	return lift


## Deep, dark water Kleo can't swim yet (falling in returns her to safe ground),
## with a glint below the surface at `glint_pos`.
func _water(node_name: String, pos: Vector2, size: Vector2, glint_pos: Vector2) -> Node2D:
	var water := _node(Node2D.new(), node_name, _root)
	water.set_script(load("res://scripts/world/moat_water.gd"))
	water.position = pos
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
	var glint := _sprite(water, "res://assets/characters/kleo/fx_small.png", Rect2(0, 0, 64, 64), glint_pos)
	glint.name = "Glint"
	glint.scale = Vector2(0.5, 0.5)
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	gm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glint.material = gm
	glint.modulate = Color(0.6, 1.0, 0.95)
	glint.z_index = 1
	glint.set_script(load("res://scripts/fx/pulse.gd"))
	water.set("size", size)
	surf.size = size
	(ash.shape as RectangleShape2D).size = Vector2(size.x, size.y - 10)
	ash.position = Vector2(size.x * 0.5, size.y * 0.5 + 5)
	return water


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
