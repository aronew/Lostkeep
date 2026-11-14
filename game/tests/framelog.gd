extends Node
## Profiling helper: breaks the hall's props with real input timing and logs
## every frame (real frame time, game speed, nodes, script and physics time) to
## user://framelog.csv. Run it without --fixed-fps:
##   xvfb-run -a godot --path game --max-fps 60 --audio-driver Dummy res://tests/framelog.tscn

const ROOM := "res://scenes/rooms/ironbark_test_room.tscn"
var room: Node
var kleo: Node
var cam: Node
var _log: FileAccess
var _last := 0


func _ready() -> void:
	room = load(ROOM).instantiate()
	add_child(room)
	kleo = room.get_node("Kleo")
	cam = room.get_node("Camera")
	await get_tree().process_frame
	kleo.global_position = Vector2(8 * 16, 37 * 16)
	kleo.velocity = Vector2.ZERO
	cam.snap_to_target()
	for i in 20:
		await get_tree().process_frame
	_log = FileAccess.open("user://framelog.csv", FileAccess.WRITE)
	_log.store_line("frame,real_ms,time_scale,nodes,process_ms,physics_ms,kleo_x,anim")
	_last = Time.get_ticks_usec()
	set_process(true)
	# Walk along the stores, swinging, like a player would.
	var t0 := Time.get_ticks_usec()
	var swing := 0.0
	while Time.get_ticks_usec() - t0 < 6000000:
		var t := (Time.get_ticks_usec() - t0) / 1000000.0
		if t > 1.2 and t < 1.8:
			Input.action_press("move_right")
		else:
			Input.action_release("move_right")
		if t - swing > 0.28 and t < 4.0:
			Input.action_press("attack")
			swing = t
		else:
			Input.action_release("attack")
		await get_tree().process_frame
	Input.action_release("attack")
	Input.action_release("move_right")
	var f := _log
	_log = null
	f.close()
	get_tree().quit()


func _process(_delta: float) -> void:
	if _log == null:
		return
	var now := Time.get_ticks_usec()
	_log.store_line("%d,%.1f,%.3f,%d,%.2f,%.2f,%d,%s" % [Engine.get_process_frames(), (now - _last) / 1000.0,
		Engine.time_scale, Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		int(kleo.global_position.x), kleo.sprite.animation])
	_last = now
