class_name Interactable
extends Area2D
## Something Kleo can use (E, C, gamepad Y, or up). A small amber diamond
## floats above it while she is close enough.

@export var prompt_offset := Vector2(0, -44)

var _near := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 32  # "interact"
	collision_mask = 2  # the player
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body is Kleo:
		_near = true


func _on_body_exited(body: Node) -> void:
	if body is Kleo:
		_near = false
		queue_redraw()


func can_interact(_kleo: Node) -> bool:
	return true


func interact(_kleo: Node) -> void:
	pass


func _process(delta: float) -> void:
	if _near:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if not _near or not can_interact(null):
		return
	var p := prompt_offset + Vector2(0, round(sin(_t * 4.0) * 1.5))
	var amber := Color(0.95, 0.69, 0.29)
	var light := Color(1.0, 0.9, 0.6)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -3), p + Vector2(3, 0), p + Vector2(0, 3), p + Vector2(-3, 0)]), amber)
	draw_rect(Rect2(p + Vector2(-1, -1), Vector2(1, 1)), light)
