class_name GuardLift
extends Node2D
## The Ironbark Guard's rope lift: a shortcut that opens from below.
##
## It starts at the top, jammed, plugging its shaft. From the bottom, working the
## winch frees the rope and calls the lift down; after that, standing on it
## carries Kleo to the other end. It folds the crypt back to the shrine above.

@export var top_y := 0.0
@export var bottom_y := 208.0
@export var speed := 72.0
@export var unlocked := false
## A name in Game.flags: once freed, the lift stays freed when the room is left.
@export var flag := ""
## Where the ropes hang from (local y), above the top stop.
@export var rope_top := -40.0
@export var platform_width := 64.0

@onready var platform: AnimatableBody2D = $Platform
@onready var rider: Area2D = $Platform/Rider
@onready var winch: Winch = $Winch

var _target := 0.0
var _ride_timer := 0.0


func _ready() -> void:
	if flag != "" and Game.flags.has(flag):
		unlocked = true
	platform.position.y = top_y
	_target = top_y
	winch.used.connect(_on_winch)


func _on_winch() -> void:
	if not unlocked:
		unlocked = true
		if flag != "":
			Game.flags[flag] = true
		Game.shake(0.15)
	_target = bottom_y if is_equal_approx(platform.position.y, top_y) else top_y


func _physics_process(delta: float) -> void:
	var y := platform.position.y
	if not is_equal_approx(y, _target):
		platform.position.y = move_toward(y, _target, speed * delta)
		queue_redraw()
		return
	if not unlocked:
		return
	var riding := false
	for b in rider.get_overlapping_bodies():
		if b is Kleo and b.is_on_floor():
			riding = true
	_ride_timer = _ride_timer + delta if riding else 0.0
	if _ride_timer > 0.35:
		_ride_timer = -10.0
		_target = bottom_y if is_equal_approx(y, top_y) else top_y


func _draw() -> void:
	# Two ropes from the beam above down to the platform's ends.
	var y := platform.position.y if platform else top_y
	var rope := Color(0.55, 0.42, 0.28)
	var shade := Color(0.3, 0.2, 0.14)
	for x in [-platform_width * 0.5 + 6.0, platform_width * 0.5 - 7.0]:
		draw_line(Vector2(x, rope_top), Vector2(x, y - 2.0), rope, 1.0)
		draw_line(Vector2(x + 1.0, rope_top), Vector2(x + 1.0, y - 2.0), shade, 1.0)
