@tool
class_name MoatWater
extends Node2D
## Deep, dark water. Kleo can't swim until she has the Deep-Glow Breath, so
## falling in lifts her back to safe ground. The surface mirrors the world above.

@export var size := Vector2(384, 96):
	set(v):
		size = v
		_layout()

@onready var area: Area2D = $Area
@onready var shape: CollisionShape2D = $Area/Shape
@onready var surface: ColorRect = $Surface


func _ready() -> void:
	_layout()
	if Engine.is_editor_hint():
		return
	area.body_entered.connect(_on_body_entered)


func _layout() -> void:
	if not is_inside_tree() or not has_node("Surface"):
		return
	$Surface.size = size
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, size.y - 10.0)
	$Area/Shape.shape = rect
	$Area/Shape.position = Vector2(size.x * 0.5, size.y * 0.5 + 5.0)


func _on_body_entered(body: Node) -> void:
	if body is Kleo:
		body.enter_water()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not surface.material:
		return
	# Where the surface sits on screen, for the reflection.
	var vp := get_viewport().get_visible_rect().size
	var screen_y := (get_global_transform_with_canvas() * Vector2.ZERO).y
	surface.material.set_shader_parameter("surface_uv_y", screen_y / vp.y)
	surface.material.set_shader_parameter("height_px", size.y)
