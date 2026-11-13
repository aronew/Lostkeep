class_name Winch
extends Interactable
## The lift's winch at the bottom of the shaft.

signal used


func interact(kleo: Node) -> void:
	kleo.use_object()
	used.emit()
