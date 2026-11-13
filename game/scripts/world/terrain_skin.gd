@tool
class_name TerrainSkin
extends Node2D
## Paints terrain art onto the black-box collision.
##
## The collision is two TileMapLayers, matching how a room is built:
## - `solid_layer` is the rock: the room's floors, walls and ceilings.
## - `mass_layer` holds the masses put back into the spaces: an island, a shelf,
##   a fallen capstone. Masses are painted as objects of their own on top of the
##   rock, so a floor keeps its edge where a mass stands on it.
## Each tile's atlas column picks the material (0 = earth, 1 = stone). The skin
## paints along every exposed edge (walking tops, ceilings, walls) and fades
## each mass's inside toward the void, so the black box becomes the shadow.
##
## Edit a room by painting or erasing tiles; the skin follows. Keep this node at
## the same position as the TileMapLayers.

const TILE := 16
const MAX_DEPTH := 5  # tiles looked through when measuring how thick a mass is
const SIDES := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

## The rock.
@export var solid_layer: TileMapLayer:
	set(v):
		solid_layer = v
		_connect_layer(v)
		_queue_rebuild()
## The masses put back into the spaces.
@export var mass_layer: TileMapLayer:
	set(v):
		mass_layer = v
		_connect_layer(v)
		_queue_rebuild()
## One material per tile atlas column: 0 = earth, 1 = stone.
@export var materials: Array[TerrainMaterial] = []:
	set(v):
		materials = v
		_queue_rebuild()
## The room, in tiles. Anything outside it counts as solid, so the room's own
## border never gets an edge painted on it.
@export var room_rect := Rect2i(0, 0, 120, 40):
	set(v):
		room_rect = v
		_queue_rebuild()
## Cells covered by hand-placed art (islands, bridges): no skin there.
@export var skip_regions: Array[Rect2i] = []:
	set(v):
		skip_regions = v
		_queue_rebuild()
## Turn off to see the bare black box (F1 in game).
@export var skin_visible := true:
	set(v):
		skin_visible = v
		for n in _layers_nodes():
			n.visible = v
		# In the game the black tiles are only collision; they show in box view.
		if not Engine.is_editor_hint():
			for layer in [solid_layer, mass_layer]:
				if layer:
					layer.visible = not v

var _rock := {}  # Vector2i -> material index
var _mass := {}
var _skip := {}
var _passes: Array[Dictionary] = []
var _rebuild_queued := false


func _ready() -> void:
	add_to_group("box_view")
	for pass_name in ["Rock", "Masses"]:
		var fill := Node2D.new()
		fill.name = pass_name + "Fill"
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/terrain_fill.gdshader")
		fill.material = mat
		add_child(fill, false, Node.INTERNAL_MODE_FRONT)
		var edges := Node2D.new()
		edges.name = pass_name + "Edges"
		edges.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		add_child(edges, false, Node.INTERNAL_MODE_FRONT)
		var p := {"name": pass_name, "fill": fill, "edges": edges, "mat": mat}
		fill.draw.connect(_draw_fill.bind(p))
		edges.draw.connect(_draw_edges.bind(p))
		_passes.append(p)
	skin_visible = skin_visible
	_connect_layer(solid_layer)
	_connect_layer(mass_layer)
	rebuild()


func _layers_nodes() -> Array:
	var out := []
	for p in _passes:
		out.append(p["fill"])
		out.append(p["edges"])
	return out


func set_box_view(on: bool) -> void:
	skin_visible = not on


func _connect_layer(layer: TileMapLayer) -> void:
	if layer and layer.has_signal("changed") and not layer.changed.is_connected(_queue_rebuild):
		layer.changed.connect(_queue_rebuild)


func _queue_rebuild() -> void:
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	(func() -> void:
		_rebuild_queued = false
		rebuild()).call_deferred()


## Re-read the collision tiles and repaint.
func rebuild() -> void:
	if _passes.is_empty():
		return
	_rock = _read(solid_layer)
	_mass = _read(mass_layer)
	_skip.clear()
	for r in skip_regions:
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				_skip[Vector2i(x, y)] = true
	_passes[0]["cells"] = _rock
	_passes[0]["solid"] = func(c: Vector2i) -> bool: return _rock.has(c) or not room_rect.has_point(c)
	_passes[1]["cells"] = _mass
	_passes[1]["solid"] = func(c: Vector2i) -> bool: return _mass.has(c) or _rock.has(c) or not room_rect.has_point(c)
	for p in _passes:
		_build_cell_texture(p)
		p["fill"].queue_redraw()
		p["edges"].queue_redraw()


func _read(layer: TileMapLayer) -> Dictionary:
	var out := {}
	if layer:
		for c in layer.get_used_cells():
			out[c] = layer.get_cell_atlas_coords(c).x
	return out


## True if a cell is solid in either layer (or outside the room).
func is_solid(c: Vector2i) -> bool:
	return _rock.has(c) or _mass.has(c) or not room_rect.has_point(c)


# --- The fill: one shader pass per layer -----------------------------------------

func _build_cell_texture(p: Dictionary) -> void:
	var cells: Dictionary = p["cells"]
	var solid: Callable = p["solid"]
	var w := room_rect.size.x
	var h := room_rect.size.y
	if w <= 0 or h <= 0:
		return
	# Distance to open air, in tiles, by breadth-first search inward from every
	# cell of this layer that touches open air.
	var dist := {}
	var frontier: Array[Vector2i] = []
	for c in cells:
		for d in SIDES:
			if not solid.call(c + d):
				dist[c] = 1
				frontier.append(c)
				break
	var i := 0
	while i < frontier.size():
		var c: Vector2i = frontier[i]
		i += 1
		for d in SIDES:
			var n: Vector2i = c + d
			if cells.has(n) and not dist.has(n):
				dist[n] = dist[c] + 1
				frontier.append(n)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for c in cells:
		var local: Vector2i = c - room_rect.position
		if local.x < 0 or local.y < 0 or local.x >= w or local.y >= h:
			continue
		var dd: float = min(dist.get(c, 31), 31)
		var painted := 0.0 if _skip.has(c) else 1.0
		img.set_pixel(local.x, local.y, Color(dd / 32.0, float(cells[c]) / 8.0, 0.0, painted))
	var mat: ShaderMaterial = p["mat"]
	mat.set_shader_parameter("cells", ImageTexture.create_from_image(img))
	mat.set_shader_parameter("origin_cell", Vector2(room_rect.position))
	mat.set_shader_parameter("size_cells", Vector2(w, h))
	for m in range(min(materials.size(), 2)):
		var tm: TerrainMaterial = materials[m]
		if tm:
			mat.set_shader_parameter("fill%d" % m, tm.fill)
			mat.set_shader_parameter("fade%d" % m, tm.fade_tiles)


func _draw_fill(p: Dictionary) -> void:
	var r := Rect2(Vector2(room_rect.position * TILE), Vector2(room_rect.size * TILE))
	(p["fill"] as Node2D).draw_rect(r, Color.WHITE)


# --- The edges: bands laid along every exposed side --------------------------------

func _draw_edges(p: Dictionary) -> void:
	var cells: Dictionary = p["cells"]
	var solid: Callable = p["solid"]
	var canvas: Node2D = p["edges"]
	var list := cells.keys()
	for c in list:
		if not _skip.has(c):
			_draw_walls(canvas, cells, solid, c)
	for c in list:
		if not _skip.has(c):
			_draw_top(canvas, cells, solid, c)
	for c in list:
		if not _skip.has(c):
			_draw_under(canvas, cells, solid, c)
	# Last: the pale lip on walking lines, and the dark line outside wall faces.
	for c in list:
		if not _skip.has(c):
			_draw_lines(canvas, cells, solid, c)


func _mat(cells: Dictionary, c: Vector2i) -> TerrainMaterial:
	var i: int = cells.get(c, 0)
	return materials[i] if i < materials.size() else null


func _run(cells: Dictionary, c: Vector2i, step: Vector2i) -> int:
	var n := 0
	var p := c
	while n < MAX_DEPTH and cells.has(p):
		n += 1
		p += step
	return n


func _draw_walls(canvas: Node2D, cells: Dictionary, solid: Callable, c: Vector2i) -> void:
	var m := _mat(cells, c)
	if not m or not m.wall_band:
		return
	var p := Vector2(c * TILE)
	var bw := m.wall_face + 1
	var sy := float(posmod(c.y * TILE, m.wall_band.get_height()))
	if not solid.call(c + Vector2i.RIGHT):
		var depth: float = min(bw, _run(cells, c, Vector2i.LEFT) * TILE)
		canvas.draw_texture_rect_region(m.wall_band,
			Rect2(p.x + TILE - depth, p.y, depth, TILE), Rect2(bw - depth, sy, depth, TILE))
	if not solid.call(c + Vector2i.LEFT):
		var depth: float = min(bw, _run(cells, c, Vector2i.RIGHT) * TILE)
		# Negative width mirrors the band so its face lands on the cell's left edge.
		canvas.draw_texture_rect_region(m.wall_band,
			Rect2(p.x + depth, p.y, -depth, TILE), Rect2(bw - depth, sy, depth, TILE))


func _draw_top(canvas: Node2D, cells: Dictionary, solid: Callable, c: Vector2i) -> void:
	if solid.call(c + Vector2i.UP):
		return
	var m := _mat(cells, c)
	if not m or not m.top_band:
		return
	var p := Vector2(c * TILE)
	var thick := _run(cells, c, Vector2i.DOWN) * TILE
	var below: float = m.top_band.get_height() - m.top_line
	var bottom := c + Vector2i(0, thick / TILE)
	# The band gives the lip and the surface; the fill below gives the depth, so the
	# band stops while it is still lit (its own dark tail would make a stripe).
	below = min(below, m.top_lit)
	if thick < MAX_DEPTH * TILE and not solid.call(bottom):  # a thin mass: leave room for its underside
		below = min(below, thick - min(m.under_line, thick * 0.5))
	var sx := float(posmod(c.x * TILE, m.top_band.get_width()))
	canvas.draw_texture_rect_region(m.top_band,
		Rect2(p.x, p.y - m.top_line, TILE, m.top_line + below), Rect2(sx, 0, TILE, m.top_line + below))


func _draw_under(canvas: Node2D, cells: Dictionary, solid: Callable, c: Vector2i) -> void:
	if solid.call(c + Vector2i.DOWN):
		return
	var m := _mat(cells, c)
	if not m or not m.under_band:
		return
	var p := Vector2(c * TILE)
	var thick := _run(cells, c, Vector2i.UP) * TILE
	var above: float = m.under_line
	if thick < MAX_DEPTH * TILE:
		above = min(above, thick * 0.5)
	var hang: float = m.under_band.get_height() - m.under_line
	var sx := float(posmod(c.x * TILE, m.under_band.get_width()))
	canvas.draw_texture_rect_region(m.under_band,
		Rect2(p.x, p.y + TILE - above, TILE, above + hang), Rect2(sx, m.under_line - above, TILE, above + hang))


func _draw_lines(canvas: Node2D, cells: Dictionary, solid: Callable, c: Vector2i) -> void:
	var m := _mat(cells, c)
	if not m:
		return
	var p := Vector2(c * TILE)
	if m.lip_color.a > 0.0 and not solid.call(c + Vector2i.UP):
		canvas.draw_rect(Rect2(p.x, p.y, TILE, 1), m.lip_color)
	if m.outline_color.a > 0.0:
		if not solid.call(c + Vector2i.RIGHT):
			canvas.draw_rect(Rect2(p.x + TILE, p.y, 1, TILE), m.outline_color)
		if not solid.call(c + Vector2i.LEFT):
			canvas.draw_rect(Rect2(p.x - 1, p.y, 1, TILE), m.outline_color)
