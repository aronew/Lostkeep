class_name CameraRig
extends Camera2D
## A calm platformer camera. It never moves on its own:
## - Horizontally, Kleo moves freely inside a small window; the camera follows
##   only when she pushes its edge, so it moves exactly as she does.
## - It looks ahead only while she keeps running one way, at a steady pace, and
##   holds that look-ahead when she stops or turns to fight (no swinging).
## - Vertically, it holds the height of the floor she last stood on. Jumps don't
##   move it; it follows if she rises far above or falls below, and eases to a
##   new floor once she lands there.
## - It updates on the physics tick, with Kleo, in whole pixels, so she never
##   shimmers against the world.

@export var target: Node2D
## Half-width of the window she moves in without the camera following (px).
@export var window_x := 12
## How far ahead the view settles while she keeps running one way (px).
@export var lookahead := 32
## How fast the look-ahead shifts while she runs (px per second).
@export var lookahead_speed := 40.0
## How long she must keep running one way before the look-ahead shifts (s).
@export var lookahead_delay := 0.3
## Where her feet sit relative to the screen centre (negative: below centre).
@export var vertical_offset := -58
## She can rise this far above the last floor (a jump) before the camera follows.
@export var band_up := 76.0
## She can drop this far below the last floor before the camera follows down.
@export var band_down := 20.0
## How quickly the view settles on a new floor's height after she lands.
@export var floor_ease := 7.0
## Shake strength at full trauma (px). Kept small: impacts, not earthquakes.
@export var max_shake := 3.0

var _x := 0.0
var _y := 0.0
var _look := 0.0
var _run_time := 0.0
var _run_dir := 0
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
	_look = 0.0
	_run_time = 0.0
	_apply()


func add_trauma(amount: float) -> void:
	_trauma = min(1.0, _trauma + amount)


func _physics_process(delta: float) -> void:
	if not target:
		return
	var p := target.global_position
	var grounded := true
	var running := false
	var face := 1
	if target is Kleo:
		var k := target as Kleo
		grounded = k.is_on_floor() or k.state == Kleo.State.LEDGE_HANG or k.state == Kleo.State.LEDGE_CLIMB
		running = absf(k.velocity.x) > k.run_speed * 0.8 and k.state == Kleo.State.NORMAL
		face = k.facing

	# Horizontal window: follow only when she pushes its edge.
	if p.x > _x + window_x:
		_x = p.x - window_x
	elif p.x < _x - window_x:
		_x = p.x + window_x

	# Look-ahead: only while she keeps running the same way.
	var dir := face if running else 0
	if dir != 0 and dir == _run_dir:
		_run_time += delta
	else:
		_run_time = 0.0
		_run_dir = dir
	if _run_time > lookahead_delay:
		_look = move_toward(_look, float(_run_dir * lookahead), lookahead_speed * delta)

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
	global_position = Vector2(_x + roundf(_look), _y + vertical_offset).round()
