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
const IB09 := "res://scenes/rooms/ironbark_09_outpost.tscn"

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
	# The detail pass keeps clear of the outpost's front (nothing in its doorway).
	detail_skip = SKIP + [[17, 10, 20, 7]]
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
## kneels), the building (a stand-in until OP1 comes), and its doorway into the
## stranger's interior (IB-09).
func _build_outpost(behind: Node) -> void:
	# The building: the creative lead's OP1, reduced 5:1 (tools/make_outpost.py),
	# its white doorway on the walkway's entry (x 22.5), its base stones sunk
	# 3 px into the floor. On the root, not graded, so the door stays bright.
	var hut := _node(Sprite2D.new(), "Outpost", _root) as Sprite2D
	hut.texture = load(ENV + "outpost.png")
	hut.centered = false
	hut.position = Vector2(22.5 * TILE - OUTPOST_DOOR.x, WALK + 3 - OUTPOST_SIZE.y)
	hut.z_index = 2
	# Its leaf window glows faintly from inside.
	_light(behind, hut.position + OUTPOST_LEAF, Color(0.6, 0.95, 0.88), 0.9, 0.5, "LeafWindowLight")
	_hanging_lantern(behind, 36 * TILE, 4 * TILE)
	# The save shrine.
	var shrine := _node(Area2D.new(), "PrismShrine", _root) as Area2D
	shrine.set_script(load("res://scripts/world/prism_shrine.gd"))
	shrine.position = Vector2(11 * TILE, WALK)
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
	# The stranger lives inside (the creative lead: "I want it that you have to
	# enter his outpost"): the doorway leads into IB-09, the outpost's interior.
	_entry("OutpostDoor", Vector2(22.5 * TILE, WALK), Vector2(28, 44), IB09, "Entry", 1)
	_doorway_glow(behind, Vector2(22.5 * TILE, WALK))


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
	_sh_piece(behind, "arcades", Rect2(272, 32, 20, 80), 37.5 * T, WALK, "Pillar")
	_sh_piece(behind, "arcades", Rect2(4, 32, 128, 80), 50.0 * T, LOW, "Arcade")
	_hanging_lantern(behind, 7.0 * T, 4 * T)
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


## Light coming out of the outpost, as in the creative lead's Hollow Knight
## reference: a pale glow in the doorway, a fan of light spilling out of it
## across the walkway, a pool on the stones in front, and a haze blooming
## round the building in the mist. All additive, never baked into tiles.
## White, as OP1's painted doorway (the creative lead: "how about a white light
## at the door"), barely cool so it reads as light, not paper.
const SPILL := Color(0.92, 0.96, 1.0)
const OUTPOST_SIZE := Vector2(278, 185)
const OUTPOST_DOOR := Vector2(76, 180)   # the doorway, centre and sill
const OUTPOST_LEAF := Vector2(169, 146)  # the leaf window


func _doorway_glow(behind: Node, foot: Vector2) -> void:
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	# The light itself, strong: the mood pass halves cold lights.
	_light(behind, foot + Vector2(0, -24), SPILL, 2.2, 1.6, "DoorLight")
	var tex := _halo_texture()
	# The haze round the building, wide and faint.
	var haze := _node(Sprite2D.new(), "OutpostHaze", _root) as Sprite2D
	haze.texture = tex
	haze.position = foot + Vector2(40, -60)
	haze.scale = Vector2(6.5, 4.0)
	haze.modulate = Color(SPILL.r, SPILL.g, SPILL.b, 0.38)
	haze.material = add
	haze.z_index = 1
	# The doorway, glowing.
	var door := _node(Sprite2D.new(), "DoorGlow", _root) as Sprite2D
	door.texture = tex
	door.position = foot + Vector2(0, -22)
	door.scale = Vector2(0.75, 1.1)
	door.modulate = Color(SPILL.r, SPILL.g, SPILL.b, 0.95)
	door.material = add
	door.z_index = 6
	# The fan of light spilling out, widening and fading toward the floor.
	var fan := _node(Polygon2D.new(), "LightSpill", _root) as Polygon2D
	fan.polygon = PackedVector2Array([foot + Vector2(-10, -40), foot + Vector2(10, -40), foot + Vector2(70, 2), foot + Vector2(-70, 2)])
	fan.vertex_colors = PackedColorArray([Color(SPILL.r, SPILL.g, SPILL.b, 0.34), Color(SPILL.r, SPILL.g, SPILL.b, 0.34), Color(SPILL.r, SPILL.g, SPILL.b, 0.0), Color(SPILL.r, SPILL.g, SPILL.b, 0.0)])
	fan.material = add
	fan.z_index = 11
	# The pool on the stones in front of the door.
	var pool := _node(Sprite2D.new(), "LightPool", _root) as Sprite2D
	pool.texture = tex
	pool.position = foot + Vector2(0, 1)
	pool.scale = Vector2(2.6, 0.32)
	pool.modulate = Color(SPILL.r, SPILL.g, SPILL.b, 0.7)
	pool.material = add
	pool.z_index = 7
