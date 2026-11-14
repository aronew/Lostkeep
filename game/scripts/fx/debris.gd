class_name Debris
extends Sprite2D
## A piece of something broken: it flies, tumbles, bounces off the ground it
## lands on, settles and fades. It tumbles by flipping, never by rotating, so
## its pixels stay square.

const GRAVITY := 720.0
const WORLD := 1  # physics layer of the rock

var velocity := Vector2.ZERO
var life := 1.6

var _t := 0.0
var _flip_t := 0.0
var _resting := false
var _half_h := 4.0
var _query := PhysicsPointQueryParameters2D.new()


func _ready() -> void:
	_half_h = region_rect.size.y * 0.5
	_query.collision_mask = WORLD
	_query.collide_with_bodies = true


func _physics_process(delta: float) -> void:
	_t += delta
	if not _resting:
		velocity.y = min(velocity.y + GRAVITY * delta, 420.0)
		var next := global_position + velocity * delta
		if velocity.y > 0.0 and _solid_at(next + Vector2(0, _half_h)):
			# Land on the surface: step up to it, then bounce or settle.
			while _solid_at(next + Vector2(0, _half_h)) and next.y > global_position.y - 16.0:
				next.y -= 1.0
			if velocity.y < 90.0:
				_resting = true
				velocity = Vector2.ZERO
			else:
				velocity = Vector2(velocity.x * 0.45, -velocity.y * 0.32)
		if _solid_at(next + Vector2(signf(velocity.x) * region_rect.size.x * 0.5, 0)):
			velocity.x = -velocity.x * 0.4
			next.x = global_position.x
		global_position = next
		_flip_t += delta
		if _flip_t > 0.07 and absf(velocity.x) > 20.0:
			_flip_t = 0.0
			if flip_h == flip_v:
				flip_h = not flip_h
			else:
				flip_v = not flip_v
	if _t > life - 0.4:
		modulate.a = max(0.0, (life - _t) / 0.4)
	if _t >= life:
		queue_free()


func _solid_at(p: Vector2) -> bool:
	_query.position = p
	return not get_world_2d().direct_space_state.intersect_point(_query, 1).is_empty()
