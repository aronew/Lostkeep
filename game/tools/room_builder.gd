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
## The CY stone's grade: a step darker and a touch cooler than as painted.
const CY_GRADE := Color(0.8, 0.77, 0.86)
## The hidden rooms behind false walls: no detail is placed in them.
var _secret_rects: Array[Rect2i] = []
## Which detail pass `_finish()` runs: "crypt", "surface" or none.
var _detail_kind := ""
## The moody look (the creative lead: "I like that look instead of so bright",
## docs/mockups/mood/): set by a room before _finish(), which sinks it into
## a teal murk with fog along its floors. See _moody().
var _mood := false
## The detail pass in the creative lead's CH pieces (Book 1, CH4 hangings, CH5
## ledge dressing, CH8 floor front) instead of the SH flora. Set by a room
## before _finish(); IB-05 first, for approval.
var _ch_detail := false
## Where the detail pass stays away from, if not the skin's skip regions (a
## room whose painted bands are in `skip` still wants hangings under them).
var detail_skip = null
## Warm light along every walking edge, as in the moody mockup (the creative
## lead: "a little bit of light effect to the tops of the platforms"). See
## _rim_light(). IB-05 first, for approval.
var _rim := false


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
			# The CY stone a step darker (the creative lead: "a little too bright").
			(_root.get_node(n) as CanvasItem).modulate = CY_GRADE
			continue
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
	# Depth in two value steps in front of the playfield (the creative lead: "2
	# layers of foreground, one not all the way silhouetted and one full
	# silhouette"). Both frame the screen: they slide sideways faster than the
	# room (nearer the camera) but hold their height on screen (scroll y 0), so
	# a tall room has them on every floor and they never slide up or down when
	# the camera changes floors. Thin shapes (roots, rubble, a pillar), never big
	# blobs: a big black shape reads as a hole.
	_detail_kind = "crypt"
	var w := float(room.size.x * TILE)
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	# The mid step: roots and ivy along the top of the view, rubble, crystals and
	# a broken pillar along its bottom, darkened to about half value and tinted
	# toward the room's plum, their form still showing.
	var mid := _node(Parallax2D.new(), "Foreground", _root) as Parallax2D
	mid.scroll_scale = Vector2(1.15, 0.0)
	mid.repeat_size = Vector2(960, 0)
	mid.repeat_times = maxi(3, int(w / 960.0) + 3)
	mid.z_index = 30
	var mid_tint := Color(0.4, 0.36, 0.5)
	var pieces := [
		[ENV + "sh_flora.png", Rect2(224, 112, 20, 64), Vector2(60, -6), 2.0],
		[ENV + "sh_flora.png", Rect2(88, 112, 24, 64), Vector2(420, -10), 2.0],
		[ENV + "sh_flora.png", Rect2(184, 112, 16, 32), Vector2(700, -4), 2.0],
		[ENV + "oc_foreground.png", Rect2(0, 250, 120, 110), Vector2(180, 360 - 70), 1.0],
		[ENV + "sh_flora.png", Rect2(152, 0, 64, 40), Vector2(520, 360 - 50), 1.6],
		[ENV + "sh_arcades.png", Rect2(224, 80, 16, 32), Vector2(820, 360 - 58), 2.0],
	]
	for pc in pieces:
		var reg: Rect2 = pc[1]
		var sp := _sprite(mid, pc[0], reg, pc[2])
		sp.name = "MidPiece"
		sp.scale = Vector2(pc[3], pc[3])
		sp.modulate = mid_tint
		sp.material = unlit
	# The near step: pure silhouettes, sparse, scrolling fastest: long roots
	# from the top, rubble along the very bottom, a great pillar now and then.
	var near := _node(Parallax2D.new(), "ForegroundNear", _root) as Parallax2D
	near.scroll_scale = Vector2(1.5, 0.0)
	near.repeat_size = Vector2(1500, 0)
	near.repeat_times = maxi(3, int(w / 1500.0) + 3)
	near.z_index = 31
	var black := Color(0.03, 0.022, 0.05)
	var near_pieces := [
		[ENV + "sh_flora.png", Rect2(224, 112, 20, 64), Vector2(260, -14), 2.2],
		[ENV + "oc_foreground.png", Rect2(400, 290, 80, 70), Vector2(640, 360 - 44), 1.6],
		[ENV + "sh_arcades.png", Rect2(272, 32, 20, 80), Vector2(1100, -20), 4.8],
	]
	for pc in near_pieces:
		var reg: Rect2 = pc[1]
		var sp := _sprite(near, pc[0], reg, pc[2])
		sp.name = "Silhouette"
		sp.scale = Vector2(pc[3], pc[3])
		sp.modulate = black
		sp.material = unlit


# --- Detail: what hangs from the ceilings, what stands in front of the floors ----------------
#
# The creative lead: "every place needs 2 layers on the floor level to create
# depth", "hanging things on ceilings", "the stone looks so bare and weird with
# so many 90 degree corners". Once a room is built, this reads its collision
# and places, from the kit's art (stand-ins until the new cards in Book 1):
#   - along every ceiling, roots and ivy, each sized to the space below it;
#   - under every floor's end over open air, ivy over the corner;
#   - in front of the floors, the mid step (the art darkened to about 60 %, in
#     front of Kleo); the near step frames the screen (`_crypt_foreground`,
#     `_build_foreground`) until FD2's floor-front silhouettes arrive.
# Never in a door's way, on placed art, or in a secret room.

func _cellhash(c: Vector2i, salt: int) -> int:
	return absi((c.x * 73856093) ^ (c.y * 19349663) ^ (salt * 83492791)) % 1000


func _room_detail(surface: bool) -> void:
	var solid_layer := _root.get_node("Solid") as TileMapLayer
	var mass_layer := _root.get_node("Masses") as TileMapLayer
	var solid := {}
	for c in solid_layer.get_used_cells():
		solid[c] = true
	for c in mass_layer.get_used_cells():
		solid[c] = true
	var is_solid := func(c: Vector2i) -> bool: return solid.has(c) or not room.has_point(c)
	var skipped := func(c: Vector2i) -> bool:
		for r in (skip if detail_skip == null else detail_skip):
			if Rect2i(r[0], r[1], r[2], r[3]).grow(1).has_point(c):
				return true
		for r in _secret_rects:
			if r.grow(1).has_point(c):
				return true
		return c.x < room.position.x + 3 or c.x >= room.end.x - 3
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var hang_node := _node(Node2D.new(), "Hanging", _root) as Node2D
	hang_node.z_index = 3  # under the skin's bands: each tucks up under its ceiling
	var mid_node := _node(Node2D.new(), "FloorMid", _root) as Node2D
	mid_node.z_index = 26  # in front of Kleo
	if _ch_detail:
		_ch_room_detail(is_solid, skipped, hang_node, mid_node, unlit)
		return
	var flora := ENV + "sh_flora.png"
	var hangs := [Rect2(8, 112, 16, 16), Rect2(48, 112, 16, 32), Rect2(88, 112, 24, 64),
		Rect2(144, 112, 16, 16), Rect2(184, 112, 16, 32), Rect2(224, 112, 20, 64)]
	var mid_pieces := [Rect2(16, 208, 48, 24), Rect2(8, 16, 32, 24), Rect2(8, 72, 32, 20), Rect2(112, 208, 48, 24)]
	var mid_tint := Color(0.62, 0.58, 0.72) if not surface else Color(0.52, 0.56, 0.62)
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			var c := Vector2i(x, y)
			if is_solid.call(c) or skipped.call(c):
				continue
			# A ceiling over this cell: roots or ivy, by chance, sized to the room below.
			if is_solid.call(c + Vector2i.UP) and room.has_point(c + Vector2i.UP) and _cellhash(c, 1) < 260:
				var open := 0
				while open < 10 and not is_solid.call(c + Vector2i(0, open + 1)):
					open += 1
				var kinds := []
				if open >= 9:
					kinds = [1, 2, 4, 5]
				elif open >= 6:
					kinds = [0, 1, 3, 4]
				elif open >= 4:
					kinds = [0, 3]
				if not kinds.is_empty():
					var kind: int = kinds[_cellhash(c, 2) % kinds.size()]
					var sp := _sprite(hang_node, flora, hangs[kind], Vector2(x * TILE + (_cellhash(c, 3) % 8), y * TILE - 2))
					sp.name = "Hang"
			# A floor under this cell.
			if is_solid.call(c + Vector2i.DOWN) and room.has_point(c + Vector2i.DOWN):
				var floor_y := float((y + 1) * TILE)
				# Its end over open air: ivy hangs over the corner, under the slab.
				for side in [-1, 1]:
					var n := c + Vector2i(side, 0)
					if not is_solid.call(n) and not is_solid.call(n + Vector2i.DOWN) and _cellhash(c, 4) < 600:
						var under := c + Vector2i(0, 1)
						var depth := 0
						while depth < 8 and is_solid.call(under + Vector2i(0, depth)):
							depth += 1
						if depth < 8:
							var ivy := _sprite(hang_node, flora, hangs[[0, 1, 3][_cellhash(c, 5) % 3]],
								Vector2(x * TILE + (2 if side < 0 else 6), (y + 1 + depth) * TILE - 2))
							ivy.name = "CornerIvy"
				# In front of the floor: the mid step, by chance.
				if _cellhash(c, 6) < 90:
					var reg: Rect2 = mid_pieces[_cellhash(c, 7) % mid_pieces.size()]
					var m := _sprite(mid_node, flora, reg, Vector2(x * TILE - reg.size.x * 0.25, floor_y - reg.size.y * 1.25 + 7))
					m.name = "FloorMid"
					m.scale = Vector2(1.25, 1.25)
					m.modulate = mid_tint
					m.material = unlit
				# (The near step at floor level waits for art made for it, FD2 in Book 1:
				# the kit's grass, blown up in black, read as spiky blobs.)


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
	if _detail_kind != "":
		_room_detail(_detail_kind == "surface")
	if _mood:
		_moody()
	if _rim:
		_rim_light()
		_warm_glow()
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


func _fog(parent: Node, rect: Rect2, tint: Color, density: float, drift: Vector2) -> ColorRect:
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
	return r


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


## A lantern on a chain from the ceiling: `x` its centre, `ceiling_y` the ceiling line (px).
func _hanging_lantern(parent: Node, x: float, ceiling_y: float) -> void:
	_sprite(parent, ENV + "props_lanterns.png", Rect2(201, 1, 21, 60), Vector2(x - 10, ceiling_y - 2)).name = "HangingLantern"
	_light(parent, Vector2(x, ceiling_y + 46), Color(1.0, 0.72, 0.4), 1.0, 1.0, "LanternLight")


## A lantern on an iron bracket from a wall: `wall_x` the wall's face (px),
## `y` the bracket's top; `faces` the side the room is on (1: right of the wall).
func _bracket_lantern(parent: Node, wall_x: float, y: float, faces: int) -> void:
	var sp := _sprite(parent, ENV + "props_lanterns.png", Rect2(110, 4, 42, 56), Vector2(wall_x if faces > 0 else wall_x - 42, y))
	sp.name = "BracketLantern"
	sp.flip_h = faces < 0
	_light(parent, Vector2(wall_x + faces * 31, y + 42), Color(1.0, 0.72, 0.4), 0.95, 0.9, "LanternLight")


## Ivy or roots hanging under a ledge or a ceiling: kind 0-2 ivy (short to
## long), 3-5 roots (short to long); `x` its left edge, `y` where it hangs from.
func _hang(parent: Node, kind: int, x: float, y: float) -> void:
	var regions := [Rect2(8, 112, 16, 16), Rect2(48, 112, 16, 32), Rect2(88, 112, 24, 64),
		Rect2(144, 112, 16, 16), Rect2(184, 112, 16, 32), Rect2(224, 112, 20, 64)]
	_sprite(parent, ENV + "sh_flora.png", regions[kind], Vector2(x, y - 2)).name = "Hanging"


## SH4's painted platforms (the creative lead's Shrine Hall kit), each over
## one row of collision in the plan (a mass one tile tall, also in SKIP so the
## skin leaves it to the painting): [region, walking line row, line x0, line x1].
const SH4_PLATE_A := [Rect2(144, 24, 32, 32), 7, 5, 27]
const SH4_PLATE_B := [Rect2(208, 24, 32, 32), 7, 4, 30]
const SH4_PLATE_C := [Rect2(272, 24, 32, 32), 5, 2, 30]
const SH4_BROKEN_LEDGE := [Rect2(208, 128, 32, 32), 3, 0, 31]
const SH4_WALL_LEDGE := [Rect2(104, 120, 64, 56), 16, 0, 63]  # its wall on the left; flip for a wall on the right
const SH4_ARCH_ISLAND := [Rect2(8, 8, 96, 88), 50, 0, 95]


## One of SH4's pieces on its mass [tile_x, row, tiles]: its walking line on the
## mass's top, centred over it.
func _platform(parent: Node, spec: Array, tile_x: int, row: int, tiles: int, flip := false) -> Sprite2D:
	var region: Rect2 = spec[0]
	var x0: int = spec[2]
	var x1: int = spec[3]
	if flip:
		var w := int(region.size.x) - 1
		var t := x0
		x0 = w - x1
		x1 = w - t
	var x: float = tile_x * TILE + (tiles * TILE - float(x1 - x0 + 1)) * 0.5 - x0
	var sp := _sprite(parent, ENV + "sh_platforms.png", region, Vector2(x, row * TILE - int(spec[1])))
	sp.name = "Platform"
	sp.flip_h = flip
	return sp


## A wall torch (SH6) with its light, its top left at `x`, `y` (px).
func _sh_torch(parent: Node, x: float, y: float) -> void:
	_sprite(parent, ENV + "sh_doorways.png", Rect2(48, 160, 16, 32), Vector2(x, y)).name = "Torch"
	_light(parent, Vector2(x + 8, y + 6), Color(1.0, 0.7, 0.38), 1.0, 0.8, "TorchLight")


## A lit doorway (SH6) standing on `floor_y`, left edge `x`, a torch beside it.
func _sh_doorway(parent: Node, x: float, floor_y: float, flip: bool, ruined := false) -> void:
	var sp := _ground(parent, ENV + "sh_doorways.png", Rect2(144 if ruined else 16, 16, 80, 96), x, floor_y + 1.0, 1.0, "Doorway")
	sp.flip_h = flip
	_light(parent, Vector2(x + 40, floor_y - 40), Color(0.55, 0.7, 1.0), 0.6, 0.9, "DoorwayGlow")
	_sh_torch(parent, x + (-14.0 if flip else 82.0), floor_y - 56)


## A piece of SH art (the arcades sheet, the flora sheet) standing on `floor_y`.
func _sh_piece(parent: Node, sheet: String, region: Rect2, x: float, floor_y: float, piece_name: String, flip := false) -> Sprite2D:
	var sp := _ground(parent, ENV + "sh_" + sheet + ".png", region, x, floor_y + 1.0, 1.0, piece_name)
	sp.flip_h = flip
	return sp


## Dust drifting in a tall space, lit by nothing: the air moves.
func _dust(node_name: String, box: Rect2, amount: int) -> void:
	var dust := _particles(node_name, load("res://assets/fx/mote.png"), amount, 9.0, box)
	dust.color = Color(0.8, 0.9, 1.0, 0.6)
	dust.gravity = Vector2(0, 3)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 6.0
	dust.spread = 180.0
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.0
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	dust.material = add
	dust.z_index = 14


## A bead (or a few) of Resin hanging at `pos` (px). `flag` keeps it taken.
func _pickup(parent: Node, pos: Vector2, value: int, flag: String) -> Area2D:
	var p := _node(Area2D.new(), "Resin", parent) as Area2D
	p.set_script(load("res://scripts/world/pickup.gd"))
	p.position = pos.round()
	p.z_index = 15
	p.set("value", value)
	p.set("flag", flag)
	var cs := CollisionShape2D.new()
	var cc := CircleShape2D.new()
	cc.radius = 6.0
	cs.shape = cc
	_node(cs, "Shape", p)
	var art := _node(Sprite2D.new(), "Art", p) as Sprite2D
	art.texture = load("res://assets/items/resin.png")
	art.hframes = 6
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.material = CanvasItemMaterial.new()
	(art.material as CanvasItemMaterial).light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return p


## A little hoard of Resin in a row along a floor (`floor_y` px), from `x0` to `x1`.
func _resin_cache(parent: Node, x0: float, x1: float, floor_y: float, count: int, flag: String) -> void:
	for i in count:
		var t := 0.5 if count == 1 else float(i) / float(count - 1)
		_pickup(parent, Vector2(lerpf(x0, x1, t), floor_y - 10.0 - (i % 2) * 6.0), 1, "%s_%d" % [flag, i])


## A false wall: from the room it is unbroken wall. Over the hidden space
## `hide` (tiles) it draws the room's own terrain as if that space were solid
## rock, so the wall's face at tile column `face_x` runs on across the opening
## (rows `rows`: from, count) and its bands and dark run on round it.
## `faces` is the side the wall faces (1: the open room is to the right of the
## face). No collision: Kleo walks through, and once she is inside it fades for
## good (`flag`). Give it a tell: moss over it, a draught (`_draught`).
func _false_wall(node_name: String, hide: Rect2i, face_x: int, rows: Vector2i, faces: int, flag: String) -> Node2D:
	var cover := _node(Node2D.new(), node_name, _root) as Node2D
	cover.set_script(load("res://scripts/world/secret_cover.gd"))
	cover.set("flag", flag)
	cover.z_index = 22
	# The wall as it would be if the hidden room were solid rock: a copy of the
	# rock layer with the room filled in (no collision, never shown itself),
	# painted by a second skin and clipped to the wall around the room. Inside
	# the clip it is the room's own terrain: the lit bands run on across, the
	# inside fades to the void, and nothing shows.
	var src := _root.get_node("Solid") as TileMapLayer
	var fake := _node(TileMapLayer.new(), "FakeRock", cover) as TileMapLayer
	fake.tile_set = src.tile_set
	fake.collision_enabled = false
	fake.visible = false
	for c in src.get_used_cells():
		fake.set_cell(c, 0, src.get_cell_atlas_coords(c))
	var mat_col := src.get_cell_atlas_coords(Vector2i(face_x - faces, rows.x))
	if mat_col == Vector2i(-1, -1):
		mat_col = Vector2i(1, 0)
	for x in range(hide.position.x, hide.end.x):
		for y in range(hide.position.y, hide.end.y):
			fake.set_cell(Vector2i(x, y), 0, mat_col)
	# The clip: the hidden room and 3 tiles of wall round it, up to the face.
	var m := 3
	var x0 := (hide.position.x - m) * TILE
	var x1 := (hide.end.x + m) * TILE
	if faces > 0:
		x1 = face_x * TILE
	else:
		x0 = face_x * TILE
	var clip := _node(Polygon2D.new(), "Clip", cover) as Polygon2D
	var y0 := (hide.position.y - m) * TILE
	var y1 := (hide.end.y + m) * TILE
	clip.polygon = PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	var skin := _node(Node2D.new(), "FakeSkin", clip)
	skin.set_script(load("res://scripts/world/terrain_skin.gd"))
	var area := Rect2i(hide.position - Vector2i(m + 3, m + 3), hide.size + Vector2i(2 * (m + 3), 2 * (m + 3))).intersection(room)
	skin.set("room_rect", area)
	skin.set("materials", Array([_earth, _stone], TYPE_OBJECT, &"Resource", load("res://scripts/world/terrain_material.gd")))
	skin.set("skip_regions", _rects(skip))
	skin.set("solid_layer", fake)
	skin.set("mass_layer", _root.get_node("Masses"))
	if _cy_stone:
		skin.modulate = CY_GRADE
	_secret_rects.append(hide)
	var trig := _node(Area2D.new(), "Trigger", cover) as Area2D
	var tc := CollisionShape2D.new()
	var tr := RectangleShape2D.new()
	tr.size = Vector2(hide.size * TILE)
	tc.shape = tr
	tc.position = Vector2(hide.position * TILE) + tr.size * 0.5
	_node(tc, "Shape", trig)
	return cover


## A secret's tell: a few motes drifting into the wall where the air moves.
func _draught(node_name: String, box: Rect2, dir: Vector2) -> CPUParticles2D:
	var p := _particles(node_name, load("res://assets/fx/mote.png"), 6, 2.6, box)
	p.direction = dir
	p.spread = 12.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 15.0
	p.color = Color(0.85, 0.95, 0.8, 0.8)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 0.5
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = add
	p.z_index = 21
	return p


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


# --- The moody look -------------------------------------------------------------------------

const MOOD_MURK := Color(0.36, 0.46, 0.52)         # the CanvasModulate: low key, teal
const MOOD_HAZE := Color(0.04, 0.11, 0.13, 0.24)   # washes the backdrops into the murk
const MOOD_FOG := Color(0.32, 0.48, 0.52)          # the fog's own colour
const MOOD_FAR := Color(0.7, 0.88, 0.9)            # the backdrops, greyed toward teal


## After the creative lead's moody references (docs/mockups/mood/): the room
## sinks into a teal murk, a haze lies over its backdrops, ground fog runs along
## every floor (behind Kleo and, thinner, in front of her feet), a low bank fills
## the drops, a bank lies along the bottom of the view, the warm lights carry
## the scene and the cold ones fall back, and the vignette deepens.
func _moody() -> void:
	var dark := _root.get_node_or_null("Darkness") as CanvasModulate
	if dark:
		dark.color = MOOD_MURK
	for c in _root.get_children():
		if c is Parallax2D and (c as Parallax2D).z_index < 0:
			(c as Parallax2D).modulate = MOOD_FAR
	var rect := Rect2(room.position * TILE, room.size * TILE)
	var haze := _node(ColorRect.new(), "MoodHaze", _root) as ColorRect
	haze.color = MOOD_HAZE
	haze.position = rect.position - Vector2(400, 400)
	haze.size = rect.size + Vector2(800, 800)
	haze.z_index = -9
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mood_poly := _root.get_node_or_null("Mood")
	if mood_poly:
		_root.move_child(haze, mood_poly.get_index() + 1)
	var low := _mood_fog(_root, "DeepFog", Rect2(rect.position.x, rect.position.y + rect.size.y * 0.45, rect.size.x, rect.size.y * 0.6), 0.28, 1)
	low.material.set_shader_parameter("scale", Vector2(rect.size.x / 800.0, rect.size.y / 140.0))
	low.material.set_shader_parameter("side_fade", 0.08)
	_mood_floor_fog()
	var fg := _root.get_node_or_null("Foreground") as Parallax2D
	if fg:
		var w := rect.size.x * 1.3 + 800.0
		var bank := _mood_fog(fg, "ScreenFog", Rect2(-400, 250, w, 120), 0.45, 0)
		bank.material.set_shader_parameter("scale", Vector2(w / 600.0, 0.6))
	for l in _root.find_children("*", "PointLight2D", true, false):
		var pl := l as PointLight2D
		if pl.color.r > pl.color.b:
			pl.energy *= 1.9
			pl.texture_scale *= 1.15
		else:
			pl.energy *= 0.5
	var vig := _root.get_node_or_null("Screen/Vignette") as ColorRect
	if vig and vig.material:
		var vm := (vig.material as ShaderMaterial).duplicate() as ShaderMaterial
		vm.set_shader_parameter("strength", 0.74)
		vm.set_shader_parameter("inner", 0.32)
		vm.set_shader_parameter("shadow", Color(0.01, 0.03, 0.04))
		vig.material = vm


## Ground fog along every floor run of four tiles or more.
func _mood_floor_fog() -> void:
	var cells := {}
	for layer_name in ["Solid", "Masses"]:
		var tm := _root.get_node_or_null(layer_name) as TileMapLayer
		if tm:
			for c in tm.get_used_cells():
				cells[c] = true
	var rows := {}
	for c in cells:
		if not cells.has(c + Vector2i(0, -1)) and not cells.has(c + Vector2i(0, -2)):
			if not rows.has(c.y):
				rows[c.y] = []
			rows[c.y].append(c.x)
	var n := 0
	var keys := rows.keys()
	keys.sort()
	for y in keys:
		var xs: Array = rows[y]
		xs.sort()
		var start: int = xs[0]
		var prev: int = xs[0]
		for i in range(1, xs.size() + 1):
			if i < xs.size() and xs[i] == prev + 1:
				prev = xs[i]
				continue
			if prev - start + 1 >= 4:
				var fy := float(y * TILE)
				var x0 := float(start * TILE) - 24.0
				var w := float((prev - start + 1) * TILE) + 48.0
				var back := _mood_fog(_root, "FloorFog%d" % n, Rect2(x0, fy - 3.4 * TILE, w, 3.8 * TILE), 0.4, 3)
				back.material.set_shader_parameter("side_fade", 0.12)
				var front := _mood_fog(_root, "FloorFogFront%d" % n, Rect2(x0, fy - 1.4 * TILE, w, 2.0 * TILE), 0.22, 12)
				front.material.set_shader_parameter("side_fade", 0.15)
				front.material.set_shader_parameter("drift", Vector2(-0.008, 0.0))
				n += 1
			if i < xs.size():
				start = xs[i]
				prev = xs[i]


func _mood_fog(parent: Node, fog_name: String, rect: Rect2, density: float, z: int) -> ColorRect:
	var r := _fog(parent, rect, MOOD_FOG, density, Vector2(0.005, 0.0))
	r.name = fog_name
	r.z_index = z
	r.material.set_shader_parameter("scale", Vector2(rect.size.x / 640.0, rect.size.y / 90.0))
	return r


# --- The detail pass in the CH pieces ---------------------------------------------------------

const CH_PIECES := ENV + "ch_pieces.json"
## CH4 (ch_hangings.png): moss curtains, roots and chains by length; the stone
## drips for low ceilings. Indices into ch_pieces.json's "ch_hangings".
const CH_HANG_LONG := [0, 2, 6, 7, 8, 10, 11]
const CH_HANG_MID := [1, 3, 4, 9, 17]
const CH_HANG_SHORT := [5, 13, 14, 15, 16]
## CH5 (ch_props.png): crystals, tufts and rubble standing on floors.
const CH_TOPS := [0, 1, 2, 3, 4, 5, 6, 7, 9, 11, 13, 14, 15, 16]
## CH8 (ch_foreground.png): mounds, drums, grass for the mid step; thin root
## arches and grass in black for the near step.
const CH_FLOOR_MID := [0, 1, 2, 3, 4, 5, 9, 11, 12, 16]
## Only the thin root arches: grass and ferns in black read as blobs.
const CH_FLOOR_NEAR := [6, 7, 8]
const CH_NEAR_TINT := Color(0.04, 0.03, 0.06)


func _ch_room_detail(is_solid: Callable, skipped: Callable, hang_node: Node2D, mid_node: Node2D, unlit: Material) -> void:
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CH_PIECES))
	var rect_of := func(sheet: String, i: int) -> Rect2:
		var r: Array = table[sheet][i]["rect"]
		return Rect2(r[0], r[1], r[2], r[3])
	var tops_node := _node(Node2D.new(), "Tops", _root) as Node2D
	tops_node.z_index = 3
	var near_node := _node(Node2D.new(), "FloorNear", _root) as Node2D
	near_node.z_index = 27
	var mid_tint := Color(0.5, 0.48, 0.6)
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			var c := Vector2i(x, y)
			if is_solid.call(c) or skipped.call(c):
				continue
			# Under a ceiling: a hanging that leaves her room to pass (about 40 px).
			if is_solid.call(c + Vector2i.UP) and room.has_point(c + Vector2i.UP) and _cellhash(c, 1) < 300:
				var open := 0
				while open < 12 and not is_solid.call(c + Vector2i(0, open + 1)):
					open += 1
				var room_px := (open + 1) * TILE - 40
				var pool: Array = CH_HANG_LONG + CH_HANG_MID if open >= 8 else (CH_HANG_MID + CH_HANG_SHORT if open >= 5 else CH_HANG_SHORT)
				var pick: int = pool[_cellhash(c, 2) % pool.size()]
				var reg: Rect2 = rect_of.call("ch_hangings", pick)
				if reg.size.y <= room_px:
					var sp := _sprite(hang_node, ENV + "ch_hangings.png", reg, Vector2(x * TILE + (_cellhash(c, 3) % 8) - reg.size.x * 0.5 + 8, y * TILE - 3))
					sp.name = "Hang"
			if not (is_solid.call(c + Vector2i.DOWN) and room.has_point(c + Vector2i.DOWN)):
				continue
			var floor_y := float((y + 1) * TILE)
			# Its end over open air: moss over the corner, under the slab.
			for side in [-1, 1]:
				var n := c + Vector2i(side, 0)
				if not is_solid.call(n) and not is_solid.call(n + Vector2i.DOWN) and _cellhash(c, 4) < 600:
					var depth := 0
					while depth < 8 and is_solid.call(c + Vector2i(0, 1 + depth)):
						depth += 1
					if depth < 8:
						var reg2: Rect2 = rect_of.call("ch_hangings", [5, 3, 1][_cellhash(c, 5) % 3])
						var ivy := _sprite(hang_node, ENV + "ch_hangings.png", reg2,
							Vector2(x * TILE + (0 if side < 0 else 16 - reg2.size.x), (y + 1 + depth) * TILE - 3))
						ivy.name = "CornerMoss"
			# On the floor: crystals, tufts, rubble, behind her.
			if _cellhash(c, 8) < 140:
				var reg3: Rect2 = rect_of.call("ch_props", CH_TOPS[_cellhash(c, 9) % CH_TOPS.size()])
				var top := _sprite(tops_node, ENV + "ch_props.png", reg3, Vector2(x * TILE + 8 - reg3.size.x * 0.5, floor_y - reg3.size.y + 1))
				top.name = "Top"
				top.flip_h = _cellhash(c, 10) % 2 == 0
			# In front of the floor, the mid step: darkened mounds, drums, grass.
			if _cellhash(c, 6) < 45:
				var reg4: Rect2 = rect_of.call("ch_foreground", CH_FLOOR_MID[_cellhash(c, 7) % CH_FLOOR_MID.size()])
				var m := _sprite(mid_node, ENV + "ch_foreground.png", reg4, Vector2(x * TILE + 8 - reg4.size.x * 0.5, floor_y - reg4.size.y * 0.55))
				m.name = "FloorMid"
				m.modulate = mid_tint
				m.material = unlit
				m.flip_h = _cellhash(c, 11) % 2 == 0
			# Nearest the camera: thin root arches in black, sparse, low, and only on
			# the room's lower floors (in a gallery they stood in the way).
			elif _cellhash(c, 12) < 30 and y >= room.position.y + room.size.y * 0.6:
				var reg5: Rect2 = rect_of.call("ch_foreground", CH_FLOOR_NEAR[_cellhash(c, 13) % CH_FLOOR_NEAR.size()])
				var nr := _sprite(near_node, ENV + "ch_foreground.png", reg5, Vector2(x * TILE + 8 - reg5.size.x * 0.5, floor_y - reg5.size.y * 0.35))
				nr.name = "FloorNear"
				nr.modulate = CH_NEAR_TINT
				nr.material = unlit
				nr.flip_h = _cellhash(c, 14) % 2 == 0


# --- Rim light along the walking edges --------------------------------------------------------

const RIM_BASE := Color(1.0, 0.72, 0.42)   # the faint warm line on every top
const RIM_LIT := Color(1.0, 0.84, 0.58)    # brighter where a light reaches


## Along every walking edge (a solid cell with open air over it, runs of two
## tiles or more): a faint warm line, 3 px deep and fading down, added over the
## stone; and a brighter one drawn only where lights reach it, so the rims glow
## near the torches and braziers, as the mockup's do.
func _rim_light() -> void:
	var cells := {}
	for layer_name in ["Solid", "Masses"]:
		var tm := _root.get_node_or_null(layer_name) as TileMapLayer
		if tm:
			for c in tm.get_used_cells():
				cells[c] = true
	var rows := {}
	for c in cells:
		if not cells.has(c + Vector2i(0, -1)) and room.has_point(c + Vector2i(0, -1)):
			if not rows.has(c.y):
				rows[c.y] = []
			rows[c.y].append(c.x)
	var node := _node(Node2D.new(), "RimLight", _root) as Node2D
	node.z_index = 6
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var lit := CanvasItemMaterial.new()
	lit.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	lit.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
	var keys := rows.keys()
	keys.sort()
	for y in keys:
		var xs: Array = rows[y]
		xs.sort()
		var start: int = xs[0]
		var prev: int = xs[0]
		for i in range(1, xs.size() + 1):
			if i < xs.size() and xs[i] == prev + 1:
				prev = xs[i]
				continue
			if prev - start + 1 >= 2:
				var x0 := float(start * TILE)
				var w := float((prev - start + 1) * TILE)
				for k in 3:
					var base := _node(ColorRect.new(), "Rim", node) as ColorRect
					base.position = Vector2(x0, y * TILE + k)
					base.size = Vector2(w, 1)
					base.color = Color(RIM_BASE.r, RIM_BASE.g, RIM_BASE.b, [0.16, 0.08, 0.03][k])
					base.material = add
					base.mouse_filter = Control.MOUSE_FILTER_IGNORE
					var glow := _node(ColorRect.new(), "RimLit", node) as ColorRect
					glow.position = Vector2(x0, y * TILE + k)
					glow.size = Vector2(w, 1)
					glow.color = Color(RIM_LIT.r, RIM_LIT.g, RIM_LIT.b, [0.75, 0.4, 0.15][k])
					glow.material = lit
					glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if i < xs.size():
				start = xs[i]
				prev = xs[i]


# --- Warm glow round the flames --------------------------------------------------------------

const GLOW_LIGHT := Color(1.0, 0.6, 0.27)   # the flames' light, toward amber
const GLOW_HALO := Color(0.95, 0.55, 0.22)  # the halo in the air round a flame


## The mockup's warm glow (the creative lead: "a warmer glow to the lights"):
## every warm light turns toward amber, and gets a halo in the air round it, a
## soft additive disc in four stepped rings (pixel art, not a smooth blur),
## sized to the light. Glows stay off the tiles: the halo is its own sprite.
func _warm_glow() -> void:
	var tex := _halo_texture()
	var node := _node(Node2D.new(), "WarmGlow", _root) as Node2D
	node.z_index = 7
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for l in _root.find_children("*", "PointLight2D", true, false):
		var pl := l as PointLight2D
		if pl.color.r <= pl.color.b:
			continue
		pl.color = GLOW_LIGHT
		var halo := _node(Sprite2D.new(), "Halo", node) as Sprite2D
		halo.texture = tex
		halo.global_position = pl.global_position
		var size := clampf(pl.texture_scale * 70.0, 28.0, 96.0)
		halo.scale = Vector2.ONE * (size / 64.0)
		halo.modulate = Color(GLOW_HALO.r, GLOW_HALO.g, GLOW_HALO.b, 0.55)
		halo.material = add


func _halo_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.22, 0.45, 0.7, 0.95])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.32), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t
