class_name SecretCover
extends Node2D
## Hides a secret space behind what looks like unbroken wall. It has no
## collision: Kleo can simply walk (or climb) through. Once she is inside the
## `Trigger` area, the cover fades and stays gone.

## A name in Game.flags, so the secret stays found when the room is left.
@export var flag := ""

@onready var trigger: Area2D = $Trigger

var found := false


func _ready() -> void:
	add_to_group("box_view")
	trigger.collision_layer = 0
	trigger.collision_mask = 2  # the player
	trigger.body_entered.connect(_on_body_entered)
	if flag != "" and Game.flags.has(flag):
		found = true
		modulate.a = 0.0


func _on_body_entered(body: Node) -> void:
	if found or not (body is Kleo):
		return
	found = true
	if flag != "":
		Game.flags[flag] = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_OUT)


func set_box_view(on: bool) -> void:
	visible = not on
