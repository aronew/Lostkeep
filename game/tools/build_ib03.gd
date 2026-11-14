extends "res://tools/room_builder.gd"
## Builds room IB-03, the Guard Post (the game's opening room), from the plan
## below, with the shared tools in room_builder.gd, and saves it as an ordinary
## scene. Re-running this script overwrites scenes/rooms/ironbark_03_guard_post.tscn.
##
##   godot --headless --path game --script res://tools/build_ib03.gd
##
## Spec and validation: design/rooms/ironbark_03_guard_post.md.
## The room is composed like the creative lead's surface mockups (R, S, T) from
## their set pieces SF9 to SF13: it starts low under the great tree, crosses the
## pool by the broken bridge, climbs the hill by its stairs to the chapel, then
## drops down the hill's far side to the road.
##
## In the world grid this room lies west of IB-01 and 5 tiles higher: its East
## door (rows 24 to 28) is IB-01's west upper exit (rows 19 to 23).

const ROOM_PATH := "res://scenes/rooms/ironbark_03_guard_post.tscn"
const IB01 := "res://scenes/rooms/ironbark_test_room.tscn"

# --- The room plan (tiles) ---------------------------------------------------------
const ROOM := Rect2i(0, 0, 112, 32)
## Rock: [x, y, w, h, material].
const ROCK := [
	[0, 24, 24, 8, 0],     # the start: the ground under the great tree
	[24, 27, 10, 5, 0],    # the pool's west bank
	[34, 31, 16, 1, 0],    # the pool's bed
	[50, 27, 10, 5, 0],    # the pool's east bank, the foot of the hill
	[60, 24, 9, 8, 0],     # the hill's first terrace
	[69, 21, 9, 11, 0],    # the second
	[78, 18, 9, 14, 0],    # the third
	[87, 15, 10, 17, 0],   # the hilltop: the guard's chapel
	[97, 19, 4, 13, 0],    # the far side: two shelves down
	[101, 24, 3, 8, 0],
	[104, 29, 8, 3, 0],    # the road east
]
const SPACES := []
## Floating islands: one tile of collision under painted islands (placed art).
const MASSES := [
	[23, 18, 11, 1, 0],   # the ruin island
	[38, 17, 7, 1, 0],    # the grave island, over the pool
	[49, 18, 15, 1, 0],   # the long island, on to the hill
	[100, 9, 4, 1, 0],    # the far island (Wing-Cloak)
]
const STONE := []
const SKIP := [[23, 18, 11, 1], [38, 17, 7, 1], [49, 18, 15, 1], [100, 9, 4, 1]]
const BACK := []
const BACK_EARTH := []

## The start of the game: under the great tree, by its lantern.
const SPAWN := Vector2(18 * 16, 24 * 16)

const GT := ENV + "surface_great_tree.png"
const CH := ENV + "surface_chapel_terraces.png"
const PL := ENV + "surface_pool_bridge.png"
const IS := ENV + "surface_ruin_islands.png"
const GRAVE := ENV + "props_graveyard.png"
const FLORA := ENV + "props_flora.png"
const LAN := ENV + "props_lanterns.png"
const LAMP := Color(1.0, 0.72, 0.4)

# Walking lines (px).
const G := 384.0      # the start, and the first terrace
const BANK := 432.0
const DECK := 400.0
const T2 := 336.0
const T3 := 288.0
const TOP := 240.0

## The surface set pieces (SF9 to SF12) were painted bluer and yellower than the
## Ironbark kit. They are tinted toward its plum and teal, the palette the
## creative lead prefers (IB-01's: purple sky, plum stone).
const SF_TINT := Color(0.98, 0.85, 1.1)
## The colour under the mid forest layer (as IB-01).
const MID_BASE := Color("#24535b")

var _unlit: CanvasItemMaterial


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
	_unlit = CanvasItemMaterial.new()
	_unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var tileset := _shared()
	_begin("IronbarkGuardPost")
	_build_backdrops()
	_back_walls()
	var t := _terrain(tileset)
	_build_collision()
	_build_tree(t["behind"], t["placed"], t["front"])
	_build_pool(t["behind"], t["placed"])
	_build_hill(t["behind"], t["placed"])
	_build_islands(t["behind"], t["placed"])
	_build_atmosphere()
	_build_foreground()
	_tint_surface_kit(_root)
	_edge_shades()
	_door("East", Rect2i(104, 24, 8, 5), 1, IB01, "WestUpper")
	# West: the forest road. Its room isn't built: a place to arrive, no way through.
	_door("West", Rect2i(0, 19, 6, 5), -1, "", "")
	_finish()
	quit()


# --- Backdrops ---------------------------------------------------------------------------------

## The Ironbark backdrops, as in IB-01: the purple dusk sky and its moons, the
## far forest, and the nearer trees. (No ruined wall layer here: the room's own ruins
## must read against the forest.)
func _build_backdrops() -> void:
	var sky := _parallax("Sky", Vector2(0.05, 0.0), PARALLAX + "sky.png", -96.0, Color("#3b6d70"))
	sky.get_node("Art").modulate = Color(0.78, 0.76, 0.86)
	_parallax("Far", Vector2(0.15, 0.08), PARALLAX + "far.png", 92.0, Color("#3d7070"))
	var fog_far := _node(Parallax2D.new(), "FogFar", _root) as Parallax2D
	fog_far.scroll_scale = Vector2(0.25, 0.12)
	fog_far.z_index = -10
	_fog(fog_far, Rect2(-200, 210, 2400, 150), Color("#6f9a9a"), 0.32, Vector2(0.004, 0.0))
	_parallax("Mid", Vector2(0.35, 0.22), PARALLAX + "mid.png", 52.0, MID_BASE)
	var fog_mid := _node(Parallax2D.new(), "FogMid", _root) as Parallax2D
	fog_mid.scroll_scale = Vector2(0.5, 0.35)
	fog_mid.z_index = -10
	_fog(fog_mid, Rect2(-200, 260, 2600, 160), Color("#5f8a8c"), 0.26, Vector2(0.007, 0.0))


func _tint_surface_kit(node: Node) -> void:
	for c in node.get_children():
		if c is Sprite2D and c.texture and c.texture.resource_path.contains("/surface_"):
			c.modulate = c.modulate * SF_TINT
		_tint_surface_kit(c)


# --- Collision that isn't tiles -------------------------------------------------------------------

func _body(body_name: String, layer: int) -> StaticBody2D:
	var b := _node(StaticBody2D.new(), body_name, _root) as StaticBody2D
	b.collision_layer = layer
	b.collision_mask = 0
	return b


## Stairs: a slope she runs up, under painted steps. From its foot to its head.
func _stairs(stairs_name: String, foot: Vector2, head: Vector2) -> void:
	var b := _body(stairs_name, 1)
	var poly := CollisionPolygon2D.new()
	poly.polygon = PackedVector2Array([foot, head, Vector2(head.x, foot.y + 8.0), Vector2(foot.x, foot.y + 8.0)])
	_node(poly, "Shape", b)


func _slab(slab_name: String, x0: float, x1: float, y: float, one_way: bool) -> void:
	var b := _body(slab_name, 64 if one_way else 1)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(x1 - x0, 8)
	cs.shape = r
	cs.position = Vector2((x0 + x1) * 0.5, y + 4.0)
	cs.one_way_collision = one_way
	_node(cs, "Shape", b)


func _build_collision() -> void:
	# The stairs (painted steps over slopes).
	_stairs("StairsTreeBank", Vector2(440, BANK), Vector2(384, G))
	_stairs("StairsBridgeWest", Vector2(488, BANK), Vector2(544, DECK))
	_stairs("StairsBridgeEast", Vector2(856, BANK), Vector2(800, DECK))
	_stairs("StairsHill1", Vector2(904, BANK), Vector2(960, G))
	_stairs("StairsHill2", Vector2(1048, G), Vector2(1104, T2))
	_stairs("StairsHill3", Vector2(1192, T2), Vector2(1248, T3))
	_stairs("StairsHill4", Vector2(1336, T3), Vector2(1392, TOP))
	# Two mossy blocks by the tree: two tiles up, the way to its branch.
	var ledge := _body("RootLedge", 1)
	var ls := CollisionShape2D.new()
	var lr := RectangleShape2D.new()
	lr.size = Vector2(60, 32)
	ls.shape = lr
	ls.position = Vector2(222, G - 16)
	_node(ls, "Shape", ledge)
	# The broken bridge's two decks, over the pool.
	_slab("BridgeWest", 544, 640, DECK, false)
	_slab("BridgeEast", 704, 800, DECK, false)
	# The tree's great branch: she can jump up through it and drop back down.
	_slab("BranchWest", 96, 320, 19 * TILE, true)


# --- The great tree ---------------------------------------------------------------------------------

func _build_tree(behind: Node, placed: Node, _front: Node) -> void:
	# The great Ironbark over the start, as in the clearing east of here: thorn
	# knots sleeping in its crown (Thorn-Line), a lantern on its bough.
	var tree := _sprite(behind, ENV + "landmark_great_ironbark.png", Rect2(1, 1, 255, 252), Vector2(-72, G - 248))
	tree.name = "GreatIronbark"
	_light(behind, Vector2(-72, G - 248) + Vector2(193, 130), LAMP, 1.0, 1.1, "TreeLantern")
	# Its great branch, reaching east toward the islands.
	_sprite(placed, GT, Rect2(112, 0, 256, 56), Vector2(64, 19 * TILE - 24)).name = "BranchWest"
	# Two mossy blocks of the old wall beside it.
	_sprite(placed, PL, Rect2(40, 80, 32, 36), Vector2(190, G - 34)).name = "WallBlock"
	_sprite(placed, PL, Rect2(80, 80, 32, 36), Vector2(222, G - 34)).name = "WallBlock"
	_ground(behind, GRAVE, Rect2(165, 2, 35, 45), 300.0, G, 0.95, "Grave")
	_ground(behind, FLORA, Rect2(126, 93, 42, 27), 340.0, G, 1.0, "Mushrooms")


# --- The pool and the broken bridge -------------------------------------------------------------------

func _build_pool(behind: Node, placed: Node) -> void:
	# Stairs from the tree's ground down to the bank.
	var st := _sprite(placed, CH, Rect2(36, 160, 68, 48), Vector2(384 - 38, G - 3))
	st.name = "StairsTreeBank"
	st.flip_h = true
	# SF11's bridge, as two broken ends: each its stair, its deck and two arches.
	_sprite(placed, PL, Rect2(0, 0, 163, 64), Vector2(482, DECK - 27)).name = "BridgeWest"
	var east := _sprite(placed, PL, Rect2(0, 0, 163, 64), Vector2(704 - 6, DECK - 27))
	east.name = "BridgeEast"
	east.flip_h = true
	# Fallen blocks in the water under the gap (behind her: not a way across).
	for s in [[Rect2(120, 72, 32, 30), 652.0], [Rect2(80, 140, 30, 32), 676.0]]:
		var stump := _sprite(behind, PL, s[0], Vector2(s[1], BANK + 6 - s[0].size.y + 12))
		stump.name = "FallenBlock"
		stump.modulate = Color(0.62, 0.64, 0.72)
	# The pool. A glint lies deep under the gap (Deep-Glow Breath).
	var pool := _water("Pool", Vector2(544, BANK + 6), Vector2(256, 58), Vector2(128, 40))
	pool.z_index = 12
	for pad in [[Rect2(272, 88, 64, 10), 560.0], [Rect2(272, 102, 64, 10), 720.0]]:
		var lily := _sprite(behind, PL, pad[0], Vector2(pad[1], BANK + 3))
		lily.name = "LilyPads"
		lily.z_index = 11
	for r in [[Rect2(270, 124, 20, 26), 532.0], [Rect2(336, 124, 14, 28), 806.0]]:
		_ground(behind, PL, r[0], r[1], BANK + 2, 1.0, "Reeds")


# --- The hill and the chapel ----------------------------------------------------------------------------

func _build_hill(behind: Node, placed: Node) -> void:
	# The four flights of stairs.
	for s in [[960.0, G], [1104.0, T2], [1248.0, T3], [1392.0, TOP]]:
		_sprite(placed, CH, Rect2(36, 160, 68, 48), Vector2(s[0] - 30, s[1] - 3)).name = "StairsHill"
	# The guard's chapel on the hilltop, its windows lit, nobody home.
	_sprite(behind, CH, Rect2(12, 0, 96, 92), Vector2(1436, TOP - 90)).name = "Chapel"
	_light(behind, Vector2(1436 + 34, TOP - 90 + 62), LAMP, 0.9, 0.8, "ChapelWindowLight")
	_light(behind, Vector2(1436 + 62, TOP - 90 + 62), LAMP, 0.9, 0.8, "ChapelWindowLight")
	_ground(behind, CH, Rect2(224, 8, 24, 40), 1404.0, TOP, 1.0, "GatePillar")
	# The terraces: graves, a fence, ruins.
	_ground(behind, IS, Rect2(144, 184, 64, 62), 968.0, G, 0.95, "RuinArch")
	_ground(behind, CH, Rect2(128, 8, 80, 27), 1110.0, T2 + 1, 1.0, "Fence")
	_ground(behind, CH, Rect2(40, 220, 24, 28), 1150.0, T2, 1.0, "Grave")
	_ground(behind, IS, Rect2(248, 186, 128, 61), 1252.0, T3 + 1, 0.9, "Arcade")
	_ground(behind, CH, Rect2(72, 222, 18, 26), 1300.0, T3, 1.0, "Grave")
	_ground(behind, CH, Rect2(288, 220, 22, 18), 880.0, BANK, 1.0, "Mushrooms")
	# The tracery ruin with its lantern, at the hill's foot.
	_ground(behind, IS, Rect2(8, 160, 90, 87), 1020.0, G + 1, 0.95, "TraceryRuin")
	_light(behind, Vector2(1020 + 82, G - 87 + 41), LAMP, 0.9, 0.8, "RuinLanternLight")


# --- The islands -------------------------------------------------------------------------------------------

func _build_islands(behind: Node, placed: Node) -> void:
	# Each painted island's grass line lies on its collision's top.
	_sprite(placed, IS, Rect2(18, 0, 192, 76), Vector2(360, 18 * TILE - 38)).name = "RuinIsland"
	_sprite(placed, IS, Rect2(16, 84, 130, 56), Vector2(602, 17 * TILE - 21)).name = "GraveIsland"
	_sprite(placed, IS, Rect2(280, 104, 64, 40), Vector2(1598, 9 * TILE - 11)).name = "FarIsland"
	# The long island (the Ironbark kit's own), the last step onto the hill.
	_sprite(placed, ENV + "ironbark_islands.png", Rect2(130, 2, 246, 85), Vector2(49 * TILE - 3, 18 * TILE - 31)).name = "LongIsland"
	# Something glints on the far island (Wing-Cloak).
	var glint := _sprite(behind, "res://assets/characters/kleo/fx_small.png", Rect2(0, 0, 64, 64), Vector2(1616, 9 * TILE - 40))
	glint.name = "FarGlint"
	glint.scale = Vector2(0.5, 0.5)
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	gm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glint.material = gm
	glint.modulate = Color(1.0, 0.85, 0.5)
	glint.set_script(load("res://scripts/fx/pulse.gd"))


# --- Atmosphere ------------------------------------------------------------------------------------------------

func _build_atmosphere() -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.64, 0.63, 0.78)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_fog(_root, Rect2(480, BANK - 30, 400, 60), Color("#5f8a8c"), 0.28, Vector2(0.006, 0.0))
	# Moonlight falling through the canopy.
	for sh in [[420.0, 70.0], [1010.0, 90.0], [1500.0, 60.0]]:
		var shaft := _node(Polygon2D.new(), "LightShaft", _root) as Polygon2D
		shaft.z_index = 3
		var x: float = sh[0]
		var w: float = sh[1]
		shaft.polygon = PackedVector2Array([Vector2(x, 0), Vector2(x + w, 0), Vector2(x + w + 150, 430), Vector2(x + 150, 430)])
		shaft.vertex_colors = PackedColorArray([Color(1, 0.93, 0.7, 0.13), Color(1, 0.93, 0.7, 0.13), Color(1, 0.93, 0.7, 0.0), Color(1, 0.93, 0.7, 0.0)])
		shaft.material = add
	var flies := _particles("Fireflies", load("res://assets/fx/mote.png"), 30, 7.0, Rect2(0, 200, 1792, 240))
	flies.color = Color(1.0, 0.82, 0.45)
	flies.gravity = Vector2(0, -2)
	flies.initial_velocity_min = 3.0
	flies.initial_velocity_max = 9.0
	flies.spread = 180.0
	flies.scale_amount_min = 0.5
	flies.scale_amount_max = 1.0
	flies.material = add
	flies.z_index = 14
	var leaves := _particles("Leaves", load("res://assets/fx/leaf.png"), 14, 11.0, Rect2(0, 0, 1792, 60))
	leaves.gravity = Vector2(5, 16)
	leaves.initial_velocity_min = 4.0
	leaves.initial_velocity_max = 12.0
	leaves.angular_velocity_min = -90.0
	leaves.angular_velocity_max = 90.0
	leaves.z_index = 14


## The foreground plane: the Ironbark canopy (P5) along the room's top edge.
func _build_foreground() -> void:
	var p := _node(Parallax2D.new(), "Foreground", _root) as Parallax2D
	p.scroll_scale = Vector2(1.2, 1.0)
	p.repeat_size = Vector2(720, 0)
	p.repeat_times = 4
	p.z_index = 30
	var top := _sprite(p, PARALLAX + "fg.png", Rect2(0, 0, 720, 132), Vector2(0, -8))
	top.name = "Canopy"
	top.material = _unlit
	top.modulate = Color(0.55, 0.55, 0.62)
