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
const FOOT := 22.0   # px a wall's face runs on below a floor it stands on (the soil's depth)
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
	# Tops first, then walls over them: at a corner the rock face runs straight
	# down from the grass, instead of the soil band ending in a ragged stub.
	for c in list:
		if not _skip.has(c):
			_draw_top(canvas, cells, solid, c)
	for c in list:
		if not _skip.has(c):
			_draw_walls(canvas, cells, solid, c)
	for c in list:
		if not _skip.has(c):
			_draw_under(canvas, cells, solid, c)
	# Painted corners over the bands where a top or a ceiling meets a face.
	for c in list:
		if not _skip.has(c):
			_draw_corners(canvas, cells, solid, c)
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


## How far (px) a wall band may reach into the mass from its face, going `step`.
## A column open on both sides gives each face half its width, so the two bands
## meet in the middle instead of painting over each other.
func _wall_room(cells: Dictionary, solid: Callable, c: Vector2i, step: Vector2i) -> float:
	var n := _run(cells, c, step)
	if n < MAX_DEPTH and not solid.call(c + step * n):
		return n * TILE * 0.5
	return n * TILE


## How far (px) a corner may reach from the corner along its face, going `step`:
## while the face stays open. A face that ends because the mass ends (a thin
## column or slab) gives half, so the corners at both ends meet in the middle.
func _face_room(cells: Dictionary, solid: Callable, c: Vector2i, side: Vector2i, step: Vector2i) -> float:
	var n := 0
	var p := c
	while n < MAX_DEPTH and cells.has(p) and not solid.call(p + side):
		n += 1
		p += step
	if n < MAX_DEPTH and not cells.has(p) and not solid.call(p):
		return n * TILE * 0.5
	return n * TILE


func _draw_corners(canvas: Node2D, cells: Dictionary, solid: Callable, c: Vector2i) -> void:
	var m := _mat(cells, c)
	if not m:
		return
	for side in [Vector2i.RIGHT, Vector2i.LEFT]:
		if solid.call(c + side):
			if m.inner_under and not solid.call(c + Vector2i.DOWN) and solid.call(c + side + Vector2i.DOWN):
				_inner(canvas, cells, c, side, m, m.inner_under, m.inner_under_anchor, false)
			if m.inner_top and not solid.call(c + Vector2i.UP) and solid.call(c + side + Vector2i.UP):
				_inner(canvas, cells, c, side, m, m.inner_top, m.inner_top_anchor, true)
			# A ceiling meeting a wall that runs down to the floor: the arcade ends
			# on a pier set against that wall.
			if m.corner_under and m.corner_under_inner and not solid.call(c + Vector2i.DOWN) \
					and solid.call(c + side + Vector2i.DOWN) and _reaches_floor(solid, c, m.corner_under_reach):
				_corner(canvas, cells, solid, c, side, m.corner_under, m.corner_under_anchor, false, true)
			continue
		if m.corner_top and not solid.call(c + Vector2i.UP):
			_corner(canvas, cells, solid, c, side, m.corner_top, m.corner_top_anchor, true)
		if m.corner_under and not solid.call(c + Vector2i.DOWN) and _reaches_floor(solid, c, m.corner_under_reach):
			_corner(canvas, cells, solid, c, side, m.corner_under, m.corner_under_anchor, false)


## A painted inner corner at cell c's edge toward `side`, where c's ceiling
## (or walking line, if `top`) meets the wall on that side. The piece is painted
## with its wall on the left of the notch, so it is mirrored for a wall on the right.
func _inner(canvas: Node2D, cells: Dictionary, c: Vector2i, side: Vector2i, m: Resource,
		tex: Texture2D, anchor: Vector2, top: bool) -> void:
	var p := Vector2(c * TILE)
	var nx: float = p.x + (TILE if side == Vector2i.RIGHT else 0.0)
	var ny: float = p.y + (0.0 if top else TILE)
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	# Into the slab (up from a ceiling, down from a floor): the share its band takes.
	var thick := _run(cells, c, Vector2i.DOWN if top else Vector2i.UP) * TILE
	var src: Rect2
	var y0: float
	if top:
		var down: float = h - anchor.y
		if thick < MAX_DEPTH * TILE:
			down = min(down, thick - min(m.under_line, thick * 0.5))
		src = Rect2(0, 0, w, anchor.y + down)
		y0 = ny - anchor.y
	else:
		var up: float = anchor.y
		if thick < MAX_DEPTH * TILE:
			up = min(up, max(thick * 0.5, thick - 24.0))
		src = Rect2(0, anchor.y - up, w, up + h - anchor.y)
		y0 = ny - up
	var dest := Rect2(nx - anchor.x, y0, w, src.size.y)
	if side == Vector2i.RIGHT:
		dest = Rect2(nx - (w - anchor.x), y0, -w, src.size.y)
	canvas.draw_texture_rect_region(tex, dest, src)


## True if a standing piece reaching `reach` px below this ceiling cell lands on
## the floor (within 16 px), or if the piece hangs freely (reach 0).
func _reaches_floor(solid: Callable, c: Vector2i, reach: float) -> bool:
	if reach <= 0.0:
		return true
	var n := 0
	while n < 12 and not solid.call(c + Vector2i.DOWN * (n + 1)):
		n += 1
	return absf(n * TILE - reach) <= 16.0


func _corner(canvas: Node2D, cells: Dictionary, solid: Callable, c: Vector2i, side: Vector2i,
		tex: Texture2D, anchor: Vector2, top: bool, inner := false) -> void:
	var p := Vector2(c * TILE)
	# The corner point: the cell's outer edge, at its top (walking line) or bottom (ceiling).
	var cx: float = p.x + (TILE if side == Vector2i.RIGHT else 0.0)
	var cy: float = p.y + (0.0 if top else TILE)
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	# Inward along the surface (the top or the ceiling) and along the face.
	var inward: float = min(anchor.x, _wall_room(cells, solid, c, -side))
	var along := _face_room(cells, solid, c, side, Vector2i.DOWN if top else Vector2i.UP)
	if inner:
		along = anchor.y  # no face above to clip to: the masonry above sits in the slab
	# A thin slab, for a material that asks for it (thin_wall_depth): each corner
	# takes only the share of the slab its band takes
	# (see _draw_top and _draw_under), so a ceiling corner's dark inside never
	# paints over the floor's lit bricks above it, and the reverse.
	var m := _mat(cells, c)
	var thick := _run(cells, c, Vector2i.DOWN if top else Vector2i.UP) * TILE
	var share := INF
	if m and m.thin_wall_depth > 0 and thick < MAX_DEPTH * TILE and not inner:
		if top:
			share = thick - min(m.under_line, thick * 0.5)
		else:
			share = max(thick * 0.5, thick - 24.0)
		# Its dark inside would show against the bands' lit bricks: only the
		# corner's face stones and the brick beside them.
		inward = min(inward, float(m.thin_wall_depth + 6))
	var sx := anchor.x - inward
	var sw := w - sx
	var src: Rect2
	var dy: float
	if top:
		var down: float = min(min(h - anchor.y, along), share)
		src = Rect2(sx, 0, sw, anchor.y + down)
		dy = cy - anchor.y
	else:
		var up: float = min(min(anchor.y, along), share)
		src = Rect2(sx, anchor.y - up, sw, up + h - anchor.y)
		dy = cy - up
	var dest := Rect2(cx - inward, dy, sw, src.size.y)
	if side == Vector2i.LEFT:
		# Mirrored: a negative width flips the piece within [x, x + |width|], so the
		# rect starts where the flipped piece's outer end lands and its face meets cx.
		dest = Rect2(cx + inward - sw, dy, -sw, src.size.y)
	canvas.draw_texture_rect_region(tex, dest, src)


func _draw_walls(canvas: Node2D, cells: Dictionary, solid: Callable, c: Vector2i) -> void:
	var m := _mat(cells, c)
	if not m or not m.wall_band:
		return
	var p := Vector2(c * TILE)
	var bw := m.wall_face + 1
	# Columns past the face: stones standing proud of the collision, into the air.
	var over := m.wall_band.get_width() - bw
	var bh := m.wall_band.get_height()
	# A wall standing on a floor sinks into it: its face runs on below the walking
	# line as deep as the floor's soil, so the floor's band doesn't end in a cut.
	var foot := 0.0
	if solid.call(c + Vector2i.DOWN):
		foot = FOOT
	for side in [Vector2i.RIGHT, Vector2i.LEFT]:
		if solid.call(c + side):
			continue
		var depth: float = min(bw, _wall_room(cells, solid, c, -side))
		# A thin slab (its floor and ceiling bands meet inside it): the wall's
		# inward fade would paint over their lit bricks, so only its face stones show.
		var tall := _run(cells, c, Vector2i.UP) + _run(cells, c, Vector2i.DOWN) - 1
		if m.thin_wall_depth > 0 and tall < MAX_DEPTH:
			depth = min(depth, float(m.thin_wall_depth))
		var f := foot if solid.call(c + side + Vector2i.DOWN) else 0.0
		if m.inner_top:
			f = 0.0  # the inner floor corner paints the wall's foot
		# A ceiling over the open side meets this wall: the face runs on up past the
		# ceiling line as high as the ceiling's band, so the band ends against it.
		var head := 0.0
		if solid.call(c + Vector2i.UP) and solid.call(c + side + Vector2i.UP) and not m.inner_under:
			head = float(m.under_line)
		# Left-facing faces read the band half a repeat further on, so the two faces
		# of a pier never mirror each other.
		var phase := 0 if side == Vector2i.RIGHT else bh / 2
		var sy := float(posmod(c.y * TILE + phase - int(head), bh))
		var src := Rect2(bw - depth, sy, depth + over, head + TILE + f)
		if side == Vector2i.RIGHT:
			canvas.draw_texture_rect_region(m.wall_band,
				Rect2(p.x + TILE - depth, p.y - head, depth + over, head + TILE + f), src)
		else:
			# A negative width draws the region flipped within [x, x + |width|] (Godot
			# keeps the rect's x), so the rect starts at the proud stones' outer end
			# and the face lands on the cell's left edge.
			canvas.draw_texture_rect_region(m.wall_band,
				Rect2(p.x - over, p.y - head, -(depth + over), head + TILE + f), src)


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
		# A thin slab: the ceiling band takes what the floor's soil band (about
		# 24 px) leaves, or half the slab, whichever is more.
		above = min(above, max(thick * 0.5, thick - 24.0))
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
