@tool
class_name TerrainSkin
extends Node2D
## Paints terrain art onto the black-box collision.
##
## The collision is a TileMapLayer: every solid cell is one black tile, and the
## tile's atlas column picks the material (0 = earth, 1 = stone). This node reads
## those cells and paints along every exposed edge: walking tops, ceilings and
## walls, each from its material's bands. The inside of every mass fades to the
## void colour, so the black box itself becomes the shadow.
##
## Edit the room by painting or erasing tiles; the skin follows. Keep this node
## at the same position as the TileMapLayer.

const TILE := 16
const MAX_DEPTH := 5  # tiles looked through when measuring how thick a mass is

## The collision tiles this skin paints.
@export var solid_layer: TileMapLayer:
	set(v):
		solid_layer = v
		_connect_layer()
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
## Cells covered by hand-placed art (islands, bridges, plates): no skin there.
@export var skip_regions: Array[Rect2i] = []:
	set(v):
		skip_regions = v
		_queue_rebuild()
## Turn off to see the bare black box (F1 in game).
@export var skin_visible := true:
	set(v):
		skin_visible = v
		if _fill:
			_fill.visible = v
			_edges.visible = v
		# In the game the black tiles are only collision; they show in box view.
		if solid_layer and not Engine.is_editor_hint():
			solid_layer.visible = not v

var _solid := {}  # Vector2i -> material index
var _skip := {}  # Vector2i -> true
var _fill: Node2D
var _edges: Node2D
var _fill_mat: ShaderMaterial
var _rebuild_queued := false


func _ready() -> void:
	add_to_group("box_view")
	_fill = Node2D.new()
	_fill.name = "Fill"
	add_child(_fill, false, Node.INTERNAL_MODE_FRONT)
	_edges = Node2D.new()
	_edges.name = "Edges"
	_edges.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(_edges, false, Node.INTERNAL_MODE_FRONT)
	_fill_mat = ShaderMaterial.new()
	_fill_mat.shader = preload("res://shaders/terrain_fill.gdshader")
	_fill.material = _fill_mat
	_fill.draw.connect(_draw_fill)
	_edges.draw.connect(_draw_edges)
	skin_visible = skin_visible
	_connect_layer()
	rebuild()


func set_box_view(on: bool) -> void:
	skin_visible = not on


func _connect_layer() -> void:
	if solid_layer and solid_layer.has_signal("changed") and not solid_layer.changed.is_connected(_queue_rebuild):
		solid_layer.changed.connect(_queue_rebuild)


func _queue_rebuild() -> void:
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	(func() -> void:
		_rebuild_queued = false
		rebuild()).call_deferred()


## Re-read the collision tiles and repaint.
func rebuild() -> void:
	if not _fill:
		return
	_solid.clear()
	_skip.clear()
	if solid_layer:
		for c in solid_layer.get_used_cells():
			_solid[c] = solid_layer.get_cell_atlas_coords(c).x
	for r in skip_regions:
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				_skip[Vector2i(x, y)] = true
	_build_cell_texture()
	_fill.queue_redraw()
	_edges.queue_redraw()


func is_solid(c: Vector2i) -> bool:
	return _solid.has(c) or not room_rect.has_point(c)


# --- The fill: one shader pass over the whole room --------------------------

func _build_cell_texture() -> void:
	var w := room_rect.size.x
	var h := room_rect.size.y
	if w <= 0 or h <= 0:
		return
	# Distance to open air, in tiles, by breadth-first search from every
	# solid cell that touches open air.
	var dist := {}
	var frontier: Array[Vector2i] = []
	for c in _solid:
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not is_solid(c + d):
				dist[c] = 1
				frontier.append(c)
				break
	var i := 0
	while i < frontier.size():
		var c: Vector2i = frontier[i]
		i += 1
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if _solid.has(n) and not dist.has(n):
				dist[n] = dist[c] + 1
				frontier.append(n)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for c in _solid:
		var local: Vector2i = c - room_rect.position
		if local.x < 0 or local.y < 0 or local.x >= w or local.y >= h:
			continue
		var dd: float = min(dist.get(c, 31), 31)
		var painted := 0.0 if _skip.has(c) else 1.0
		img.set_pixel(local.x, local.y, Color(dd / 32.0, float(_solid[c]) / 8.0, 0.0, painted))
	var tex := ImageTexture.create_from_image(img)
	_fill_mat.set_shader_parameter("cells", tex)
	_fill_mat.set_shader_parameter("origin_cell", Vector2(room_rect.position))
	_fill_mat.set_shader_parameter("size_cells", Vector2(w, h))
	for m in range(min(materials.size(), 2)):
		var mat: TerrainMaterial = materials[m]
		if mat:
			_fill_mat.set_shader_parameter("fill%d" % m, mat.fill)
			_fill_mat.set_shader_parameter("fade%d" % m, mat.fade_tiles)


func _draw_fill() -> void:
	var r := Rect2(Vector2(room_rect.position * TILE), Vector2(room_rect.size * TILE))
	_fill.draw_rect(r, Color.WHITE)


# --- The edges: bands laid along every exposed side --------------------------

func _draw_edges() -> void:
	var cells := _solid.keys()
	for c in cells:
		if not _skip.has(c):
			_draw_walls(c)
	for c in cells:
		if not _skip.has(c):
			_draw_top(c)
	for c in cells:
		if not _skip.has(c):
			_draw_under(c)


func _mat(c: Vector2i) -> TerrainMaterial:
	var i: int = _solid.get(c, 0)
	return materials[i] if i < materials.size() else null


func _run(c: Vector2i, step: Vector2i) -> int:
	var n := 0
	var p := c
	while n < MAX_DEPTH and _solid.has(p):
		n += 1
		p += step
	return n


func _draw_walls(c: Vector2i) -> void:
	var m := _mat(c)
	if not m or not m.wall_band:
		return
	var p := Vector2(c * TILE)
	var bw := m.wall_face + 1
	var sy := float(posmod(c.y * TILE, m.wall_band.get_height()))
	if not is_solid(c + Vector2i.RIGHT):
		var depth: float = min(bw, _run(c, Vector2i.LEFT) * TILE)
		_edges.draw_texture_rect_region(m.wall_band,
			Rect2(p.x + TILE - depth, p.y, depth, TILE), Rect2(bw - depth, sy, depth, TILE))
	if not is_solid(c + Vector2i.LEFT):
		var depth: float = min(bw, _run(c, Vector2i.RIGHT) * TILE)
		# Negative width mirrors the band so its face lands on the cell's left edge.
		_edges.draw_texture_rect_region(m.wall_band,
			Rect2(p.x + depth, p.y, -depth, TILE), Rect2(bw - depth, sy, depth, TILE))


func _draw_top(c: Vector2i) -> void:
	if is_solid(c + Vector2i.UP):
		return
	var m := _mat(c)
	if not m or not m.top_band:
		return
	var p := Vector2(c * TILE)
	var thick := _run(c, Vector2i.DOWN) * TILE
	var below: float = m.top_band.get_height() - m.top_line
	if thick < MAX_DEPTH * TILE:  # a thin mass: leave room for its underside
		below = min(below, thick - min(m.under_line, thick * 0.5))
	var sx := float(posmod(c.x * TILE, m.top_band.get_width()))
	_edges.draw_texture_rect_region(m.top_band,
		Rect2(p.x, p.y - m.top_line, TILE, m.top_line + below), Rect2(sx, 0, TILE, m.top_line + below))


func _draw_under(c: Vector2i) -> void:
	if is_solid(c + Vector2i.DOWN):
		return
	var m := _mat(c)
	if not m or not m.under_band:
		return
	var p := Vector2(c * TILE)
	var thick := _run(c, Vector2i.UP) * TILE
	var above: float = m.under_line
	if thick < MAX_DEPTH * TILE:
		above = min(above, thick * 0.5)
	var hang: float = m.under_band.get_height() - m.under_line
	var sx := float(posmod(c.x * TILE, m.under_band.get_width()))
	_edges.draw_texture_rect_region(m.under_band,
		Rect2(p.x, p.y + TILE - above, TILE, above + hang), Rect2(sx, m.under_line - above, TILE, above + hang))
