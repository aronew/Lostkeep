class_name SecretCover
extends Node2D
## Hides a secret space behind what looks like unbroken wall. It has no
## collision: Kleo can simply walk (or climb) through. While she is inside the
## `Trigger` area the cover fades away and the hidden room shows; once she
## steps back out it fades in again, so the wall reads as unbroken rock from
## outside every time (the creative lead: "once you leave it it should go back
## to hidden").

## A name in Game.flags, set the first time the secret is found (for the map
## and the rewards). It no longer keeps the wall open.
@export var flag := ""

## Seconds to lift the cover on the way in, and to close it on the way out.
const OPEN_TIME := 0.45
const CLOSE_TIME := 0.7

@onready var trigger: Area2D = $Trigger

## True once the secret has ever been found (now or on an earlier visit).
var found := false
## True while Kleo is inside it.
var inside := false
var _tween: Tween


func _ready() -> void:
	add_to_group("box_view")
	trigger.collision_layer = 0
	trigger.collision_mask = 2  # the player
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)
	found = flag != "" and Game.flags.has(flag)


func _on_body_entered(body: Node) -> void:
	if not (body is Kleo):
		return
	inside = true
	if not found:
		found = true
		if flag != "":
			Game.flags[flag] = true
	_fade_to(0.0, OPEN_TIME)


func _on_body_exited(body: Node) -> void:
	if not (body is Kleo):
		return
	inside = false
	_fade_to(1.0, CLOSE_TIME)


func _fade_to(alpha: float, time: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, time * absf(modulate.a - alpha)) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_box_view(on: bool) -> void:
	visible = not on
