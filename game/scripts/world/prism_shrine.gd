class_name PrismShrine
extends Interactable
## A Prism-shard shrine: the save point. Kneeling here wakes it; Kleo returns
## here when she falls.

@export var sprite: Sprite2D
@export var dormant_region := Rect2()
@export var awake_region := Rect2()
@export var glow: PointLight2D

var awake := false


func _ready() -> void:
	super()
	if sprite:
		sprite.region_rect = dormant_region


func interact(kleo: Node) -> void:
	kleo.rest_at(self)
	if not awake:
		awake = true
		if sprite:
			sprite.region_rect = awake_region
		if glow:
			var tw := create_tween()
			tw.tween_property(glow, "energy", glow.energy * 2.2, 0.6).set_ease(Tween.EASE_OUT)
		Game.shake(0.12)
