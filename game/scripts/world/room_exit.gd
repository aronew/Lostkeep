class_name RoomExit
extends Area2D
## A way out of the room: a strip just inside the room's edge, across a door's
## opening. Kleo walking into it goes to `target_door` in `target_scene`.

@export_file("*.tscn") var target_scene := ""
@export var target_door := ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # the player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Kleo and target_scene != "":
		Game.go_to(target_scene, target_door, body)
