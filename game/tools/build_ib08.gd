extends "res://tools/room_builder.gd"
## Builds room IB-08, the Keep's foundations: the outpost (the hooded
## stranger's, with the first save shrine since the clearing) and the way on
## east toward the Keep. Re-running overwrites
## scenes/rooms/ironbark_08_foundations.tscn.
##
##   godot --headless --path game --script res://tools/build_ib08.gd
##
## Spec and validation: design/rooms/ironbark_08_foundations.md. World grid:
## origin at IB-01's (44, 88). Its West door (rows 12 to 16) is the
## Undercroft's lower East door (IB-06, rows 60 to 64).
## After the creative lead's outpost mockup (docs/mockups/outpost/outpost.webp):
## a long straight walkway under a cave ceiling, the outpost on it, ruins either
## side, mist below.

const ROOM_PATH := "res://scenes/rooms/ironbark_08_foundations.tscn"
const IB06 := "res://scenes/rooms/ironbark_06_undercroft.tscn"

const ROOM := Rect2i(0, 0, 64, 28)
const ROCK := [[0, 0, 64, 28, 1]]
const SPACES := [
	[0, 12, 8, 5],      # the passage in from the Undercroft (floor row 17)
	[8, 4, 34, 13],     # the outpost cavern over the walkway (floor row 17)
	[42, 9, 22, 15],    # the lower gallery, east of the walkway's broken end (floor row 24)
	[36, 20, 6, 4],     # a secret room behind the gallery's west wall (floor row 24)
	[52, 24, 3, 3],     # under the cracked bark plate (Ironbark Ward): a pit with Resin
]
## Two CH1 slabs: the way back up from the lower gallery to the walkway.
const MASSES := [
	[43, 18, 2, 1, 1],   # just off the walkway's end, a tile below it
	[47, 21, 2, 1, 1],   # halfway down
]
const STONE := [[0, 0, 64, 28]]
const SKIP := [[43, 18, 2, 1], [47, 21, 2, 1]]
const SPAWN := Vector2(4 * 16, 17 * 16)
const WALK := 17.0 * 16
const LOW := 24.0 * 16


func _initialize() -> void:
	room = ROOM
	rock = ROCK
	spaces = SPACES
	masses = MASSES
	stone = STONE
	skip = SKIP
	spawn = SPAWN
	room_path = ROOM_PATH
	var tileset := _shared()
	_use_crypt_y_stone()
	_begin("IronbarkFoundations")
	_shrine_far()
	var t := _terrain(tileset)
	_platform(t["placed"], CH1_SLAB_SPEC, 43, 18, 2).name = "Slab"
	_platform(t["placed"], CH1_SLAB_SPEC, 47, 21, 2, true).name = "Slab2"
	_grade_stone()
	_build_outpost(t["behind"])
	_build_plate(t["behind"])
	_dress(t["behind"])
	_build_air()
	_build_secrets()
	_crypt_foreground()
	_edge_shades()
	_door("West", Rect2i(0, 12, 8, 5), -1, IB06, "EastLower")
	# On east toward the Keep (not built).
	_door("EastLower", Rect2i(56, 19, 8, 5), 1, "", "")
	_mood = true
	_ch_detail = true
	_rim = true
	_finish()
	quit()


## The outpost on the walkway: the save shrine (as the clearing's, where Kleo
## kneels), the building (a stand-in until OP1 comes), and the stranger.
func _build_outpost(behind: Node) -> void:
	# The building, a stand-in: CH6's arcade recess with its lantern, a doorway.
	var hut := _sprite(behind, ENV + "ch_alcoves.png", Rect2(8, 22, 127, 89), Vector2(22 * TILE, WALK - 80))
	hut.name = "OutpostStandIn"
	_sh_doorway(behind, 20 * TILE, WALK, false)
	_hanging_lantern(behind, 28 * TILE, 4 * TILE)
	# The save shrine.
	var shrine := _node(Area2D.new(), "PrismShrine", _root) as Area2D
	shrine.set_script(load("res://scripts/world/prism_shrine.gd"))
	shrine.position = Vector2(13 * TILE, WALK)
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
	shrine.set("flag", "ib08_shrine")
	# The stranger, by the outpost's door, facing the way Kleo comes in.
	var stranger := _node(Area2D.new(), "Stranger", _root) as Area2D
	stranger.set_script(load("res://scripts/world/stranger.gd"))
	stranger.position = Vector2(31 * TILE, WALK)
	stranger.z_index = 9
	var cs := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(40, 40)
	cs.shape = cr
	cs.position = Vector2(0, -20)
	_node(cs, "Shape", stranger)
	var art := _sprite(stranger, "res://assets/characters/stranger/stranger.png", Rect2(0, 0, 34, 48), Vector2(-17, -48))
	art.name = "Art"
	art.flip_h = true
	stranger.set("prompt_offset", Vector2(0, -58))
	_light(stranger, Vector2(0, -36), Color(1.0, 0.75, 0.45), 0.35, 0.35, "StrangerGlow")


## The lock seen before its key: a cracked bark plate in the gallery's floor
## (Ironbark Ward), with Resin glinting in the pit under it.
func _build_plate(behind: Node) -> void:
	var plate := _node(StaticBody2D.new(), "BarkPlateW1d", _root) as StaticBody2D
	plate.position = Vector2(52 * TILE, LOW)
	plate.z_index = 8
	var pc := CollisionShape2D.new()
	var pr := RectangleShape2D.new()
	pr.size = Vector2(3 * TILE, TILE)
	pc.shape = pr
	pc.position = Vector2(1.5 * TILE, 0.5 * TILE)
	_node(pc, "Shape", plate)
	_sprite(plate, ENV + "gate_bark_plate.png", Rect2(65, 97, 63, 29), Vector2(-8, -4)).name = "Art"
	_resin_cache(_root, 52.4 * TILE, 54.6 * TILE, 27.0 * TILE, 4, "ib08_pit_resin")


## Ruins either side of the outpost, as in the mockup; the gallery's lanterns,
## crates and pots (they drop Resin when smashed).
func _dress(behind: Node) -> void:
	var bag := ENV + "props_guard_belongings.png"
	var T := float(TILE)
	_sh_piece(behind, "arcades", Rect2(144, 32, 64, 80), 9.0 * T, WALK, "Arch")
	_sh_piece(behind, "arcades", Rect2(272, 32, 20, 80), 37.5 * T, WALK, "Pillar")
	_sh_piece(behind, "arcades", Rect2(4, 32, 128, 80), 50.0 * T, LOW, "Arcade")
	_hanging_lantern(behind, 9.0 * T, 4 * T)
	_hanging_lantern(behind, 58.0 * T, 9 * T)
	_sh_torch(behind, 5.0 * T, WALK - 56)
	_breakable(bag, POT, 35.0 * T, WALK, CLAY)
	_breakable(bag, POT, 36.4 * T, WALK, CLAY)
	_breakable(bag, CRATE_B, 44.0 * T, LOW, WOOD)
	_breakable(bag, POT, 60.0 * T, LOW, CLAY)


func _build_air() -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.82, 0.82, 0.92)
	_dust("CavernDust", Rect2(8 * TILE, 4 * TILE, 54 * TILE, 20 * TILE), 24)


## A secret room behind the lower gallery's west wall, under the walkway.
## Tell: motes drifting into the stone.
func _build_secrets() -> void:
	_false_wall("GallerySecret", Rect2i(36, 20, 6, 4), 42, Vector2i(20, 4), 1, "ib08_gallery_secret")
	_draught("GalleryDraught", Rect2(42.2 * TILE, 20.5 * TILE, 2.0 * TILE, 3.0 * TILE), Vector2(-1, 0))
	_resin_cache(_root, 36.6 * TILE, 40.6 * TILE, LOW, 6, "ib08_gallery_resin")
