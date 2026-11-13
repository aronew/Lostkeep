class_name CameraRig
extends Camera2D
## A calm platformer camera. It never moves on its own and never moves faster
## than Kleo:
## - Horizontally, she moves inside a small window. As she moves out from its
##   centre the camera picks up speed smoothly, reaching her speed exactly at the
##   window's edge; it never moves when she is still, and never faster than her.
##   There is no look-ahead: a camera that runs ahead of her slides the whole
##   world past her.
## - Vertically, it holds the height of the floor she last stood on. Jumps don't
##   move it; it follows if she rises far above or falls below, and eases to a
##   new floor once she lands there.
## - At the room's edges it slows down smoothly over the last stretch instead of
##   stopping dead (`bounds`, set by the room).
## - It updates on the physics tick, with Kleo, in whole pixels, so she never
##   shimmers against the world.

const VIEW := Vector2(640, 360)

@export var target: Node2D
## Half-width of the window she moves in without the camera following (px).
@export var window_x := 16
## Where her feet sit relative to the screen centre (negative: below centre).
@export var vertical_offset := -58
## She can rise this far above the last floor (a jump) before the camera follows.
@export var band_up := 76.0
## She can drop this far below the last floor before the camera follows down.
@export var band_down := 20.0
## How quickly the view settles on a new floor's height after she lands.
@export var floor_ease := 7.0
## Over how many pixels the camera slows to a stop at the room's edges.
@export var edge_ease := 64.0
## Shake strength at full trauma (px). Kept small: impacts, not earthquakes.
@export var max_shake := 3.0

## The room, in pixels. The view stays inside it, easing in at the edges.
var bounds := Rect2()

var _x := 0.0
var _y := 0.0
var _last_px := 0.0
var _trauma := 0.0
var _t := 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	position_smoothing_enabled = false
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	process_physics_priority = 100  # after Kleo has moved this tick
	make_current()
	_noise.frequency = 0.9
	snap_to_target()


func snap_to_target() -> void:
	if not target:
		return
	_x = target.global_position.x
	_y = target.global_position.y
	_last_px = _x
	_apply()


func add_trauma(amount: float) -> void:
	_trauma = min(1.0, _trauma + amount)


func _physics_process(delta: float) -> void:
	if not target:
		return
	var p := target.global_position
	var grounded := true
	if target is Kleo:
		var k := target as Kleo
		grounded = k.is_on_floor() or k.state == Kleo.State.LEDGE_HANG or k.state == Kleo.State.LEDGE_CLIMB

	# Horizontal window: while she moves out from its centre, the camera follows a
	# growing share of her movement (none near the centre, all of it at the edge),
	# so it starts smoothly; she can never leave the window.
	var moved := p.x - _last_px
	_last_px = p.x
	var off := p.x - _x
	if moved * off > 0.0:
		_x += moved * smoothstep(0.3, 1.0, absf(off) / window_x)
	off = p.x - _x
	if absf(off) > window_x:
		_x = p.x - signf(off) * window_x

	# Vertical: hold the floor's height; follow outside the band; ease to new floors.
	if p.y < _y - band_up:
		_y = p.y + band_up
	elif p.y > _y + band_down and not grounded:
		_y = p.y - band_down
	if grounded and absf(p.y - _y) > 0.5:
		_y = lerp(_y, p.y, 1.0 - exp(-delta * floor_ease))
		if absf(p.y - _y) < 0.5:
			_y = p.y

	# Shake from impacts: whole pixels, decaying fast.
	_trauma = max(_trauma - delta * 2.4, 0.0)
	_t += delta * 60.0
	var s := _trauma * _trauma * max_shake
	offset = (Vector2(_noise.get_noise_2d(_t, 0.0), _noise.get_noise_2d(0.0, _t)) * s * 2.0).round()
	_apply()


func _apply() -> void:
	var c := Vector2(_x, _y + vertical_offset)
	if bounds.size != Vector2.ZERO:
		var lo := bounds.position + VIEW * 0.5
		var hi := bounds.end - VIEW * 0.5
		c.x = _soft_clamp(c.x, lo.x, hi.x, edge_ease)
		c.y = _soft_clamp(c.y, lo.y, hi.y, edge_ease * 0.75)
	global_position = c.round()


## Clamps `v` to [lo, hi], easing into each end over `m` pixels: the result
## follows `v` exactly until it is `m` from an end, then slows smoothly (same
## speed where the easing starts, approaching the end without ever stopping dead).
static func _soft_clamp(v: float, lo: float, hi: float, m: float) -> float:
	if hi <= lo:
		return (lo + hi) * 0.5
	m = minf(m, (hi - lo) * 0.5)
	if v < lo + m:
		return lo + m * exp((v - lo - m) / m)
	if v > hi - m:
		return hi - m * exp((hi - m - v) / m)
	return v
