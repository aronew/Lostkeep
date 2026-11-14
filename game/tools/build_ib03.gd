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
	[100, 9, 4, 1, 0],    # the far island (Wing-Cloak)
]
const STONE := []
const SKIP := [[23, 18, 11, 1], [38, 17, 7, 1], [100, 9, 4, 1]]
const BACK := []
const BACK_EARTH := []

## The start of the game: under the great tree, by its lantern.
const SPAWN := Vector2(14 * 16, 24 * 16)

const GT := ENV + "surface_great_tree.png"
const CH := ENV + "surface_chapel_terraces.png"
const PL := ENV + "surface_pool_bridge.png"
const IS := ENV + "surface_ruin_islands.png"
const BD := ENV + "surface_backdrops.png"
const LAN := ENV + "props_lanterns.png"
const LAMP := Color(1.0, 0.72, 0.4)

# Walking lines (px).
const G := 384.0      # the start, and the first terrace
const BANK := 432.0
const DECK := 400.0
const T2 := 336.0
const T3 := 288.0
const TOP := 240.0

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
	_edge_shades()
	_door("East", Rect2i(104, 24, 8, 5), 1, IB01, "WestUpper")
	# West: the forest road. Its room isn't built: a place to arrive, no way through.
	_door("West", Rect2i(0, 19, 6, 5), -1, "", "")
	_finish()
	quit()


# --- Backdrops ---------------------------------------------------------------------------------

func _layer(layer_name: String, scale: Vector2, region: Rect2, y: float, base: Color) -> Parallax2D:
	var p := _node(Parallax2D.new(), layer_name, _root) as Parallax2D
	p.scroll_scale = scale
	p.repeat_size = Vector2(region.size.x, 0)
	p.repeat_times = 4
	p.z_index = -10
	var s := _sprite(p, BD, region, Vector2(0, y))
	s.name = "Art"
	var fill := _node(ColorRect.new(), "Base", p) as ColorRect
	fill.color = base
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.position = Vector2(0, y + region.size.y - 1)
	fill.size = Vector2(region.size.x, 420)
	return p


## SF13: the dusk sky with the far forest and its ruins, then the nearer trees.
func _build_backdrops() -> void:
	_layer("Sky", Vector2(0.06, 0.1), Rect2(0, 0, 768, 216), -4.0, Color("#3a6488"))
	_layer("Mid", Vector2(0.35, 0.3), Rect2(0, 280, 768, 152), 196.0, Color("#386489"))
	var fog := _node(Parallax2D.new(), "FogMid", _root) as Parallax2D
	fog.scroll_scale = Vector2(0.5, 0.4)
	fog.z_index = -10
	_fog(fog, Rect2(-200, 300, 2400, 170), Color("#5f8aa0"), 0.24, Vector2(0.006, 0.0))


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
	# The great tree's root ledge: two tiles up, the way to the branches.
	var ledge := _body("RootLedge", 1)
	var ls := CollisionShape2D.new()
	var lr := RectangleShape2D.new()
	lr.size = Vector2(80, 32)
	ls.shape = lr
	ls.position = Vector2(120, G - 16)
	_node(ls, "Shape", ledge)
	# The broken bridge's two decks, over the pool.
	_slab("BridgeWest", 544, 640, DECK, false)
	_slab("BridgeEast", 704, 800, DECK, false)
	# The great branches: she can jump up through them and drop back down.
	_slab("BranchWest", 96, 320, 19 * TILE, true)
	_slab("BranchEast", 784, 1040, 18 * TILE, true)


# --- The great tree ---------------------------------------------------------------------------------

func _trunk(parent: Node, x: float, base_y: float, copies: int, flip: bool, tint: Color) -> void:
	# The trunk, and its upper length repeated on up out of sight: it leans as it
	# rises, so each length is set over along the lean.
	var lean := -6.0 if flip else 6.0
	for i in range(copies, 0, -1):
		var up := _sprite(parent, GT, Rect2(0, 0, 96, 62), Vector2(x + lean * i, base_y - 118 - 60 * i))
		up.name = "TrunkUpper"
		up.flip_h = flip
		up.modulate = tint
	var t := _sprite(parent, GT, Rect2(0, 0, 96, 120), Vector2(x, base_y - 118))
	t.name = "Trunk"
	t.flip_h = flip
	t.modulate = tint


## A crown of leaves from `bottom_y` up past the room's top, over [x0, x1]. Rows
## are laid from the lowest up, each wider than the one under it and 28 px
## higher, so its leaves cover the flat top edge of the row below; the top
## row's flat edge is above the room.
func _crown(front: Node, x0: float, x1: float, bottom_y: float) -> void:
	var y := bottom_y
	var i := 0
	while true:
		var x := x0 - 24.0 * i - (90.0 if i % 2 == 1 else 0.0)
		var n := 0
		while x < x1 + 24.0 * i:
			var leaf := _sprite(front, GT, Rect2(112, 184, 256, 62), Vector2(x, y))
			leaf.name = "Crown"
			leaf.flip_h = (n + i) % 2 == 1
			leaf.material = _unlit
			var shade := 0.74 - 0.05 * i
			leaf.modulate = Color(shade - 0.1, shade - 0.08, shade)
			x += 200.0
			n += 1
		if y < 0.0:
			break
		y -= 28.0
		i += 1


func _build_tree(behind: Node, placed: Node, front: Node) -> void:
	# The great tree at the start: its trunk, and the root mound with its mossy
	# ledge (the collision's root ledge) and ruined wall.
	_trunk(behind, 20, 356, 4, false, Color.WHITE)
	_sprite(placed, GT, Rect2(0, 128, 192, 47), Vector2(20, G - 46)).name = "RootMound"
	# The west branch, with its lantern.
	_sprite(placed, GT, Rect2(112, 0, 256, 56), Vector2(90, 19 * TILE - 24)).name = "BranchWest"
	_light(behind, Vector2(90 + 164, 19 * TILE - 24 + 40), LAMP, 0.95, 0.9, "BranchLanternLight")
	# The second tree, on the hill, and the east branch reaching back over the pool.
	_trunk(behind, 1012, G + 2, 5, true, Color(0.86, 0.86, 0.92))
	var be := _sprite(placed, GT, Rect2(112, 64, 256, 56), Vector2(784, 18 * TILE - 26))
	be.name = "BranchEast"
	be.flip_h = true
	# Leaves: the crowns, hanging into the top of the view.
	_crown(front, -40.0, 400.0, 96.0)
	_crown(front, 660.0, 1330.0, 52.0)
	for c in [[40.0, 130.0, true], [990.0, 84.0, false]]:
		var leaf := _sprite(behind, GT, Rect2(112, 184, 256, 62), Vector2(c[0], c[1]))
		leaf.name = "CrownBehind"
		leaf.flip_h = c[2]


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
	_ground(behind, CH, Rect2(8, 218, 24, 30), 1010.0, G, 1.0, "Grave")
	_ground(behind, CH, Rect2(128, 8, 80, 27), 1110.0, T2 + 1, 1.0, "Fence")
	_ground(behind, CH, Rect2(40, 220, 24, 28), 1150.0, T2, 1.0, "Grave")
	_ground(behind, IS, Rect2(248, 186, 128, 61), 1252.0, T3 + 1, 0.9, "Arcade")
	_ground(behind, CH, Rect2(72, 222, 18, 26), 1300.0, T3, 1.0, "Grave")
	_ground(behind, CH, Rect2(288, 220, 22, 18), 880.0, BANK, 1.0, "Mushrooms")
	# The start: the tracery ruin with its lantern, a grave under the tree.
	_ground(behind, IS, Rect2(8, 160, 90, 87), 268.0, G + 1, 0.95, "TraceryRuin")
	_light(behind, Vector2(268 + 82, G - 87 + 41), LAMP, 0.9, 0.8, "RuinLanternLight")
	_ground(behind, CH, Rect2(312, 226, 12, 12), 236.0, G, 1.0, "Mushrooms")


# --- The islands -------------------------------------------------------------------------------------------

func _build_islands(behind: Node, placed: Node) -> void:
	# Each painted island's grass line lies on its collision's top.
	_sprite(placed, IS, Rect2(18, 0, 192, 76), Vector2(360, 18 * TILE - 38)).name = "RuinIsland"
	_sprite(placed, IS, Rect2(16, 84, 130, 56), Vector2(602, 17 * TILE - 21)).name = "GraveIsland"
	_sprite(placed, IS, Rect2(280, 104, 64, 40), Vector2(1598, 9 * TILE - 11)).name = "FarIsland"
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
	mod.color = Color(0.68, 0.67, 0.82)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_fog(_root, Rect2(480, BANK - 30, 400, 60), Color("#6f9ab0"), 0.26, Vector2(0.006, 0.0))
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


## The foreground plane: SF9's leaves along the room's top edge, close to the camera.
func _build_foreground() -> void:
	var p := _node(Parallax2D.new(), "Foreground", _root) as Parallax2D
	p.scroll_scale = Vector2(1.2, 1.0)
	p.repeat_size = Vector2(512, 0)
	p.repeat_times = 5
	p.z_index = 30
	for i in 2:
		var top := _sprite(p, GT, Rect2(112, 184, 256, 62), Vector2(i * 256, -22))
		top.name = "Canopy"
		top.flip_h = i == 1
		top.material = _unlit
		top.modulate = Color(0.42, 0.44, 0.54)
