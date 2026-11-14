class_name Room
extends Node2D
## A room: its bounds in tiles, where Kleo starts, and the camera's limits.

const TILE := 16

@export var room_rect := Rect2i(0, 0, 120, 40)
@export var spawn := Vector2(224, 384)

@onready var kleo: Kleo = $Kleo
@onready var camera: CameraRig = $Camera


## Art hidden in box view (F1), leaving the collision, Kleo and the machines.
const ART_NODES := ["Behind", "PlacedArt", "Front", "PrismShrine/Art", "GuardLift/Frame", "EarthBackWalls", "BackWalls",
	"Foreground"]


func _ready() -> void:
	add_to_group("box_view")
	kleo.global_position = spawn
	camera.target = kleo
	camera.limit_left = room_rect.position.x * TILE
	camera.limit_top = room_rect.position.y * TILE
	camera.limit_right = room_rect.end.x * TILE
	camera.limit_bottom = room_rect.end.y * TILE
	camera.snap_to_target()


func set_box_view(on: bool) -> void:
	for path in ART_NODES:
		var n := get_node_or_null(path)
		if n:
			n.visible = not on
