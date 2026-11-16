class_name EntryDoor
extends Interactable
## A doorway in the middle of a room (a building's door, the outpost's):
## interact to go through it, to `target_door` in `target_scene`. Coming back,
## Kleo appears at the marker beside it (made by the builder's `_entry`).

@export_file("*.tscn") var target_scene := ""
@export var target_door := ""


func interact(kleo: Node) -> void:
	if target_scene != "":
		Game.go_to(target_scene, target_door, kleo)
