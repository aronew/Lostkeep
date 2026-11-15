class_name Mossback
extends Node2D
## A Mossback: a mossy boulder on little legs, the gardens' gentle grazer and
## the game's first enemy. It ambles back and forth along its floor, stops to
## rest, and never chases. Walking into it earns a shove; it takes seven sword
## hits to put down.
##
## The node sits at its feet (the floor line). It walks between `left_x` and
## `right_x` (world px) and needs no physics body: its floor is flat.

@export var hits_to_kill := 7
@export var walk_speed := 16.0
@export var left_x := 0.0
@export var right_x := 0.0
## How hard a hit on it lands for Kleo's hit-stop and shake (props are 0.35).
@export var hit_weight := 0.8

@onready var art: Sprite2D = $Art
@onready var hurtbox: Area2D = $Hurtbox
@onready var touch: Area2D = $Touch

var hits := 0
var dir := 1
var dead := false
var _clock := 0.0
var _rest := 0.0
var _next_rest := 4.0
var _stun := 0.0
var _push := 0.0


func _ready() -> void:
	add_to_group("enemy")
	dir = 1 if (int(position.x) / 16) % 2 == 0 else -1
	_next_rest = 3.0 + fmod(position.x, 3.0)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_clock += delta
	if _stun > 0.0:
		_stun -= delta
		position.x = clampf(position.x + _push * delta, left_x, right_x)
		_push = move_toward(_push, 0.0, 260.0 * delta)
		art.frame = 5
	elif _rest > 0.0:
		_rest -= delta
		art.frame = 4
	else:
		position.x += dir * walk_speed * delta
		if position.x >= right_x:
			position.x = right_x
			dir = -1
		elif position.x <= left_x:
			position.x = left_x
			dir = 1
		art.frame = int(_clock * 6.0) % 4
		_next_rest -= delta
		if _next_rest <= 0.0:
			_rest = 1.6
			_next_rest = 4.0 + fmod(_clock, 2.5)
	art.flip_h = dir < 0
	# Bumping into it shoves her back. It doesn't mean it.
	if _stun <= 0.0:
		for body in touch.get_overlapping_bodies():
			if body is Kleo:
				body.hurt(1 if body.global_position.x >= global_position.x else -1)


func take_hit(hit: Dictionary) -> bool:
	if dead:
		return false
	hits += 1
	var from := int(hit.get("dir", 1))
	var mat := art.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash", 1.0)
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.14)
	Fx.burst(self, hit.get("pos", global_position + Vector2(0, -10)), Color(0.5, 0.62, 0.24), 7, 100.0)
	if hits >= hits_to_kill:
		_die(from)
		return true
	_stun = 0.32
	_push = from * 70.0
	_rest = 0.0
	dir = -from  # it turns to look at what hit it
	return true


func _die(from: int) -> void:
	dead = true
	hurtbox.set_deferred("monitorable", false)
	touch.set_deferred("monitoring", false)
	art.frame = 5
	Fx.burst(self, global_position + Vector2(0, -10), Color(0.5, 0.62, 0.24), 16, 150.0)
	Fx.burst(self, global_position + Vector2(0, -8), Color(0.42, 0.32, 0.52), 14, 120.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position", position + Vector2(from * 14.0, -10.0), 0.22).set_ease(Tween.EASE_OUT)
	tw.tween_property(art, "scale", Vector2(1.3, 0.2), 0.22).set_ease(Tween.EASE_IN)
	tw.tween_property(art, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(queue_free)
