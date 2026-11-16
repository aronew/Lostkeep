extends SceneTree
## Screenshots a room scene from a few places, for comparing moods.
##   xvfb-run -a godot --path game --script res://tests/mood_shot.gd -- <scene> <out_prefix> x,y [x,y ...]
## Each x,y is where Kleo is placed (in pixels); the camera settles before the shot.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var room: Node = load(args[0]).instantiate()
	root.add_child(room)
	var kleo := room.get_node("Kleo") as Node2D
	var cam := room.get_node("Camera") as Node2D
	for i in range(2, args.size()):
		var p := args[i].split(",")
		var at := Vector2(float(p[0]), float(p[1]))
		kleo.global_position = at
		cam.global_position = at
		if cam.has_method("snap_to_target"):
			cam.call("snap_to_target")
		for f in 150:
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s_%d.png" % [args[1], i - 1])
	quit()
