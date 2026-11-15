extends "res://tools/surface_builder.gd"
## Builds room IB-04, the Gate Road, and saves it as an ordinary scene.
## Re-running overwrites scenes/rooms/ironbark_04_gate_road.tscn.
##
##   godot --headless --path game --script res://tools/build_ib04.gd
##
## Spec and validation: design/rooms/ironbark_04_gate_road.md. After the
## creative lead's mockup "Moonlit Ruin Gardens Above the Forest": she comes in
## high on the west hill and winds back down its terraces, with the great
## islands hanging over them; then the straight road east, a jump over the
## water, and the way on to the guard's clearing (IB-01).
##
## World grid: origin at IB-01's (-128, -13). Its East door (rows 32 to 36) is
## IB-01's west upper exit (rows 19 to 23); its West door (rows 11 to 15) is
## IB-03's East door.

const ROOM_PATH := "res://scenes/rooms/ironbark_04_gate_road.tscn"
const IB01 := "res://scenes/rooms/ironbark_test_room.tscn"
const IB03 := "res://scenes/rooms/ironbark_03_ruin_gardens.tscn"

const ROOM := Rect2i(0, 0, 128, 40)
const ROCK := [
	[0, 37, 128, 3, 0],    # the ground: the road east
	[0, 16, 10, 21, 0],    # the west hill, winding down east
	[10, 19, 8, 18, 0],
	[18, 22, 8, 15, 0],
	[26, 26, 8, 11, 0],
	[34, 29, 8, 8, 0],
	[42, 34, 8, 3, 0],
]
const SPACES := [
	[78, 37, 42, 2],       # the long pool across the road
]
## The islands: one tile of collision under each painting's grass line.
const MASSES := [
	[21, 17, 3, 1, 0],     # the stepping island (bush chunk)
	[27, 16, 19, 1, 0],    # the great island, over the terraces (the tree)
	[50, 20, 16, 1, 0],    # the root-held island, over the road
	# The high path over the pool: each island at its own height, up and down.
	[70, 18, 9, 1, 0],     # the ruin island (two up)
	[83, 21, 11, 1, 0],    # the crystal-shrine island (three down)
	[97, 18, 3, 1, 0],     # a bush chunk (three up)
	[104, 21, 9, 1, 0],    # a second ruin island (three down)
	[115, 25, 5, 1, 0],    # the headstone chunk: the last step, right over the far bank
	                       # (a full jump from the ruin overshoots it onto the bank, not into the water)
	[122, 14, 3, 1, 0],    # the far chunk (Wing-Cloak)
]
const SKIP := [[21, 17, 3, 1], [27, 16, 19, 1], [50, 20, 16, 1], [70, 18, 9, 1], [83, 21, 11, 1], [97, 18, 3, 1], [104, 21, 9, 1], [115, 25, 5, 1], [122, 14, 3, 1]]
const SPAWN := Vector2(4 * 16, 16 * 16)

const GROUND := 592.0


func _initialize() -> void:
	room = ROOM
	rock = ROCK
	spaces = SPACES
	masses = MASSES
	skip = SKIP
	spawn = SPAWN
	room_path = ROOM_PATH
	var t := _surface_begin("IronbarkGateRoad")
	var behind: Node = t["behind"]
	var placed: Node = t["placed"]
	_island(placed, "chunk_bush", 21, 17, 3)
	_island(placed, "tree", 27, 16, 19)
	_island(placed, "root_held", 50, 20, 16)
	_island(placed, "ruin", 70, 18, 9)
	_island(placed, "shrine", 83, 21, 11)
	_island(placed, "chunk_bush", 97, 18, 3)
	_island(placed, "ruin", 104, 21, 9).flip_h = true
	_island(placed, "chunk_headstone", 115, 25, 5)
	_island(placed, "chunk_bush", 122, 14, 3)
	_hide_island_tiles()
	# The flights down the hill.
	_flight(placed, 160, 19 * TILE, true)
	_flight(placed, 288, 22 * TILE, true)
	_flight(placed, 544, 29 * TILE, true)
	_flight(placed, 800, GROUND, true)
	_build_pool(behind, placed)
	_dress(behind, placed)
	_surface_finish()
	_door("West", Rect2i(0, 11, 8, 5), -1, IB03, "East")
	_door("East", Rect2i(120, 32, 8, 5), 1, IB01, "WestUpper")
	_finish()
	quit()


## The long pool across the road: more than a screen of water, and two ways
## over it (the creative lead's call, after their mockup). Low: the old wall's
## broken piers, six small islands to hop. High: the big floating islands above
## (ruin, crystal shrine, bush chunk, ruin, headstone chunk), each at its own
## height so the way across goes up and down, reached from the hill's island line. The piers are spaced for her real jump: about 55 px of water,
## then 48 px to land on; their tops stand a tile or two above the road so the
## stone shows over the water. She can't swim yet; a miss returns her to where
## she last stood. Each low island is two piers side by side: [left edge x, top y].
const POOL_ISLANDS := [[1304.0, 576.0], [1407.0, 560.0], [1510.0, 576.0], [1613.0, 576.0], [1716.0, 560.0], [1819.0, 576.0]]
## Piers from SF11: [region, the stone top's row in the region].
const PIERS := [
	[Rect2(1, 79, 30, 54), 9], [Rect2(81, 80, 31, 44), 7],
	[Rect2(42, 141, 29, 44), 7], [Rect2(120, 140, 29, 46), 6],
	[Rect2(81, 80, 31, 44), 7], [Rect2(1, 79, 30, 54), 9],
]

func _build_pool(behind: Node, placed: Node) -> void:
	var n := 0
	for isl in POOL_ISLANDS:
		var x0: float = isl[0]
		var top: float = isl[1]
		for k in 2:
			var pier: Array = PIERS[n % PIERS.size()]
			var region: Rect2 = pier[0]
			var px := x0 - 2.0 if k == 0 else x0 + 50.0 - region.size.x
			_sprite(placed, PL, region, Vector2(px, top - float(pier[1]))).name = "Pier"
			n += 1
		var b := _body("PoolIsland", 1)
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(48, 10)
		cs.shape = r
		cs.position = Vector2(x0 + 24.0, top + 5.0)
		_node(cs, "Shape", b)
	var pool := _water("Pool", Vector2(78 * TILE, GROUND + 5), Vector2(42 * TILE, 2 * TILE - 5), Vector2(300, 14))
	pool.get_node("Glint").visible = false
	var x := 1256.0
	var i := 0
	while x < 1900.0:
		var lily := _sprite(behind, PL, Rect2(272, 88 + 14 * (i % 2), 64, 10), Vector2(x, GROUND + 2))
		lily.name = "LilyPads"
		lily.z_index = 11
		x += 103.0
		i += 1
	_ground(behind, PL, Rect2(270, 124, 20, 26), 1226.0, GROUND + 2, 1.0, "Reeds")
	_ground(behind, PL, Rect2(336, 124, 14, 28), 1924.0, GROUND + 2, 1.0, "Reeds")


func _dress(behind: Node, placed: Node) -> void:
	# The hilltop she arrives on: the arch from the gardens, its lantern.
	_arch_door(behind, -30, 16 * TILE, false)
	# The terraces: graves and fences all the way down.
	_row(behind, GRAVE, 19 * TILE, [[GRAVE_CROSS, 236.0]])
	_row(behind, GRAVE, 22 * TILE, [[GRAVE_CELTIC, 372.0]])
	_row(behind, GRAVE, 26 * TILE, [[FENCE, 424.0], [GRAVE_CREST, 470.0]])
	_lantern_post(behind, 620, 29 * TILE)
	_row(behind, GRAVE, 34 * TILE, [[GRAVE_BROKEN, 690.0], [GRAVE_CROSS, 730.0]])
	# Something glints on the far chunk, high over the road's end (Wing-Cloak).
	_glint(behind, Vector2(1960, 14 * TILE - 30), Color(1.0, 0.85, 0.5))
	# The road east: graves, a ruin, a crystal shrine, the timber gate over the water.
	_row(behind, GRAVE, GROUND, [[GRAVE_CREST, 880.0]])
	_piece(behind, DOOR_RUINED, 900, GROUND, "RoadRuin").modulate = Color(0.9, 0.9, 0.95)
	_piece(behind, CRYSTAL_SHRINE, 1020, GROUND, "CrystalShrine")
	_row(behind, FLORA, GROUND, [[TUFTS[1], 1090.0], [TUFTS[0], 1990.0]])
	_piece(behind, TIMBER_GATE, 1120, GROUND, "TimberGate")
	_lantern_post(behind, 1200, GROUND)
	_lantern_post(behind, 1950, GROUND)
