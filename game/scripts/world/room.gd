class_name Room
extends Node2D
## A room: its bounds in tiles, where Kleo starts, and the camera's limits.
##
## Doors are Marker2D children of a "Doors" node, each beside a RoomExit. When
## Kleo arrives through a door (Game.arrival_door), she appears at its marker,
## facing into the room.

const TILE := 16

@export var room_rect := Rect2i(0, 0, 120, 40)
@export var spawn := Vector2(224, 384)

@onready var kleo: Kleo = $Kleo
@onready var camera: CameraRig = $Camera


## Art hidden in box view (F1), leaving the collision, Kleo and the machines.
const ART_NODES := ["Behind", "PlacedArt", "Front", "PrismShrine/Art", "GuardLift/Frame", "EarthBackWalls", "BackWalls",
	"Foreground", "ForegroundNear", "ForegroundBands", "GroundFronts", "BierHoist/Frame"]


func _ready() -> void:
	add_to_group("box_view")
	var door := get_node_or_null("Doors/" + Game.arrival_door) as Marker2D if Game.arrival_door != "" else null
	Game.arrival_door = ""
	if door:
		kleo.place(door.global_position, int(door.get_meta("facing", 1)))
	else:
		kleo.place(spawn, 1)
	camera.target = kleo
	camera.limit_left = room_rect.position.x * TILE
	camera.limit_top = room_rect.position.y * TILE
	camera.limit_right = room_rect.end.x * TILE
	camera.limit_bottom = room_rect.end.y * TILE
	# The camera eases into these edges itself; the limits above are only a backstop.
	camera.bounds = Rect2(Vector2(room_rect.position * TILE), Vector2(room_rect.size * TILE))
	camera.snap_to_target()


func set_box_view(on: bool) -> void:
	for path in ART_NODES:
		var n := get_node_or_null(path)
		if n:
			n.visible = not on
	# Islands that are paintings: their collision tiles show only in the box view.
	var masses := get_node_or_null("Masses")
	if masses and masses.has_meta("under_art"):
		masses.visible = on
