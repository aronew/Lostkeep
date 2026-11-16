extends "res://tools/room_builder.gd"
## Shared tools for the Ironbark surface rooms (IB-03, IB-04), on top of
## room_builder.gd: the look the creative lead chose (IB-01's purple sky, moons
## and teal forest; plum boulder terrain; big floating islands, after their
## "Moonlit" mockups in docs/mockups/ironbark_surface/), and the surface's
## placed collision: stairs, one-way logs.

const GT := ENV + "surface_great_tree.png"
const CH := ENV + "surface_chapel_terraces.png"
const PL := ENV + "surface_pool_bridge.png"
const IS := ENV + "surface_ruin_islands.png"
const LAN := ENV + "props_lanterns.png"
const GRAVE := ENV + "props_graveyard.png"
const FLORA := ENV + "props_flora.png"
const TIMBER := ENV + "keep_timber_kit.png"
const LAMP := Color(1.0, 0.72, 0.4)

# The creative lead's Ironbark islands and cliff pieces (art/source/ironbark/islands),
# in the palette they prefer. Islands: [texture, grass line row, grass x0, grass x1].
const CLIFFS := ENV + "cliffs_and_ruins.png"
const ISLANDS := {
	"graveyard": ["island_graveyard.png", 95, 3, 443],
	"root_held": ["island_root_held.png", 89, 4, 268],
	"tree": ["island_tree.png", 150, 2, 316],
	"shrine": ["island_shrine.png", 62, 1, 189],
	"ruin": ["island_ruin.png", 57, 2, 156],
	"chunk_headstone": ["island_chunk_headstone.png", 21, 1, 94],
	"chunk_bush": ["island_chunk_bush.png", 11, 3, 61],
}
const DOOR_LANTERN := Rect2(8, 160, 112, 72)   # arch door with its lantern at (99, 42)
const DOOR_RUINED := Rect2(152, 160, 112, 72)
const CRYSTAL_SHRINE := Rect2(8, 248, 96, 64)
const TIMBER_GATE := Rect2(144, 248, 80, 64)
const POST := Rect2(256, 248, 40, 64)          # lantern post, its lamp at (31, 28)
const FG_LEFT := Rect2(8, 328, 128, 48)
const FG_RIGHT := Rect2(232, 328, 144, 48)

## The surface set pieces (SF9 to SF12) were painted bluer and yellower than the
## Ironbark kit; they are tinted toward its plum.
const SF_TINT := Color(0.98, 0.85, 1.1)
const MID_BASE := Color("#24535b")

# Pieces of the kit, by what they are.
const GRAVE_CROSS := Rect2(17, 2, 50, 45)
const GRAVE_BROKEN := Rect2(73, 14, 37, 33)
const GRAVE_CREST := Rect2(116, 11, 43, 36)
const GRAVE_CELTIC := Rect2(165, 2, 35, 45)
const FENCE := Rect2(7, 88, 110, 36)
const FENCE_POST := Rect2(125, 85, 22, 39)
const TRACERY := Rect2(8, 160, 90, 87)      # SF12: tracery ruin with a lantern at (82, 41)
const SMALL_ARCH := Rect2(144, 184, 64, 62) # SF12
const ARCADE := Rect2(248, 186, 128, 61)    # SF12
const CHAPEL := Rect2(12, 0, 96, 92)        # SF10
const VINES := [Rect2(198, 126, 16, 71), Rect2(171, 126, 15, 51), Rect2(227, 126, 14, 88)]
const TUFTS := [Rect2(91, 24, 49, 24), Rect2(22, 101, 32, 17), Rect2(215, 22, 32, 26), Rect2(126, 93, 42, 27)]

var _unlit: CanvasItemMaterial
var _add_mat: CanvasItemMaterial


func _surface_begin(node_name: String) -> Dictionary:
	_unlit = CanvasItemMaterial.new()
	_unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_add_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var tileset := _shared()
	_begin(node_name)
	_build_backdrops()
	_back_walls()
	return _terrain(tileset)


func _surface_finish() -> void:
	_build_atmosphere()
	_build_foreground()
	_tint_surface_kit(_root)
	_edge_shades()


## The Ironbark backdrops, as in IB-01: the purple dusk sky and its moons, the
## far forest and the nearer trees.
func _build_backdrops() -> void:
	var sky := _parallax("Sky", Vector2(0.05, 0.0), PARALLAX + "sky.png", -96.0, Color("#3b6d70"))
	sky.get_node("Art").modulate = Color(0.78, 0.76, 0.86)
	_parallax("Far", Vector2(0.15, 0.08), PARALLAX + "far.png", 92.0, Color("#3d7070"))
	var fog_far := _node(Parallax2D.new(), "FogFar", _root) as Parallax2D
	fog_far.scroll_scale = Vector2(0.25, 0.12)
	fog_far.z_index = -10
	_fog(fog_far, Rect2(-200, 210, 2600, 150), Color("#6f9a9a"), 0.32, Vector2(0.004, 0.0))
	_parallax("Mid", Vector2(0.35, 0.22), PARALLAX + "mid.png", 52.0, MID_BASE)
	var fog_mid := _node(Parallax2D.new(), "FogMid", _root) as Parallax2D
	fog_mid.scroll_scale = Vector2(0.5, 0.35)
	fog_mid.z_index = -10
	_fog(fog_mid, Rect2(-200, 260, 2800, 160), Color("#5f8a8c"), 0.26, Vector2(0.007, 0.0))


func _tint_surface_kit(node: Node) -> void:
	for c in node.get_children():
		if c is Sprite2D and c.texture and c.texture.resource_path.contains("/surface_"):
			c.modulate = c.modulate * SF_TINT
		_tint_surface_kit(c)


func _build_atmosphere() -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.64, 0.63, 0.78)
	var w := float(room.size.x * TILE)
	var h := float(room.size.y * TILE)
	# Moonlight falling through the canopy.
	var x := 300.0
	while x < w:
		var shaft := _node(Polygon2D.new(), "LightShaft", _root) as Polygon2D
		shaft.z_index = 3
		var sw := 60.0 + fmod(x, 37.0)
		shaft.polygon = PackedVector2Array([Vector2(x, 0), Vector2(x + sw, 0), Vector2(x + sw + 170, h - 60), Vector2(x + 170, h - 60)])
		shaft.vertex_colors = PackedColorArray([Color(1, 0.93, 0.7, 0.12), Color(1, 0.93, 0.7, 0.12), Color(1, 0.93, 0.7, 0.0), Color(1, 0.93, 0.7, 0.0)])
		shaft.material = _add_mat
		x += 520.0
	var flies := _particles("Fireflies", load("res://assets/fx/mote.png"), 40, 7.0, Rect2(0, h * 0.3, w, h * 0.6))
	flies.color = Color(1.0, 0.82, 0.45)
	flies.gravity = Vector2(0, -2)
	flies.initial_velocity_min = 3.0
	flies.initial_velocity_max = 9.0
	flies.spread = 180.0
	flies.scale_amount_min = 0.5
	flies.scale_amount_max = 1.0
	flies.material = _add_mat
	flies.z_index = 14
	var leaves := _particles("Leaves", load("res://assets/fx/leaf.png"), 16, 12.0, Rect2(0, 0, w, 60))
	leaves.gravity = Vector2(5, 16)
	leaves.initial_velocity_min = 4.0
	leaves.initial_velocity_max = 12.0
	leaves.angular_velocity_min = -90.0
	leaves.angular_velocity_max = 90.0
	leaves.z_index = 14


## The foreground in two value steps (the creative lead: "2 layers of
## foreground, one not all the way silhouetted and one full silhouette").
## Both frame the screen (scroll y 0): they slide sideways faster than the
## room but hold their height on screen, so they are there on every floor.
## The mid step: P5's canopy along the top and ferns along the bottom, dark and
## tinted toward the night, their leaves still showing. The near step: sparse
## pure silhouettes in thin shapes (a branch, vines, tall grass), scrolling
## fastest; never big blobs, which read as holes.
## The fog between the surface foreground bands: moonlit violet-teal.
const SURFACE_FG_FOG := Color(0.4, 0.42, 0.6)


func _build_foreground() -> void:
	_detail_kind = "surface"
	# The foreground is FG9 and FG10, the continuous undergrowth and canopy
	# bands, at three depths with fog between (`_fg_bands` in room_builder.gd).
	# They replace P5's canopy and ferns and the blown-up black branch, vines
	# and grass, which held their height on screen (the creative lead: the
	# foreground looked "weirdly attached"; "these little pieces ... look bad").
	var p := _node(Parallax2D.new(), "Foreground", _root) as Parallax2D
	p.scroll_scale = Vector2(1.2, 0.0)
	p.z_index = 30
	_fg_bands("forest", SURFACE_FG_FOG)
	# Ruin silhouettes in the room's bottom corners, nearest the camera.
	var front := _root.get_node("Front")
	var h := float(room.size.y * TILE)
	var w := float(room.size.x * TILE)
	for c in [[FG_LEFT, 0.0], [FG_RIGHT, w - FG_RIGHT.size.x]]:
		var sil := _sprite(front, CLIFFS, c[0], Vector2(c[1], h - c[0].size.y))
		sil.name = "CornerRuin"
		sil.material = _unlit
		sil.z_index = 9


# --- Collision that isn't tiles -------------------------------------------------------------------

func _body(body_name: String, layer: int) -> StaticBody2D:
	var b := _node(StaticBody2D.new(), body_name, _root) as StaticBody2D
	b.collision_layer = layer
	b.collision_mask = 0
	return b


## SF10's flight of steps, whole: six treads rising three tiles to its own mossy
## block, over a slope she runs up. `edge_x` is the upper floor's corner (the
## block stands on it, covering the terrain's corner), `foot_y` the lower
## floor's walking line. `down_east`: the flight descends to the east.
const STAIR := Rect2(208, 76, 128, 64)  # eight treads: the top tread on row 10 from x 76, the foot at x 8
const STAIR_RUN := 68.0

func _flight(parent: Node, edge_x: float, foot_y: float, down_east: bool) -> void:
	var dir := 1.0 if down_east else -1.0
	var foot := Vector2(edge_x + dir * STAIR_RUN, foot_y)
	var head := Vector2(edge_x, foot_y - 48.0)
	var b := _body("Stairs", 1)
	var poly := CollisionPolygon2D.new()
	poly.polygon = PackedVector2Array([foot, head, Vector2(head.x, foot.y + 8.0), Vector2(foot.x, foot.y + 8.0)])
	_node(poly, "Shape", b)
	var x: float = edge_x - (STAIR.size.x - 76.0) if down_east else edge_x - 76.0
	var st := _sprite(parent, CLIFFS, STAIR, Vector2(x, head.y - 10.0))
	st.name = "StairsArt"
	st.flip_h = down_east


## A painted floating island on its collision: the mass [tile_x, row, tiles, 1]
## in the plan (one tile under the grass line; the Masses layer is hidden, so
## only the painting shows). Its grass line lies on the collision's top, centred.
func _island(parent: Node, kind: String, tile_x: int, row: int, tiles: int) -> Sprite2D:
	var spec: Array = ISLANDS[kind]
	var tex: Texture2D = load(ENV + spec[0])
	var grass_w := float(spec[3] - spec[2] + 1)
	var x: float = tile_x * TILE + (tiles * TILE - grass_w) * 0.5 - float(spec[2])
	var s := _sprite(parent, ENV + spec[0], Rect2(0, 0, tex.get_width(), tex.get_height()), Vector2(x, row * TILE - float(spec[1])))
	s.name = "Island_" + kind
	return s


## The room's islands are paintings: hide their collision tiles (the box view
## shows them again).
func _hide_island_tiles() -> void:
	var m := _root.get_node("Masses") as TileMapLayer
	m.visible = false
	m.set_meta("under_art", true)


## A piece from the cliff atlas standing on a floor (x is its left edge).
func _piece(parent: Node, region: Rect2, x: float, floor_y: float, piece_name: String) -> Sprite2D:
	return _ground(parent, CLIFFS, region, x, floor_y + 1.0, 1.0, piece_name)


## An arch door with its lantern, standing at a room's edge.
func _arch_door(parent: Node, x: float, floor_y: float, flip: bool) -> void:
	var d := _piece(parent, DOOR_LANTERN, x, floor_y, "ArchDoor")
	d.flip_h = flip
	var lx: float = (DOOR_LANTERN.size.x - 99.0) if flip else 99.0
	_light(parent, Vector2(x + lx, floor_y - DOOR_LANTERN.size.y + 44), LAMP, 0.95, 0.9, "ArchDoorLight")


## A fallen log between two floors: one-way (she can jump up through it and
## drop down through it), timber from the keep's kit.
func _log(parent: Node, x0: float, x1: float, y: float) -> void:
	var b := _body("Log", 64)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(x1 - x0, 8)
	cs.shape = r
	cs.position = Vector2((x0 + x1) * 0.5, y + 4.0)
	cs.one_way_collision = true
	_node(cs, "Shape", b)
	var x := x0 - 6.0
	while x < x1:
		var piece := _sprite(parent, TIMBER, Rect2(42, 13, minf(96.0, x1 + 6.0 - x), 16), Vector2(x, y - 2))
		piece.name = "LogArt"
		x += 96.0


# --- Dressing -------------------------------------------------------------------------------------

func _lantern_post(parent: Node, x: float, floor_y: float) -> void:
	_piece(parent, POST, x, floor_y, "LanternPost")
	_light(parent, Vector2(x + 31, floor_y - POST.size.y + 30), LAMP, 1.0, 1.0, "LanternPostLight")


func _tracery(parent: Node, x: float, floor_y: float) -> void:
	_ground(parent, IS, TRACERY, x, floor_y + 1, 0.95, "TraceryRuin")
	_light(parent, Vector2(x + 82, floor_y - 87 + 41), LAMP, 0.9, 0.8, "RuinLanternLight")


## Vines hanging under a floating island, along [x0, x1] at its underside.
func _vines(parent: Node, x0: float, x1: float, y: float) -> void:
	var i := 0
	var x := x0
	while x < x1:
		var v := _sprite(parent, FLORA, VINES[i % 3], Vector2(x, y))
		v.name = "Vine"
		v.modulate = Color(0.85, 0.85, 0.9)
		x += 34.0 + 11.0 * (i % 3)
		i += 1


## Props standing along a floor: [[region or texture+region, x], ...].
func _row(parent: Node, tex: String, floor_y: float, items: Array) -> void:
	for it in items:
		_ground(parent, tex, it[0], it[1], floor_y, 0.97, "Prop")


## A Mossback (the gardens' gentle enemy) on a flat floor, walking between two
## x positions (world px). Seven sword hits put it down.
func _mossback(x: float, floor_y: float, left_x: float, right_x: float) -> Node2D:
	var m := _node(Node2D.new(), "Mossback", _root) as Node2D
	m.set_script(load("res://scripts/world/mossback.gd"))
	m.position = Vector2(x, floor_y)
	m.z_index = 7
	m.set("left_x", left_x)
	m.set("right_x", right_x)
	var art := _node(Sprite2D.new(), "Art", m) as Sprite2D
	art.texture = load("res://assets/characters/mossback/mossback.png")
	art.hframes = 6
	art.centered = false
	art.position = Vector2(-16, -22)
	var flash := ShaderMaterial.new()
	flash.shader = load("res://shaders/hit_flash.gdshader")
	art.material = flash
	var hb := _node(Area2D.new(), "Hurtbox", m) as Area2D
	hb.collision_layer = 4
	hb.collision_mask = 0
	hb.monitoring = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(22, 18)
	hs.shape = hr
	hs.position = Vector2(0, -9)
	_node(hs, "Shape", hb)
	var touch := _node(Area2D.new(), "Touch", m) as Area2D
	touch.collision_layer = 0
	touch.collision_mask = 2
	touch.monitorable = false
	var ts := CollisionShape2D.new()
	var tr := RectangleShape2D.new()
	tr.size = Vector2(14, 14)
	ts.shape = tr
	ts.position = Vector2(0, -8)
	_node(ts, "Shape", touch)
	return m


func _glint(parent: Node, pos: Vector2, tint: Color) -> void:
	var g := _sprite(parent, "res://assets/characters/kleo/fx_small.png", Rect2(0, 0, 64, 64), pos)
	g.name = "Glint"
	g.scale = Vector2(0.5, 0.5)
	g.material = _add_mat
	g.modulate = tint
	g.set_script(load("res://scripts/fx/pulse.gd"))
