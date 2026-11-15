class_name Pickup
extends Area2D
## A bead of Resin, the currency (a stand-in name and sprite): it hangs in the
## air, bobbing and turning; when Kleo comes near it drifts to her, and touching
## it adds its value to the count. Once taken it stays taken (Game.flags).

@export var value := 1
## A name in Game.flags: set when taken, so it never comes back.
@export var flag := ""

const MAGNET := 30.0  # px: within this it drifts to her
const FRAMES := 6

var _t := 0.0
var _home := Vector2.ZERO
var _taken := false
var _target: Node2D = null

@onready var art: Sprite2D = $Art


func _ready() -> void:
	if flag != "" and Game.flags.has(flag):
		queue_free()
		return
	collision_layer = 0
	collision_mask = 2  # the player
	body_entered.connect(_on_body_entered)
	_home = position
	_t = randf() * TAU


func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	art.frame = int(_t * 8.0) % FRAMES
	if _target == null:
		for k in get_tree().get_nodes_in_group("player"):
			if (k as Node2D).global_position.distance_to(global_position) < MAGNET:
				_target = k
	if _target:
		var to: Vector2 = _target.global_position + Vector2(0, -14) - global_position
		global_position += to.normalized() * min(to.length(), 220.0 * delta)
	else:
		position = _home + Vector2(0, roundf(sin(_t * 2.6) * 2.0))


func _on_body_entered(body: Node) -> void:
	if _taken or not (body is Kleo):
		return
	_taken = true
	if flag != "":
		Game.flags[flag] = true
	Game.add_currency(value)
	Fx.burst(self, global_position, Color(1.0, 0.8, 0.4), 8, 70.0)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.12)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)
