extends SceneTree
## A mood test (the creative lead's moody fog reference,
## docs/mockups/mood/moody_fog_reference.webp): loads a built room, sinks it
## into a teal murk, lays fog along its floors, through its drops and across
## the bottom of the view, and lets the warm lanterns carry the scene. Saves a
## copy; the room itself is untouched.
##
##   godot --headless --path game --script res://tools/mood_test.gd -- <room.tscn> <out.tscn>

const TILE := 16
const MURK := Color(0.42, 0.52, 0.58)          # the CanvasModulate: low key, teal
const HAZE := Color(0.05, 0.12, 0.14, 0.2)    # washes the backdrops into fog
const FOG := Color(0.34, 0.5, 0.54)           # the fog's own colour
const FAR_TINT := Color(0.72, 0.9, 0.92)       # the backdrops, greyed toward teal


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var root: Node = load(args[0]).instantiate()
	_murk(root)
	_haze(root)
	_floor_fog(root)
	_screen_fog(root)
	_lights(root)
	_vignette(root)
	for c in root.get_children():
		_own(c, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, args[1])
	print("mood: ", args[1])
	quit()


func _own(n: Node, root: Node) -> void:
	if n.owner == null:
		n.owner = root
	for c in n.get_children():
		_own(c, root)


func _murk(root: Node) -> void:
	var d := root.get_node_or_null("Darkness") as CanvasModulate
	if d:
		d.color = MURK
	for c in root.get_children():
		if c is Parallax2D and c.z_index < 0:
			(c as Parallax2D).modulate = FAR_TINT


## A sheet of teal haze between the backdrops and the playfield: the far hall
## sinks into it, as the arcades do behind the reference's building.
func _haze(root: Node) -> void:
	var rect := _room_rect(root)
	var h := ColorRect.new()
	h.name = "MoodHaze"
	h.color = HAZE
	h.position = rect.position - Vector2(400, 400)
	h.size = rect.size + Vector2(800, 800)
	h.z_index = -9
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(h)
	var mood := root.get_node_or_null("Mood")
	if mood:
		root.move_child(h, mood.get_index() + 1)
	# A second, lower bank behind the playfield, heavy in the drops.
	var low := _fog(root, "DeepFog", Rect2(rect.position.x, rect.position.y + rect.size.y * 0.45, rect.size.x, rect.size.y * 0.6), 0.28, 1)
	low.material.set_shader_parameter("scale", Vector2(rect.size.x / 800.0, rect.size.y / 140.0))
	low.material.set_shader_parameter("side_fade", 0.08)


## Ground fog along every floor run of four tiles or more: one band behind the
## playfield's props and one, thinner, in front of Kleo's feet.
func _floor_fog(root: Node) -> void:
	var cells := {}
	for layer_name in ["Solid", "Masses"]:
		var tm := root.get_node_or_null(layer_name) as TileMapLayer
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
	for y in rows:
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
				var back := _fog(root, "FloorFog%d" % n, Rect2(x0, fy - 3.4 * TILE, w, 3.8 * TILE), 0.4, 3)
				back.material.set_shader_parameter("side_fade", 0.12)
				var front := _fog(root, "FloorFogFront%d" % n, Rect2(x0, fy - 1.4 * TILE, w, 2.0 * TILE), 0.22, 12)
				front.material.set_shader_parameter("side_fade", 0.15)
				front.material.set_shader_parameter("drift", Vector2(-0.008, 0.0))
				n += 1
			if i < xs.size():
				start = xs[i]
				prev = xs[i]


## A bank of fog along the bottom of the view, in the foreground's own frame
## (it holds its height on screen), over the near silhouettes' feet.
func _screen_fog(root: Node) -> void:
	var fg := root.get_node_or_null("Foreground") as Parallax2D
	if fg == null:
		return
	var rect := _room_rect(root)
	var r := _fog(fg, "ScreenFog", Rect2(-400, 250, rect.size.x * 1.3 + 800, 120), 0.45, 0)
	r.material.set_shader_parameter("scale", Vector2((rect.size.x * 1.3 + 800) / 600.0, 0.6))


## The warm lights carry the scene; the cold ones fall back.
func _lights(root: Node) -> void:
	for l in root.find_children("*", "PointLight2D", true, false):
		var pl := l as PointLight2D
		if pl.color.r > pl.color.b:
			pl.energy *= 2.2
			pl.texture_scale *= 1.6
		else:
			pl.energy *= 0.55


func _vignette(root: Node) -> void:
	var v := root.get_node_or_null("Screen/Vignette") as ColorRect
	if v and v.material:
		var m := (v.material as ShaderMaterial).duplicate() as ShaderMaterial
		m.set_shader_parameter("strength", 0.72)
		m.set_shader_parameter("inner", 0.32)
		m.set_shader_parameter("shadow", Color(0.01, 0.03, 0.04))
		v.material = m


func _fog(parent: Node, fog_name: String, rect: Rect2, density: float, z: int) -> ColorRect:
	var r := ColorRect.new()
	r.name = fog_name
	r.position = rect.position
	r.size = rect.size
	r.z_index = z
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/fog.gdshader")
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 128
	nt.seamless = true
	var noise := FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	nt.noise = noise
	m.set_shader_parameter("noise", nt)
	m.set_shader_parameter("tint", FOG)
	m.set_shader_parameter("density", density)
	m.set_shader_parameter("drift", Vector2(0.005, 0.0))
	m.set_shader_parameter("scale", Vector2(rect.size.x / 640.0, rect.size.y / 90.0))
	r.material = m
	parent.add_child(r)
	return r


func _room_rect(root: Node) -> Rect2:
	var tm := root.get_node_or_null("Solid") as TileMapLayer
	if tm == null:
		return Rect2(0, 0, 1280, 720)
	var u := tm.get_used_rect()
	return Rect2(u.position * TILE, u.size * TILE)
