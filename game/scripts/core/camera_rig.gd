class_name CameraRig
extends Camera2D
## Follows Kleo: it looks ahead in the direction she faces, holds its height
## while she jumps (so the world doesn't bob), and shakes on impacts.
## The room sets the limits.

@export var target: Node2D
## How far ahead of her the camera looks, in pixels.
@export var lookahead := 44.0
## Raise the view so more of what's ahead and above shows.
@export var vertical_offset := -58.0
@export var follow_speed := 6.5
@export var vertical_speed := 4.0
## Shake strength at full trauma, in pixels.
@export var max_shake := 7.0

var _look := 0.0
var _track_y := 0.0
var _trauma := 0.0
var _t := 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	position_smoothing_enabled = false
	make_current()
	_noise.frequency = 0.9
	snap_to_target()


func snap_to_target() -> void:
	if target:
		_track_y = target.global_position.y
		global_position = Vector2(target.global_position.x, _track_y + vertical_offset)


func add_trauma(amount: float) -> void:
	_trauma = min(1.0, _trauma + amount)


func _process(delta: float) -> void:
	if not target:
		return
	var face := 1
	var moving := false
	var grounded := true
	if target is Kleo:
		face = target.facing
		moving = absf(target.velocity.x) > 30.0
		grounded = target.is_on_floor() or target.state == Kleo.State.LEDGE_HANG
	_look = lerp(_look, face * lookahead * (1.0 if moving else 0.55), 1.0 - exp(-delta * 2.2))
	var ty := target.global_position.y
	# Platformer framing: follow the height only on the ground, or when she
	# leaves the band around the last floor height.
	if grounded or ty > _track_y + 36.0 or ty < _track_y - 84.0:
		_track_y = lerp(_track_y, ty, 1.0 - exp(-delta * vertical_speed * (1.0 if grounded else 1.6)))
	var goal := Vector2(target.global_position.x + _look, _track_y + vertical_offset)
	global_position = global_position.lerp(goal, 1.0 - exp(-delta * follow_speed))
	# Trauma shake: the square makes small hits subtle and big ones strong.
	_trauma = max(_trauma - delta * 1.6, 0.0)
	_t += delta * 60.0
	var s := _trauma * _trauma * max_shake
	offset = Vector2(_noise.get_noise_2d(_t, 0.0), _noise.get_noise_2d(0.0, _t)) * s * 2.0
