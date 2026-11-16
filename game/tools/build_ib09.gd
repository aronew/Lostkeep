extends "res://tools/room_builder.gd"
## Builds room IB-09, the stranger's outpost (inside): entered by the outpost's
## doorway in IB-08 (the creative lead: "I want it that you have to enter his
## outpost ... spooky feeling in a way, not all bright"). Re-running overwrites
## scenes/rooms/ironbark_09_outpost.tscn.
##
##   godot --headless --path game --script res://tools/build_ib09.gd
##
## An interior, not on the world grid: one screen. Its west door leads back out
## to the doorway on IB-08's walkway.

const ROOM_PATH := "res://scenes/rooms/ironbark_09_outpost.tscn"
const IB08 := "res://scenes/rooms/ironbark_08_foundations.tscn"

const ROOM := Rect2i(0, 0, 40, 23)
const ROCK := [[0, 0, 40, 23, 1]]
const SPACES := [
	[2, 4, 36, 14],     # the one room (floor row 18, ceiling row 4)
	[0, 13, 2, 5],      # the way back out, west
]
const MASSES := []
const STONE := [[0, 0, 40, 23]]
const SKIP := []
const SPAWN := Vector2(5 * 16, 18 * 16)
const FLOOR := 18.0 * 16
const OC_PROPS := ENV + "oc_props.png"
const FLAME := Color(1.0, 0.62, 0.3)


func _initialize() -> void:
	room = ROOM
	rock = ROCK
	spaces = SPACES
	masses = MASSES
	stone = STONE
	skip = SKIP
	# The detail pass keeps clear of his counter, so nothing stands in front of him.
	detail_skip = [[21, 14, 14, 4]]
	spawn = SPAWN
	room_path = ROOM_PATH
	var tileset := _shared()
	_use_crypt_y_stone()
	_begin("IronbarkOutpost")
	var t := _terrain(tileset)
	_grade_stone()
	_back_wall()
	_dress(t["behind"])
	_build_stranger()
	_build_air()
	_door("Entry", Rect2i(0, 13, 8, 5), -1, IB08, "OutpostDoor")
	_edge_shades()
	# Spooky, not bright: the crypts' mood, sunk much darker.
	_detail_kind = "crypt"
	_mood = true
	mood_murk = Color(0.27, 0.27, 0.36)
	detail_near = false
	_ch_detail = true
	_rim = true
	_finish()
	quit()


func _back_wall() -> void:
	var wall := _node(Node2D.new(), "BackWall", _root) as Node2D
	wall.set_script(load("res://scripts/world/back_wall.gd"))
	wall.z_index = -2
	wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall.set("fill", load(TERRAIN + "sh_fill.png"))
	wall.set("brightness", 0.75)
	var regions: Array[Rect2i] = [Rect2i(2, 4, 36, 14), Rect2i(0, 13, 2, 5)]
	wall.set("regions", regions)


## The clutter of a wanderer's den: shelves of arches behind the counter, jars,
## bones, a cobweb and chains in the corners, a few candles.
func _dress(behind: Node) -> void:
	var T := float(TILE)
	var alc := ENV + "ch_alcoves.png"
	var props := ENV + "ch_props.png"
	var hangs := ENV + "ch_hangings.png"
	# Shelves: CH6's arcade recesses standing on the floor against the wall.
	_sprite(behind, alc, Rect2(142, 30, 85, 81), Vector2(23.0 * T, FLOOR - 56)).name = "Shelves"
	_sprite(behind, alc, Rect2(8, 22, 127, 89), Vector2(8.0 * T, FLOOR - 80)).name = "Recess"
	# The counter: crates and pots, the stranger behind it.
	# In front of the stranger (z 4 against his 3): he stands behind it.
	var counter := _sprite(behind, props, Rect2(240, 94, 47, 26), Vector2(26.0 * T, FLOOR - 26))
	counter.name = "Counter"
	counter.z_index = 2
	_sprite(behind, props, Rect2(294, 92, 40, 28), Vector2(30.0 * T, FLOOR - 28)).name = "Jars"
	# A candelabra by the counter, candles about.
	_sprite(behind, props, Rect2(347, 74, 23, 46), Vector2(24.2 * T, FLOOR - 46)).name = "Candelabra"
	_light(behind, Vector2(24.9 * T, FLOOR - 42), FLAME, 0.8, 0.7, "CandelabraLight")
	for x in [12.5, 33.0]:
		_sprite(behind, OC_PROPS, Rect2(133, 163, 9, 28), Vector2(x * T, FLOOR - 28)).name = "Candle"
		_light(behind, Vector2(x * T + 4, FLOOR - 26), FLAME, 0.45, 0.35, "CandleLight")
	# Bones on the floor, a crystal glowing faintly violet in the corner.
	_sprite(behind, OC_PROPS, Rect2(41, 46, 46, 21), Vector2(15.0 * T, FLOOR - 21)).name = "Bones"
	_sprite(behind, props, Rect2(106, 21, 32, 18), Vector2(35.0 * T, FLOOR - 18)).name = "Crystal"
	_light(behind, Vector2(36.0 * T, FLOOR - 10), Color(0.62, 0.42, 0.95), 0.35, 0.4, "CrystalGlow")
	# A cobweb in the east corner, chains from the ceiling.
	var web := _sprite(behind, hangs, Rect2(13, 93, 32, 27), Vector2(38.0 * T - 32, 4.0 * T - 2))
	web.name = "Cobweb"
	web.flip_h = true
	_sprite(behind, hangs, Rect2(340, 8, 12, 79), Vector2(19.0 * T, 4.0 * T - 4)).name = "Chain"
	_sprite(behind, hangs, Rect2(360, 8, 16, 111), Vector2(29.5 * T, 4.0 * T - 4)).name = "Chain2"


## The stranger, behind the counter, eyes glowing amber in the dark.
func _build_stranger() -> void:
	var stranger := _node(Area2D.new(), "Stranger", _root) as Area2D
	stranger.set_script(load("res://scripts/world/stranger.gd"))
	stranger.position = Vector2(28.5 * TILE, FLOOR)
	stranger.z_index = 3
	var cs := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(72, 40)
	cs.shape = cr
	cs.position = Vector2(-16, -20)
	_node(cs, "Shape", stranger)
	# His frames (OP2): 8 of 32 x 47, feet on the bottom row; stranger.gd plays them.
	var art := _node(Sprite2D.new(), "Art", stranger) as Sprite2D
	art.texture = load("res://assets/characters/stranger/stranger_frames.png")
	art.hframes = 8
	art.centered = false
	art.position = Vector2(-16, -47)
	art.flip_h = true
	stranger.set("art", art)
	stranger.set("prompt_offset", Vector2(0, -58))
	# The eyes: a small cold-amber glow at the face, nothing more.
	_light(stranger, Vector2(-2, -33), Color(1.0, 0.7, 0.3), 0.6, 0.25, "EyeGlow")


func _build_air() -> void:
	var mod := _node(CanvasModulate.new(), "Darkness", _root) as CanvasModulate
	mod.color = Color(0.7, 0.7, 0.8)
	_dust("RoomDust", Rect2(3 * TILE, 5 * TILE, 34 * TILE, 12 * TILE), 14)
