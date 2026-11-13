class_name PracticePost
extends Node2D
## A practice post in the Ironbark Guard's training yard: something to swing at.
## It flashes, rocks and sheds wood chips when hit.

@onready var art: Node2D = $Art
@onready var hurtbox: Area2D = $Hurtbox

var hits := 0
var _shake := 0.0


func take_hit(hit: Dictionary) -> bool:
	hits += 1
	var power: int = hit.get("power", 1)
	_shake = 2.0 + power
	var mat := art.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash", 1.0)
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.12)
	Fx.burst(self, hit.get("pos", global_position + Vector2(0, -20)), Color(0.66, 0.46, 0.3), 6 + power * 3, 90.0 + power * 30.0)
	return true


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = max(_shake - delta * 24.0, 0.0)
		art.position.x = round(sin(Time.get_ticks_msec() * 0.09) * _shake)
	else:
		art.position.x = 0.0
