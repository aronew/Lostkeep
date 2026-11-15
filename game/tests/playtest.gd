extends Node
## Test harness: plays the room with scripted input and captures what it sees.
##
##   xvfb-run -a godot --path game --fixed-fps 60 --audio-driver Dummy res://tests/playtest.tscn -- mode=shots
##
## `room=ib02` plays another room (default ib01); its output goes to
## tests/out/<room>/<mode>/. Room IB-02's own modes: tour (the main line), west
## (the upper line, the cave and the secret vault), and doors (IB-01's hall door
## into IB-02 and back). The surface rooms (`room=ib03`, the Ruin
## Gardens; `room=ib04`, the Gate Road): tour (the main line and out the East
## door), upper (the optional lines and the ways back) and doors.
##
## Modes:
##   shots    screenshots of the room's key places, with art and as the black box
##   tour     the main line, scripted, every second frame saved (for a video)
##   upper    the upper line: island, ledge climb, hard landing, knockback
##   props    breaks pots and barrels, stands on the lift's crossbeam, drops through it
##   edge     runs to the room's west edge on both floors and back (the camera at the room's edge)
##   hitstop  random overlapping hit-stops for 3 s of real time: the game must
##            always come back to full speed (run it without --fixed-fps too)
##   click    checks that a left click attacks and a right click is the spell action
##   map      the whole room in screen-sized tiles, with art and as the black box
##            (stitch with tools/stitch_map.py)
##   measure  measures the jump, running jump and ledge reach; prints the numbers
## Output: tests/out/<mode>/

const ROOMS := {
	"ib01": "res://scenes/rooms/ironbark_test_room.tscn",
	"ib02": "res://scenes/rooms/ironbark_02_old_crypt.tscn",
	"ib03": "res://scenes/rooms/ironbark_03_ruin_gardens.tscn",
	"ib04": "res://scenes/rooms/ironbark_04_gate_road.tscn",
	"ib05": "res://scenes/rooms/ironbark_05_shrine_hall.tscn",
	"ib06": "res://scenes/rooms/ironbark_06_undercroft.tscn",
	"ib07": "res://scenes/rooms/ironbark_07_pit_shaft.tscn",
}
const TILE := 16.0

var room_id := "ib01"

var room: Node
var kleo: Kleo
var cam: CameraRig
var mode := "shots"
var out_dir := ""
var _frame := 0
var _held := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("mode="):
			mode = arg.substr(5)
		if arg.begins_with("room="):
			room_id = arg.substr(5)
	out_dir = "res://tests/out/" + ("" if room_id == "ib01" else room_id + "/") + mode
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	Game.room_host = _swap_room  # doors swap the room under this harness
	await _swap_room(ROOMS[room_id])
	await _frames(2)
	if room_id == "ib05":
		match mode:
			"shots":
				await _shots()
			"map":
				await _map()
			"tour":
				await _tour_ib05()
			"upper":
				await _lower_ib05()
			"doors":
				await _doors_ib05()
		get_tree().quit()
		return
	if mode == "secrets":
		await _secrets()
		get_tree().quit()
		return
	if room_id == "ib07":
		match mode:
			"shots":
				await _shots()
			"map":
				await _map()
			"tour":
				await _tour_ib07()
			"upper":
				await _upper_ib07()
		get_tree().quit()
		return
	if room_id == "ib06":
		match mode:
			"shots":
				await _shots()
			"map":
				await _map()
			"tour":
				await _tour_ib06()
			"upper":
				await _loop_ib06()
			"doors":
				await _doors_ib06()
		get_tree().quit()
		return
	if room_id == "ib03" or room_id == "ib04":
		match mode:
			"shots":
				await _shots()
			"map":
				await _map()
			"tour":
				if room_id == "ib03":
					await _tour_ib03()
				else:
					await _tour_ib04()
			"upper":
				if room_id == "ib03":
					await _lower_ib03()
				else:
					await _upper_ib04()
			"doors":
				await _doors_surface()
			"enemy":
				await _enemy()
		get_tree().quit()
		return
	if room_id == "ib02":
		match mode:
			"shots":
				await _shots()
			"map":
				await _map()
			"tour":
				await _tour_ib02()
			"west":
				await _west_ib02()
			"doors":
				await _doors()
		get_tree().quit()
		return
	match mode:
		"shots":
			await _shots()
		"tour":
			await _tour()
		"upper":
			await _upper()
		"map":
			await _map()
		"click":
			await _click()
		"props":
			await _props()
		"hitstop":
			await _hitstop_test()
		"edge":
			await _edge()
		"measure":
			await _measure()
	get_tree().quit()


# --- Helpers ----------------------------------------------------------------------------------

## Load a room in place of the current one (also what a door does, via Game.room_host).
func _swap_room(scene: String) -> void:
	if room:
		# Out of the tree at once, so the new room never sees the old one's tiles
		# and this harness never holds a freed room.
		remove_child(room)
		room.queue_free()
	room = load(scene).instantiate()
	add_child(room)
	kleo = room.get_node("Kleo")
	cam = room.get_node("Camera")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
	await get_tree().process_frame


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir + "/" + name + ".png")


func _place(tile_x: float, floor_tile_y: float, face := 1) -> void:
	kleo.global_position = Vector2(tile_x * TILE, floor_tile_y * TILE)
	kleo.velocity = Vector2.ZERO
	kleo.facing = face
	cam.snap_to_target()


func _press(action: String) -> void:
	Input.action_press(action)
	_held[action] = true


func _release(action: String) -> void:
	Input.action_release(action)
	_held.erase(action)


func _release_all() -> void:
	for a in _held.keys():
		Input.action_release(a)
	_held.clear()


# --- Shots --------------------------------------------------------------------------------------

const SHOTS_IB02 := [
	["01_east_door_hoist", 103.0, 10, -1],
	["02_balcony_well", 63.5, 10, -1],
	["03_grave_island", 52.0, 17, -1],
	["04_niche_walk", 74.0, 19, 1],
	["05_collapse", 83.0, 19, 1],
	["06_long_gallery_winch", 93.0, 28, 1],
	["07_lower_well", 63.5, 28, -1],
	["08_cave_hideout", 30.0, 28, -1],
	["09_west_gallery_plate", 21.0, 16, -1],
	["10_vault", 8.0, 24, -1],
]


func _shots() -> void:
	var places := [
		["01_spawn_shrine", 14.5, 24, 1],
		["02_graveyard", 38.0, 28, 1],
		["03_training_yard", 62.0, 28, -1],
		["04_bridge_moat", 92.0, 28, 1],
		["05_crypt_east", 80.0, 37, -1],
		["06_crypt_west", 44.0, 37, -1],
		["07_west_hall_lift", 23.2, 37, 1],
		["08_island", 40.0, 21, 1],
		["09_root_shelf", 60.0, 17, 1],
		["10_bridge_gap", 100.5, 28, 1],
	]
	if room_id == "ib02":
		places = SHOTS_IB02
	if room_id == "ib03":
		places = SHOTS_IB03
	if room_id == "ib04":
		places = SHOTS_IB04
	if room_id == "ib05":
		places = SHOTS_IB05
	if room_id == "ib06":
		places = SHOTS_IB06
	if room_id == "ib07":
		places = SHOTS_IB07
	for p in places:
		_place(p[1], p[2], p[3])
		await _frames(40)
		await _capture(p[0])
	get_tree().call_group("box_view", "set_box_view", true)
	for p in places:
		_place(p[1], p[2], p[3])
		await _frames(6)
		await _capture(p[0] + "_box")
	get_tree().call_group("box_view", "set_box_view", false)


# --- Tours --------------------------------------------------------------------------------------
# Goal-driven: hold keys until something is true in the world, so each tour walks a real route.

var _n := 0
var _log: FileAccess
var _cam_log: FileAccess


## One frame of a tour. `physics_frame` fires just before the frame's physics
## runs, so wait for `process_frame` too: the log then holds this frame's result.
func _step() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	# Every frame: Kleo and the view, for tools/camera_report.py.
	var view := cam.get_screen_center_position()
	_cam_log.store_line("%.2f,%.2f,%.2f,%.2f" % [kleo.global_position.x, kleo.global_position.y, view.x, view.y])
	if _n % 2 == 0:
		await _capture("f%04d" % (_n / 2))
		var sp := kleo.get_global_transform_with_canvas().origin
		_log.store_line("%d,%d,%d,%s,%d,%d,%d" % [_n / 2, int(sp.x), int(sp.y), kleo.sprite.animation,
			kleo.sprite.frame, int(kleo.global_position.x), int(kleo.global_position.y)])
	_n += 1


func _wait(frames: int) -> void:
	for i in frames:
		await _step()


func _hold_until(actions: Array, done: Callable, limit := 900) -> void:
	for a in actions:
		_press(a)
	for i in limit:
		await _step()
		if done.call():
			break
	_release_all()


func _tap(action: String) -> void:
	_press(action)
	await _step()
	_release(action)


func _start_tour() -> void:
	_log = FileAccess.open(out_dir + "/kleo.csv", FileAccess.WRITE)
	_cam_log = FileAccess.open(out_dir + "/camera.csv", FileAccess.WRITE)
	var rr: Rect2i = room.room_rect
	_cam_log.store_line("#room,%d,%d" % [rr.size.x * TILE, rr.size.y * TILE])
	_n = 0


## The main line: down from the shrine, the training yard, the drop into the
## crypt, west to the hall, the winch, the lift back up, and rest at the shrine.
func _tour() -> void:
	_place(14.5, 24, 1)
	await _frames(20)
	_start_tour()
	await _wait(24)
	await _hold_until(["move_right"], func(): return kleo.global_position.y > 440.0 and kleo.is_on_floor())
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 932.0)
	await _wait(8)
	for i in 4:
		await _tap("attack")
		await _wait(14 if i < 3 else 40)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 1205.0)
	await _wait(12)
	await _hold_until(["move_right"], func(): return kleo.global_position.y > 585.0 and kleo.is_on_floor())
	await _wait(20)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 376.0)
	await _wait(10)
	await _tap("interact")
	await _wait(170)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 412.0)
	await _wait(230)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 240.0)
	await _wait(8)
	await _tap("interact")
	await _wait(100)
	_release_all()


## The upper line: terrace to the island, a ledge climb to the root shelf, a
## long drop to a hard landing, then a heavy blow and the knockback slide.
func _upper() -> void:
	_place(25.0, 24, 1)
	await _frames(20)
	_start_tour()
	await _wait(16)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 452.0)
	await _hold_until(["move_right", "jump"], func(): return kleo.is_on_floor() and kleo.global_position.y < 340.0)
	await _wait(10)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 744.0)
	await _hold_until(["move_right", "jump"], func(): return kleo.state == Kleo.State.LEDGE_HANG)
	await _wait(6)
	await _hold_until(["jump"], func(): return kleo.state == Kleo.State.NORMAL and kleo.is_on_floor())
	await _wait(14)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 1000.0)
	await _hold_until(["move_right"], func(): return kleo.is_on_floor() and kleo.global_position.y > 440.0)
	await _wait(40)
	kleo.hurt(-1, true)
	await _wait(70)
	await _tap("jump")
	await _wait(10)
	await _tap("attack")
	await _wait(30)
	_release_all()


# --- Props ----------------------------------------------------------------------------------------

func _props() -> void:
	_start_tour()
	var lines := []
	# Break the hall's stores with the combo, walking along them.
	var before := get_tree().get_nodes_in_group("breakable").size()
	_place(8.0, 37, 1)
	await _frames(6)
	for i in 6:
		await _tap("attack")
		await _wait(12)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 13.5 * TILE, 120)
	for i in 6:
		await _tap("attack")
		await _wait(12)
	await _wait(40)
	var after := get_tree().get_nodes_in_group("breakable").size()
	lines.append("breakables: %d before, %d after the combo in the hall" % [before, after])
	var settle := Time.get_ticks_usec()
	while Engine.time_scale < 1.0 and Time.get_ticks_usec() - settle < 1000000:
		await get_tree().process_frame
	lines.append("game speed after breaking: %.2f (back to full speed in %.3f s of real time)" %
		[Engine.time_scale, (Time.get_ticks_usec() - settle) / 1000000.0])
	# Jump onto the crossbeam (3 tiles up) from the terrace beside it.
	_place(21.0, 24, 1)
	await _frames(6)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 22.6 * TILE, 60)
	await _hold_until(["move_right", "jump"], func(): return kleo.is_on_floor() and kleo.global_position.y < 24 * TILE - 40, 80)
	await _wait(20)
	var on_beam := kleo.is_on_floor() and absf(kleo.global_position.y - (24 * TILE - 48)) < 1.0
	lines.append("stood on the crossbeam: %s (feet at %.0f, beam top %d)" % [on_beam, kleo.global_position.y, 24 * TILE - 48])
	# Drop back through it.
	_press("move_down")
	await _wait(2)
	await _tap("jump")
	await _wait(40)
	_release_all()
	lines.append("dropped through it: %s (feet at %.0f)" % [kleo.global_position.y > 24 * TILE - 4, kleo.global_position.y])
	var text := "\n".join(lines)
	print(text)
	FileAccess.open(out_dir + "/props.txt", FileAccess.WRITE).store_string(text + "\n")


# --- Room IB-02 ---------------------------------------------------------------------------------

func _floor_at(row: int) -> bool:
	return kleo.is_on_floor() and absf(kleo.global_position.y - row * TILE) < 2.0


## The main line: the East door, over the jammed hoist, off the balcony onto the
## grave island, into the niche walk, down the collapse, the winch, the hoist
## back up, and out through the East door into IB-01.
func _tour_ib02() -> void:
	var lines := []
	_start_tour()
	await _wait(20)
	await _hold_until(["move_left"], func(): return _floor_at(17), 900)
	lines.append("off the balcony onto the grave island: %s (x %.0f)" % [_floor_at(17), kleo.global_position.x])
	await _wait(10)
	await _hold_until(["move_right"], func(): return _floor_at(19), 300)
	lines.append("island into the niche walk (E2): %s" % _floor_at(19))
	await _hold_until(["move_right"], func(): return _floor_at(28), 900)
	lines.append("down the collapse into the long gallery (E3): %s" % _floor_at(28))
	await _wait(30)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 94.4 * TILE, 300)
	await _wait(6)
	await _tap("interact")
	await _wait(300)
	var hoist := room.get_node("BierHoist")
	lines.append("winch frees the hoist: %s; it comes down: %s" % [hoist.unlocked, absf(hoist.get_node("Platform").position.y - 18 * TILE) < 1.0])
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 97.6 * TILE, 200)
	await _wait(330)
	lines.append("hoist carries her up to the vestibule (E1): %s" % _floor_at(10))
	await _hold_until(["move_right"], func(): return room.name != "IronbarkOldCrypt", 400)
	await _wait(50)
	lines.append("out the East door into: %s, standing at x %.0f, y %.0f" % [room.name, kleo.global_position.x, kleo.global_position.y])
	_release_all()
	_report(lines, "tour")


## The upper line and the loop: island, west gallery (the plated door holds),
## the collapse into the cave, the false wall into the vault, then east over the
## lower islands into the long gallery.
func _west_ib02() -> void:
	var lines := []
	_place(52.0, 17, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 46.6 * TILE, 200)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(16) and kleo.global_position.x < 41 * TILE, 200)
	lines.append("island across to the west gallery (W1): %s" % _floor_at(16))
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 29 * TILE, 300)
	await _hold_until(["move_left", "jump"], func(): return kleo.global_position.x < 23.4 * TILE and kleo.is_on_floor(), 200)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 18.9 * TILE, 200)
	await _wait(30)
	lines.append("the plated door holds: %s (x %.0f, wall at %d)" % [kleo.global_position.x > 18 * TILE, kleo.global_position.x, 18 * 16])
	await _hold_until(["move_right"], func(): return kleo.global_position.y > 20 * TILE, 200)
	await _hold_until([], func(): return kleo.is_on_floor(), 200)
	lines.append("down W1's collapse into the cave: landed at y %.0f (the fallen rock is 416, the floor 448)" % kleo.global_position.y)
	await _wait(30)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 15.2 * TILE and kleo.is_on_floor(), 300)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(24), 300)
	var cover := room.get_node("VaultCover")
	await _wait(40)
	lines.append("climbed through the false wall into the vault: %s; cover found: %s" % [_floor_at(24), cover.found])
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 8 * TILE, 200)
	await _wait(20)
	await _hold_until(["move_right"], func(): return _floor_at(28) and kleo.global_position.x > 22 * TILE, 400)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 22.6 * TILE, 100)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(26), 200)
	await _hold_until(["move_right"], func(): return _floor_at(28) and kleo.global_position.x > 30 * TILE, 300)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 39.6 * TILE, 300)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(28) and kleo.global_position.x > 45 * TILE, 200)
	lines.append("cave mouth to the west low island: %s" % (_floor_at(28) and kleo.global_position.x > 45 * TILE))
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 50 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(28) and kleo.global_position.x > 54 * TILE, 200)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 58 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(28) and kleo.global_position.x > 62 * TILE, 200)
	lines.append("over the low islands into the long gallery (E3): %s (x %.0f)" % [_floor_at(28) and kleo.global_position.x > 62 * TILE, kleo.global_position.x])
	await _wait(20)
	# And the water: she can't swim yet, so it returns her to safe ground.
	await _hold_until(["move_left"], func(): return kleo.global_position.y > 31 * TILE, 200)
	await _wait(90)
	lines.append("fell in the cistern, returned to safe ground: %s (x %.0f, y %.0f)" % [kleo.is_on_floor(), kleo.global_position.x, kleo.global_position.y])
	_release_all()
	_report(lines, "west")


# --- Room IB-05, the Shrine Hall (the Old Crypt's first section) -------------------------------------

const SHOTS_IB05 := [
	["01_east_door_landing", 55.0, 7, -1],
	["02_east_gallery", 36.0, 9, -1],
	["03_shrine_island", 20.0, 17, 1],
	["04_west_gallery", 8.0, 8, 1],
	["05_plates_arch_island", 36.0, 17, 1],
	["06_lower_floor_west", 10.0, 26, 1],
	["07_pit_and_dip", 26.0, 26, 1],
	["08_shelf_lower_east", 48.0, 26, 1],
]


## The main line: in by the East door, over the gap by the landing (down to the
## east gallery), along it, over the gap between the galleries (up one), and
## out the West door into the rest of the Old Crypt.
func _tour_ib05() -> void:
	var lines := []
	_start_tour()
	await _wait(30)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 51.0 * TILE, 300)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(9) and kleo.global_position.x < 46 * TILE, 200)
	lines.append("over the gap by the landing, down to the east gallery: %s (x %.0f)" % [_floor_at(9) and kleo.global_position.x < 46 * TILE, kleo.global_position.x])
	# Up the step out of the arcade bay (row 9 to 8), then over the gap: the
	# west gallery's floor steps up toward it (row 7).
	await _jump_to(31.0 * TILE, 23.0 * TILE, 27.0 * TILE, 8)
	var up := await _jump_to(25.0 * TILE, 14.0 * TILE, 18.5 * TILE, 7, 22.4 * TILE)
	lines.append("over the gap between the galleries, up to the west gallery's step: %s (x %.0f)" % [up, kleo.global_position.x])
	await _hold_until(["move_left"], func(): return room.name != "IronbarkShrineHall", 500)
	await _wait(50)
	lines.append("out the West door into: %s, standing at x %.0f, y %.0f, on the floor: %s" % [room.name, kleo.global_position.x, kleo.global_position.y, kleo.is_on_floor()])
	_release_all()
	_report(lines, "tour")


## Walk to an edge and step off it, as a player would to drop to what is below.
func _step_off(key: String, past_x: float, row: int) -> bool:
	var dir := 1 if key == "move_right" else -1
	await _hold_until([key], func(): return dir * (kleo.global_position.x - past_x) > 0.0 or not kleo.is_on_floor(), 300)
	_release_all()
	for i in 200:
		await _step()
		if kleo.is_on_floor() and i > 4:
			break
	await _wait(6)
	return _floor_at(row)


## Jump from where she stands to a floor in [x0, x1] on `row`. A climb (the
## target four or more rows up: a ledge catch) is jumped from standing at `from_x`, steering
## toward the target only near the top, so she rises beside its edge and
## catches it. Any other jump is run at from `from_x` and taken off at
## `takeoff_x` (by default straight away), steering so she comes down over it.
func _jump_to(from_x: float, x0: float, x1: float, row: int, takeoff_x := -1.0) -> bool:
	var dir := 1 if x0 > from_x else -1
	var start_row := int(roundf(kleo.global_position.y / TILE))
	var climb := row <= start_row - 4
	if kleo.global_position.x > from_x:
		await _hold_until(["move_left"], func(): return kleo.global_position.x <= from_x, 300)
	else:
		await _hold_until(["move_right"], func(): return kleo.global_position.x >= from_x, 300)
	await _wait(6)
	var mid := (x0 + x1) * 0.5
	var key := "move_right" if dir > 0 else "move_left"
	if not climb:
		_press(key)
		if takeoff_x >= 0.0:
			await _hold_until([key], func(): return dir * (kleo.global_position.x - takeoff_x) >= 0.0, 200)
			_press(key)
		else:
			await _wait(4)
	_press("jump")
	for i in 150:
		await _step()
		if climb and i == 10:
			_press(key)
		if dir * (kleo.global_position.x - mid) > -8.0:
			_release(key)
		if kleo.state == Kleo.State.LEDGE_HANG:
			_press(key)
		if kleo.is_on_floor() and i > 4 and kleo.state == Kleo.State.NORMAL:
			break
	_release_all()
	await _wait(8)
	var ok := _floor_at(row) and kleo.global_position.x >= x0 - 6.0 and kleo.global_position.x <= x1 + 6.0
	if not ok:
		print("  jump to row %d [%.0f, %.0f] from %.0f missed: at x %.0f, y %.0f" % [row, x0, x1, from_x, kleo.global_position.x, kleo.global_position.y])
	return ok


## The hall: every island, plate and ledge, and the ways back up.
func _lower_ib05() -> void:
	var lines := []
	_place(24.0, 9, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return _floor_at(17), 300)
	lines.append("dropped through the galleries' gap onto the shrine island: %s (x %.0f)" % [_floor_at(17), kleo.global_position.x])
	await _wait(20)
	var a := await _jump_to(424.0, 496.0, 528.0, 18)
	var b := await _jump_to(520.0, 544.0, 576.0, 17)
	var c := await _jump_to(568.0, 592.0, 624.0, 16)
	var d := await _jump_to(616.0, 656.0, 752.0, 18)
	var e := await _jump_to(738.0, 752.0, 784.0, 13)
	var f := await _jump_to(766.0, 352.0, 736.0, 9)
	lines.append("shrine to the three plates, the arch island, the ledge under the east gap, and up to the east gallery: %s, %s, %s, %s, %s, %s" % [a, b, c, d, e, f])
	# The west side, from the lower floor: the pedestal, the small island, the shrine; the wall ledge.
	_place(5.0, 26, 1)
	await _wait(10)
	var g := await _jump_to(132.0, 160.0, 192.0, 22)
	var h := await _jump_to(186.0, 112.0, 144.0, 20)
	var i2 := await _jump_to(136.0, 208.0, 448.0, 17)
	_place(8.0, 20, -1)
	await _wait(10)
	var j := await _jump_to(126.0, 48.0, 112.0, 16)
	lines.append("floor to the pedestal, the small island, the shrine; the island to the west wall's ledge: %s, %s, %s, %s" % [g, h, i2, j])
	# The nook under the shrine, the ledge over the pit, the shelf by the lower East door.
	_place(19.0, 27, 1)
	await _wait(10)
	var k := await _jump_to(330.0, 352.0, 384.0, 22)
	_place(26.0, 26, 1)
	await _wait(10)
	var l := await _jump_to(440.0, 464.0, 496.0, 22)
	var m := await _jump_to(480.0, 496.0, 528.0, 18)
	_place(45.0, 26, 1)
	await _wait(10)
	var n := await _jump_to(780.0, 800.0, 864.0, 21)
	var o := await _jump_to(856.0, 656.0, 752.0, 18, 806.0)
	lines.append("the nook; the pit ledge and on to the first plate; the shelf and over to the arch island: %s, %s, %s, %s, %s" % [k, l, m, n, o])
	# The pit, and out the lower West door.
	_place(26.0, 26, 1)
	await _wait(10)
	await _hold_until(["move_right"], func(): return _floor_at(31) or (_floor_at(26) and kleo.global_position.x > 33.5 * TILE), 300)
	var in_pit := _floor_at(31)
	if in_pit:
		await _wait(20)
		await _hold_until(["move_right", "jump"], func(): return _floor_at(26) and kleo.global_position.x > 33 * TILE, 300)
	lines.append("over the pit (%s): out on its far side: %s (x %.0f)" % ["fell in and climbed out" if in_pit else "caught its far lip", _floor_at(26), kleo.global_position.x])
	_place(6.0, 26, -1)
	await _wait(10)
	await _hold_until(["move_left"], func(): return room.name != "IronbarkShrineHall", 300)
	await _wait(50)
	lines.append("out the lower West door into: %s, standing at x %.0f, y %.0f, on the floor: %s" % [room.name, kleo.global_position.x, kleo.global_position.y, kleo.is_on_floor()])
	_release_all()
	_report(lines, "upper")


# --- Room IB-06, the Undercroft ----------------------------------------------------------------

const SHOTS_IB06 := [
	["01_storeroom_L1", 6.0, 16, 1],
	["02_arcade_R1", 30.0, 18, -1],
	["03_void_step", 17.0, 28, 1],
	["04_arcades_L3_R3", 18.0, 39, -1],
	["05_root_arch", 20.0, 46, 1],
	["06_L4_R4", 16.0, 53, 1],
	["07_basin", 18.0, 68, 1],
	["08_R5_lift_foot", 34.0, 65, 1],
	["09_L5_plated_door", 6.0, 65, -1],
]


## The main line: in by the West door to the storeroom (L1), across the void
## to the arcade (R1), down onto the step, across to R2, off its lip onto R3's,
## across to L3's arcade, down onto the root arch, into R4, down to the basin,
## up into R5 and out east.
func _tour_ib06() -> void:
	var lines := []
	_place(4.0, 16, 1)
	await _frames(10)
	_start_tour()
	await _wait(20)
	var a := await _jump_to(15.0 * TILE, 18.0 * TILE, 30.0 * TILE, 18, 15.2 * TILE)
	var b := await _step_off("move_left", 17.9 * TILE, 28)
	var c := await _jump_to(17.4 * TILE, 20.0 * TILE, 30.0 * TILE, 28)
	var d := await _step_off("move_left", 19.9 * TILE, 39)
	var e := await _jump_to(18.4 * TILE, 4.0 * TILE, 15.5 * TILE, 39)
	var f := await _step_off("move_right", 16.3 * TILE, 46)
	await _hold_until(["move_right"], func(): return _floor_at(53), 400)
	var g := _floor_at(53)
	await _hold_until(["move_left"], func(): return _floor_at(68), 500)
	var h := _floor_at(68)
	var i := await _jump_to(21.5 * TILE, 24.0 * TILE, 34.0 * TILE, 65)
	lines.append("L1 to R1, down to the step, R2, R3's lip, across to L3, down onto the arch, into R4, the basin, R5: %s, %s, %s, %s, %s, %s, %s, %s, %s" % [a, b, c, d, e, f, g, h, i])
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 42.5 * TILE, 400)
	lines.append("to the lower East door (toward the Keep's foundations): %s (x %.0f)" % [kleo.global_position.x > 42.5 * TILE, kleo.global_position.x])
	_release_all()
	_report(lines, "tour")


## The fold and the side rooms: the winch and the lift from R5 up to R1, back
## across to L1; L2 from the step; L4 off the arch; L5 from the basin; the sump.
func _loop_ib06() -> void:
	var lines := []
	_place(33.0, 65, 1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 35.6 * TILE, 200)
	await _wait(6)
	await _tap("interact")
	await _wait(700)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 39.8 * TILE, 200)
	await _wait(760)
	lines.append("the winch frees the cellar lift; it carries her up to R1: %s (y %.0f)" % [_floor_at(18), kleo.global_position.y])
	_place(19.0, 18, -1)
	await _wait(10)
	var a := await _jump_to(18.3 * TILE, 4.0 * TILE, 15.5 * TILE, 16)
	lines.append("back across the void to L1, by the Shrine Hall's door: %s" % a)
	_place(17.0, 28, -1)
	await _wait(10)
	var b := await _jump_to(16.4 * TILE, 8.0 * TILE, 15.5 * TILE, 25)
	_place(20.0, 46, -1)
	await _wait(10)
	await _hold_until(["move_left"], func(): return _floor_at(53) and kleo.global_position.x < 13.0 * TILE, 300)
	var c := _floor_at(53) and kleo.global_position.x < 13.0 * TILE
	_place(18.0, 68, -1)
	await _wait(10)
	var d := await _jump_to(16.3 * TILE, 4.0 * TILE, 12.5 * TILE, 65)
	lines.append("L2 from the step, L4 off the arch, L5 from the basin: %s, %s, %s" % [b, c, d])
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 3.0 * TILE, 200)
	lines.append("the plated door holds her (Ward): she stops at x %.0f" % kleo.global_position.x)
	_place(18.0, 68, -1)
	await _wait(10)
	await _hold_until(["move_left"], func(): return kleo.global_position.y > 68.5 * TILE, 200)
	await _wait(90)
	lines.append("fell in the sump, returned to safe ground: %s (x %.0f, y %.0f)" % [kleo.is_on_floor(), kleo.global_position.x, kleo.global_position.y])
	_release_all()
	_report(lines, "upper")


## IB-05's lower East door into the Undercroft, and back out its West door.
func _doors_ib06() -> void:
	var lines := []
	await _swap_room(ROOMS["ib05"])
	await _frames(2)
	_place(36.0, 26, 1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_right"], func(): return room.name == "IronbarkUndercroft", 600)
	if room.name != "IronbarkUndercroft":
		lines.append("stuck in IB-05 at x %.0f, y %.0f" % [kleo.global_position.x, kleo.global_position.y])
	await _wait(40)
	lines.append("IB-05's lower East door leads to: %s; she stands at x %.0f, y %.0f, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.is_on_floor()])
	await _hold_until(["move_left"], func(): return room.name == "IronbarkShrineHall", 300)
	await _wait(40)
	lines.append("and back to: %s; she stands at x %.0f, y %.0f, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.is_on_floor()])
	_release_all()
	_report(lines, "doors")


# --- Room IB-07, the Pit Shaft ----------------------------------------------------------------

const SHOTS_IB07 := [
	["01_walkway_plate", 15.0, 12, 1],
	["02_chasm_landing", 17.0, 28, -1],
	["03_arched_door_room", 5.0, 28, 1],
	["04_west_cave", 10.0, 50, 1],
	["05_niche_passage", 27.0, 41, 1],
	["06_the_bottom", 20.0, 60, 1],
	["07_lantern_room", 35.0, 60, 1],
]


## Dropped in through the plate (as with the Ward): down the gap in the walkway
## onto the landing, across to the arched-door room and back, down the west
## cave to the bottom, then the climb on the right to the niche and the passage
## out, and through the plated door into the Undercroft.
func _tour_ib07() -> void:
	var lines := []
	_place(14.0, 12, 1)
	await _frames(10)
	_start_tour()
	await _wait(10)
	await _hold_until(["move_right"], func(): return _floor_at(28), 300)
	var a := _floor_at(28)
	var b := await _jump_to(14.3 * TILE, 2.0 * TILE, 9.5 * TILE, 28)
	var c := await _jump_to(9.5 * TILE, 14.0 * TILE, 20.5 * TILE, 28)
	lines.append("through the walkway's gap onto the landing, to the arched-door room and back: %s, %s, %s" % [a, b, c])
	await _hold_until(["move_left"], func(): return _floor_at(36), 300)
	await _hold_until(["move_left"], func(): return _floor_at(50), 300)
	await _hold_until(["move_left"], func(): return kleo.is_on_floor() and kleo.global_position.y > 57.5 * TILE, 300)
	lines.append("down the west cave by its ledges to the bottom: on row %d" % int(roundf(kleo.global_position.y / TILE)))
	if kleo.global_position.x < 9.0 * TILE:
		await _jump_to(8.0 * TILE, 9.0 * TILE, 13.5 * TILE, 58)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 25.0 * TILE, 400)
	await _jump_to(25.0 * TILE, 27.0 * TILE, 31.5 * TILE, 58)
	var d := await _jump_to(26.4 * TILE, 22.0 * TILE, 24.0 * TILE, 54)
	var e := await _jump_to(23.6 * TILE, 26.0 * TILE, 28.0 * TILE, 50)
	var f := await _jump_to(26.4 * TILE, 23.0 * TILE, 25.0 * TILE, 46)
	var g := await _jump_to(24.6 * TILE, 25.0 * TILE, 27.0 * TILE, 41)
	var h := await _jump_to(26.6 * TILE, 31.0 * TILE, 40.0 * TILE, 41)
	lines.append("the climb on the right (54, 50, 46, the niche, the passage): %s, %s, %s, %s, %s" % [d, e, f, g, h])
	await _hold_until(["move_right"], func(): return room.name != "IronbarkPitShaft", 400)
	await _wait(40)
	lines.append("out the East door into: %s, standing at x %.0f, y %.0f, on the floor: %s" % [room.name, kleo.global_position.x, kleo.global_position.y, kleo.is_on_floor()])
	_release_all()
	_report(lines, "tour")


## The walkway's east end: down the gap by the tall wall onto the passage's lip.
func _upper_ib07() -> void:
	var lines := []
	_place(26.0, 12, 1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_right"], func(): return kleo.is_on_floor() and kleo.global_position.y > 13.0 * TILE, 300)
	lines.append("off the walkway's east end, down beside the tall wall: on row %d at x %.0f" % [int(roundf(kleo.global_position.y / TILE)), kleo.global_position.x])
	_release_all()
	_report(lines, "upper")


# --- Secrets ------------------------------------------------------------------------------------

## Every false wall: walk into it, see it open, take the Resin behind it.
## [room, start x, floor row, face, walk until x is below, the cover's name]
const SECRETS := [
	["ib05", 5.0, 16, -1, 1.2, "WestWallSecret"],
	["ib06", 10.0, 25, -1, 2.6, "L2Secret"],
	["ib06", 9.0, 53, -1, 1.6, "L4Secret"],
	["ib07", 8.0, 60, -1, 1.4, "WestFootSecret"],
	["ib02", 13.0, 24, -1, 4.2, "VaultCover"],
]


func _secrets() -> void:
	var lines := []
	_start_tour()
	for sc in SECRETS:
		await _swap_room(ROOMS[sc[0]])
		await _frames(2)
		_place(sc[1], sc[2], sc[3])
		await _wait(10)
		var before := Game.currency
		var cover := room.get_node_or_null(String(sc[5]))
		_place(sc[1] + 0.5, sc[2], 1)
		await _wait(30)
		await _capture("%s_%s_before" % [sc[0], sc[5]])
		_place(sc[1], sc[2], sc[3])
		await _wait(10)
		await _hold_until(["move_left"], func(): return kleo.global_position.x < sc[4] * TILE, 300)
		await _hold_until(["move_right"], func(): return kleo.global_position.x > (sc[4] + 1.6) * TILE, 120)
		await _wait(40)
		await _capture("%s_%s" % [sc[0], sc[5]])
		lines.append("%s %s: the wall opened: %s; Resin %d -> %d" % [sc[0], sc[5], cover != null and cover.get("found"), before, Game.currency])
	_release_all()
	_report(lines, "secrets")


## IB-01's hall door into IB-05 and back; IB-02's two East doors into IB-05.
func _doors_ib05() -> void:
	var lines := []
	await _swap_room(ROOMS["ib01"])
	await _frames(2)
	_place(6.0, 37, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return room.name == "IronbarkShrineHall", 300)
	await _wait(40)
	lines.append("IB-01 hall door leads to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	await _hold_until(["move_right"], func(): return room.name == "IronbarkTestRoom", 300)
	await _wait(40)
	lines.append("and back to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	for d in [[108.0, 10, "upper"], [108.0, 28, "lower"]]:
		await _swap_room(ROOMS["ib02"])
		await _frames(2)
		_place(d[0], d[1], 1)
		await _wait(10)
		await _hold_until(["move_right"], func(): return room.name == "IronbarkShrineHall", 300)
		await _wait(40)
		lines.append("IB-02's %s East door leads to: %s; she stands at x %.0f, y %.0f, on the floor: %s" %
			[d[2], room.name, kleo.global_position.x, kleo.global_position.y, kleo.is_on_floor()])
	_release_all()
	_report(lines, "doors")


## IB-01's hall door into the crypt (IB-05, then IB-02) and straight back.
func _doors() -> void:
	var lines := []
	await _swap_room(ROOMS["ib01"])
	await _frames(2)
	_place(6.0, 37, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return room.name == "IronbarkShrineHall", 300)
	await _wait(40)
	lines.append("IB-01 hall door leads to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	await _hold_until(["move_right"], func(): return room.name == "IronbarkTestRoom", 300)
	await _wait(40)
	lines.append("and back to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	_release_all()
	_report(lines, "doors")


# --- The surface rooms: IB-03, the Ruin Gardens, and IB-04, the Gate Road ---------------------------

const SHOTS_IB03 := [
	["01_start_road", 2.5, 37, 1],
	["02_west_hill", 20.0, 31, 1],
	["03_hill_top_stepping", 28.0, 28, 1],
	["04_great_island", 52.0, 22, 1],
	["05_log_to_cliff", 68.0, 22, 1],
	["06_exit_arch", 87.0, 16, 1],
	["07_garden", 45.0, 37, 1],
	["08_low_island", 49.0, 31, 1],
	["09_cave", 75.0, 33, -1],
]
const SHOTS_IB04 := [
	["01_arrival_hilltop", 4.0, 16, 1],
	["02_terraces", 22.0, 22, 1],
	["03_great_island", 36.0, 16, 1],
	["04_second_island", 58.0, 20, 1],
	["05_lower_terraces", 38.0, 29, 1],
	["06_high_path", 92.0, 19, 1],
	["07_pool_low_path", 96.0, 36, 1],
	["08_road_end", 123.0, 37, 1],
]


## IB-03's main line: the road, the hill's stairs and its jump, the stepping
## island, the great island, the log, the cliff's stairs, and out the East door.
func _tour_ib03() -> void:
	var lines := []
	_start_tour()
	await _wait(30)
	await _hold_until(["move_right"], func(): return _floor_at(34), 300)
	lines.append("up the first flight onto the hill: %s" % _floor_at(34))
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 15.3 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(31), 200)
	lines.append("jumped up the three-tile step: %s" % _floor_at(31))
	await _hold_until(["move_right"], func(): return _floor_at(28) and kleo.global_position.x > 384, 300)
	lines.append("up the second flight to the hill's top: %s" % _floor_at(28))
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 29.4 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(25), 200)
	lines.append("hill top to the stepping island (3 across, 3 up): %s (x %.0f)" % [_floor_at(25), kleo.global_position.x])
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 36.4 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(22), 200)
	lines.append("stepping island to the great island (2 across, 3 up): %s (x %.0f)" % [_floor_at(22), kleo.global_position.x])
	await _hold_until(["move_right"], func(): return _floor_at(22) and kleo.global_position.x > 71.5 * TILE, 700)
	lines.append("across the great island and the log onto the cliff: %s (x %.0f)" % [_floor_at(22), kleo.global_position.x])
	await _hold_until(["move_right"], func(): return _floor_at(16), 400)
	lines.append("up the cliff's two flights to the arch: %s" % _floor_at(16))
	await _hold_until(["move_right"], func(): return room.name != "IronbarkRuinGardens", 400)
	await _wait(50)
	lines.append("out the East door into: %s, standing at x %.0f, y %.0f, on the floor: %s" % [room.name, kleo.global_position.x, kleo.global_position.y, kleo.is_on_floor()])
	_release_all()
	_report(lines, "tour")


## IB-03's garden under the islands: the way back up to the hill (two ledge
## catches), the cave, and the low island.
func _lower_ib03() -> void:
	var lines := []
	_place(45.0, 37, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 35.7 * TILE, 300)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(33), 300)
	var a := _floor_at(33)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 30.7 * TILE, 200)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(28), 300)
	lines.append("garden back up to the hill's top (ledge catches of 4 and 5 tiles): %s, %s" % [a, _floor_at(28)])
	_place(52.0, 37, 1)
	await _wait(10)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 56.3 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(33), 300)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 76 * TILE, 400)
	lines.append("up the cliff's shelf and into the cave: %s (x %.0f)" % [_floor_at(33), kleo.global_position.x])
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 57.6 * TILE, 400)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(31), 300)
	lines.append("shelf to the low island (2 across, 2 up): %s (x %.0f)" % [_floor_at(31), kleo.global_position.x])
	_release_all()
	_report(lines, "upper")


## IB-04's main line: down the hill's flights and drops, the road, the pool's piers, and out the East door into IB-01.
func _tour_ib04() -> void:
	var lines := []
	_start_tour()
	await _wait(30)
	await _hold_until(["move_right"], func(): return _floor_at(22), 400)
	lines.append("down two flights: %s" % _floor_at(22))
	await _hold_until(["move_right"], func(): return _floor_at(26), 300)
	await _hold_until(["move_right"], func(): return _floor_at(29), 300)
	await _hold_until(["move_right"], func(): return _floor_at(34), 300)
	await _hold_until(["move_right"], func(): return _floor_at(37), 300)
	lines.append("wound down the hill to the road: %s (x %.0f)" % [_floor_at(37), kleo.global_position.x])
	# The pool's low path: seven jumps, by its six small islands.
	var hops := 0
	for hop in [[1242.0, 1304.0], [1346.0, 1407.0], [1449.0, 1510.0], [1552.0, 1613.0], [1655.0, 1716.0], [1758.0, 1819.0], [1861.0, 1920.0]]:
		await _hold_until(["move_right"], func(): return kleo.global_position.x > hop[0], 300)
		await _hold_until(["move_right", "jump"], func(): return kleo.is_on_floor() and kleo.global_position.x > hop[1], 120)
		if kleo.is_on_floor() and kleo.global_position.x > hop[1]:
			hops += 1
		await _wait(6)
	lines.append("crossed the pool by the low path: %d of 7 jumps landed (x %.0f, y %.0f)" % [hops, kleo.global_position.x, kleo.global_position.y])
	await _hold_until(["move_right"], func(): return room.name != "IronbarkGateRoad", 400)
	await _wait(50)
	lines.append("out the East door into: %s, standing at x %.0f, y %.0f, on the floor: %s" % [room.name, kleo.global_position.x, kleo.global_position.y, kleo.is_on_floor()])
	_release_all()
	_report(lines, "tour")


## IB-04's upper line: the islands over the terraces, a leap for the far island
## (it must fall short), then the way back up the hill from the road, and the water.
func _upper_ib04() -> void:
	var lines := []
	_place(15.0, 19, 1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 17.4 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(17), 200)
	lines.append("terrace to the stepping island (3 across, 2 up): %s (x %.0f)" % [_floor_at(17), kleo.global_position.x])
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 23.4 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(16), 200)
	lines.append("stepping island to the great island: %s (x %.0f)" % [_floor_at(16), kleo.global_position.x])
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 45.4 * TILE, 400)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(20), 200)
	lines.append("great island down to the second island (4 across, 4 down): %s (x %.0f)" % [_floor_at(20), kleo.global_position.x])
	# The high path over the pool: down to the ruin, up to the great island, down
	# to the headstone chunk, then the far bank.
	var steps := []
	for hop in [[65.4, 70.0, 22], [78.4, 82.0, 19], [108.4, 114.0, 23]]:
		await _hold_until(["move_right"], func(): return kleo.global_position.x > hop[0] * TILE, 700)
		await _hold_until(["move_right", "jump"], func(): return _floor_at(hop[2]) and kleo.global_position.x > hop[1] * TILE, 300)
		steps.append(_floor_at(hop[2]) and kleo.global_position.x > hop[1] * TILE)
		await _wait(8)
	await _hold_until(["move_right"], func(): return _floor_at(37) and kleo.global_position.x > 1920, 400)
	lines.append("the high path over the pool (ruin -2, great island +3, headstone chunk -4): %s; on the far bank: %s (x %.0f)" % [str(steps), _floor_at(37), kleo.global_position.x])
	await _wait(30)
	_place(58.0, 37, -1)
	await _wait(10)
	# Back up the hill from the road.
	await _hold_until(["move_left"], func(): return _floor_at(34), 600)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 42.7 * TILE, 200)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(29), 300)
	var a := _floor_at(29)
	await _hold_until(["move_left"], func(): return _floor_at(26), 300)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 26.7 * TILE, 200)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(22), 300)
	var b := _floor_at(22)
	await _hold_until(["move_left"], func(): return _floor_at(16), 500)
	lines.append("back up the hill from the road (a 5-tile catch, a flight, a 4-tile catch, two flights): %s, %s, %s" % [a, b, _floor_at(16)])
	# The water.
	_place(76.0, 37, 1)
	await _wait(10)
	await _hold_until(["move_right"], func(): return kleo.global_position.y > GROUND_Y + 10, 200)
	await _wait(90)
	lines.append("walked into the water, returned to safe ground: %s (x %.0f, y %.0f)" % [kleo.is_on_floor(), kleo.global_position.x, kleo.global_position.y])
	_release_all()
	_report(lines, "upper")

const GROUND_Y := 592.0


## The Mossback: walk into it (a shove), then stand and swing until it is gone,
## counting the hits it takes. Run it in IB-03 (the garden's Mossback).
func _enemy() -> void:
	var lines := []
	var moss: Node2D = null
	for e in get_tree().get_nodes_in_group("enemy"):
		if moss == null or e.global_position.y > moss.global_position.y:
			moss = e
	lines.append("enemies in the room: %d" % get_tree().get_nodes_in_group("enemy").size())
	_place((moss.global_position.x - 60.0) / TILE, moss.global_position.y / TILE, 1)
	await _frames(10)
	_start_tour()
	await _wait(50)
	# Walk into it.
	var shoved := false
	_press("move_right")
	for i in 200:
		await _step()
		if kleo.state == Kleo.State.HURT:
			shoved = true
			break
	_release_all()
	lines.append("walking into it shoves her back: %s" % shoved)
	await _wait(80)
	# Face it and swing until it is gone.
	var swings := 0
	var hits := 0
	while is_instance_valid(moss) and not moss.dead and swings < 30:
		var want := 1 if moss.global_position.x > kleo.global_position.x else -1
		var gap := absf(moss.global_position.x - kleo.global_position.x)
		if gap > 26.0:
			await _hold_until(["move_right" if want > 0 else "move_left"], func(): return not is_instance_valid(moss) or absf(moss.global_position.x - kleo.global_position.x) < 24.0 or kleo.state == Kleo.State.HURT, 120)
		elif kleo.facing != want:
			await _tap("move_right" if want > 0 else "move_left")
		if kleo.state == Kleo.State.HURT:
			await _wait(50)
			continue
		await _tap("attack")
		swings += 1
		for i in 26:
			await _step()
			if is_instance_valid(moss):
				hits = moss.hits
	await _wait(40)
	lines.append("sword hits it took before it went down: %d (rule: 7), in %d swings; gone: %s" % [hits, swings, not is_instance_valid(moss)])
	lines.append("game speed after: %.2f; enemies left in the room: %d" % [Engine.time_scale, get_tree().get_nodes_in_group("enemy").size()])
	_release_all()
	_report(lines, "enemy")


## IB-01's terrace west into IB-04, west across... no: straight back east.
func _doors_surface() -> void:
	var lines := []
	await _swap_room(ROOMS["ib01"])
	await _frames(2)
	_place(6.0, 24, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return room.name == "IronbarkGateRoad", 300)
	await _wait(40)
	lines.append("IB-01 terrace leads to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	await _hold_until(["move_right"], func(): return room.name == "IronbarkTestRoom", 300)
	await _wait(40)
	lines.append("and back to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	# IB-04's west door into IB-03 and back.
	await _swap_room(ROOMS["ib04"])
	await _frames(2)
	_place(5.0, 16, -1)
	await _wait(10)
	await _hold_until(["move_left"], func(): return room.name == "IronbarkRuinGardens", 300)
	await _wait(40)
	lines.append("IB-04 hilltop leads west to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	_release_all()
	_report(lines, "doors")


func _report(lines: Array, file: String) -> void:
	var text := "\n".join(lines)
	print(text)
	FileAccess.open(out_dir + "/" + file + ".txt", FileAccess.WRITE).store_string(text + "\n")


# --- The room's edge ---------------------------------------------------------------------------

func _edge() -> void:
	# This test is about the camera at the room's edge, so the doors stay shut.
	for e in room.get_node("Doors").get_children():
		if e is Area2D:
			e.monitoring = false
	# The terrace: from the shrine, run to the room's west edge and back.
	_place(20.0, 24, -1)
	await _frames(20)
	_start_tour()
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 12.0, 240)
	await _wait(30)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 26.0 * TILE, 240)
	await _wait(20)
	# The hall: west to the lower door and back.
	_place(16.0, 37, -1)
	await _frames(10)
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 12.0, 240)
	await _wait(30)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 17.0 * TILE, 240)
	await _wait(20)
	_release_all()


# --- Hit-stop -------------------------------------------------------------------------------------

func _hitstop_test() -> void:
	var lines := []
	var worst := 0.0
	var last_call := 0
	var calls := 0
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < 3000000:
		if randf() < 0.35:
			Game.hitstop(randf_range(0.01, 0.3))
			last_call = Time.get_ticks_usec()
			calls += 1
		await get_tree().process_frame
		if Engine.time_scale < 1.0 and last_call > 0:
			worst = maxf(worst, (Time.get_ticks_usec() - last_call) / 1000000.0)
	var end_wait := Time.get_ticks_usec()
	while Engine.time_scale < 1.0 and Time.get_ticks_usec() - end_wait < 1000000:
		await get_tree().process_frame
	lines.append("%d overlapping hit-stops in 3 s" % calls)
	lines.append("longest slow-down after the latest hit: %.3f s (cap %.2f s plus a frame)" % [worst, Game.HITSTOP_MAX])
	lines.append("game speed at the end: %.2f" % Engine.time_scale)
	var text := "\n".join(lines)
	print(text)
	FileAccess.open(out_dir + "/hitstop.txt", FileAccess.WRITE).store_string(text + "\n")


# --- Mouse ---------------------------------------------------------------------------------------

func _click() -> void:
	_place(40.0, 28)
	await _frames(10)
	var lines := []
	for button in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.position = Vector2(320, 180)
		ev.pressed = true
		Input.parse_input_event(ev)
		await get_tree().physics_frame
		var attack := Input.is_action_pressed("attack")
		var spell := Input.is_action_pressed("spell")
		await _frames(3)
		var state: String = Kleo.State.keys()[kleo.state]
		var anim := String(kleo.sprite.animation)
		ev = ev.duplicate()
		ev.pressed = false
		Input.parse_input_event(ev)
		await _frames(40)
		lines.append("%s click: attack action %s, spell action %s, Kleo %s (%s)" %
			["left" if button == MOUSE_BUTTON_LEFT else "right", attack, spell, state, anim])
	var text := "\n".join(lines)
	print(text)
	FileAccess.open(out_dir + "/click.txt", FileAccess.WRITE).store_string(text + "\n")


# --- Map ---------------------------------------------------------------------------------------

## Layers left out of the map: the parallax planes, the foreground silhouettes
## (they belong to the camera, not the room), the screen effects and Kleo.
const MAP_HIDDEN := ["Sky", "Far", "FogFar", "MidFar", "Mid", "FogMid", "Ruins", "Mood", "Foreground", "ForegroundNear", "Screen", "Kleo"]


func _map_hide() -> void:
	for n in MAP_HIDDEN:
		var node := room.get_node_or_null(n)
		if node:
			node.visible = false


func _map() -> void:
	_map_hide()
	cam.target = null
	cam.offset = Vector2.ZERO
	var rect: Rect2i = room.room_rect
	var size := Vector2(rect.size * 16)
	var xs := []
	var x := 320.0
	while x < size.x - 320.0:
		xs.append(x)
		x += 640.0
	xs.append(size.x - 320.0)
	var ys := [180.0, size.y - 180.0]
	var lines := []
	for view in ["art", "box"]:
		get_tree().call_group("box_view", "set_box_view", view == "box")
		_map_hide()  # switching views shows the art layers again
		for cx in xs:
			for cy in ys:
				cam.global_position = Vector2(cx, cy)
				await _frames(4)
				var name := "%s_%d_%d" % [view, int(cx - 320.0), int(cy - 180.0)]
				await _capture(name)
				lines.append(name)
	# The collision cells, for tools/check_room.py.
	var cells := []
	for layer in get_tree().get_nodes_in_group("solid_tiles"):
		for c in layer.get_used_cells():
			cells.append([c.x, c.y, layer.get_cell_atlas_coords(c).x])
	var cf := FileAccess.open(out_dir + "/cells.json", FileAccess.WRITE)
	cf.store_string(JSON.stringify({"room": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "cells": cells}))
	var f := FileAccess.open(out_dir + "/tiles.txt", FileAccess.WRITE)
	f.store_string("%d %d\n" % [int(size.x), int(size.y)] + "\n".join(lines) + "\n")


# --- Measure -------------------------------------------------------------------------------

func _measure() -> void:
	var lines := []
	# Standing jump, held.
	_place(40.0, 28)
	await _frames(10)
	var floor_y := kleo.global_position.y
	_press("jump")
	var top := floor_y
	for i in 90:
		await get_tree().physics_frame
		top = min(top, kleo.global_position.y)
	_release_all()
	var rise := floor_y - top
	lines.append("standing jump rise: %.1f px = %.2f tiles" % [rise, rise / TILE])
	# Tapped jump.
	_place(40.0, 28)
	await _frames(10)
	_press("jump")
	await get_tree().physics_frame
	_release_all()
	top = floor_y
	for i in 90:
		await get_tree().physics_frame
		top = min(top, kleo.global_position.y)
	lines.append("tapped jump rise: %.1f px = %.2f tiles" % [floor_y - top, (floor_y - top) / TILE])
	# Running jump: full speed, jump, hold right until she lands at the same height.
	_place(32.0, 28)
	await _frames(6)
	_press("move_right")
	for i in 40:
		await get_tree().physics_frame
	var x0 := kleo.global_position.x
	_press("jump")
	var airborne := false
	var x1 := x0
	for i in 120:
		await get_tree().physics_frame
		if not kleo.is_on_floor():
			airborne = true
		elif airborne:
			x1 = kleo.global_position.x
			break
	_release_all()
	lines.append("running jump distance: %.1f px = %.2f tiles (run speed %.0f px/s)" % [x1 - x0, (x1 - x0) / TILE, kleo.run_speed])
	lines.append("ledge reach: a ledge up to %.1f px = %.2f tiles above the floor can be caught" %
		[rise + kleo.ledge_reach_high, (rise + kleo.ledge_reach_high) / TILE])
	# The terrace step: 4 tiles, jump and hold toward it.
	_place(32.0, 28, -1)
	await _frames(6)
	_press("move_left")
	_press("jump")
	var grabbed := false
	var climbed := false
	for i in 200:
		await get_tree().physics_frame
		if kleo.state == Kleo.State.LEDGE_HANG or kleo.state == Kleo.State.LEDGE_CLIMB:
			grabbed = true
		if grabbed and kleo.state == Kleo.State.NORMAL and kleo.is_on_floor():
			climbed = absf(kleo.global_position.y - 24 * TILE) < 1.0
			break
	_release_all()
	lines.append("terrace step (4 tiles): grabbed %s, climbed onto it %s" % [grabbed, climbed])
	# Island -> root shelf: 4 across, 4 up.
	_place(46.5, 21, 1)
	await _frames(6)
	_press("move_right")
	await _frames(4)
	_press("jump")
	grabbed = false
	climbed = false
	for i in 220:
		await get_tree().physics_frame
		if kleo.state == Kleo.State.LEDGE_HANG or kleo.state == Kleo.State.LEDGE_CLIMB:
			grabbed = true
		if grabbed and kleo.state == Kleo.State.NORMAL and kleo.is_on_floor():
			climbed = absf(kleo.global_position.y - 17 * TILE) < 1.0
			break
	_release_all()
	lines.append("island to root shelf (4 across, 4 up): grabbed %s, on the shelf %s" % [grabbed, climbed])
	# Terrace -> island: 3 across, 3 up, running jump.
	_place(26.0, 24, 1)
	await _frames(6)
	_press("move_right")
	await _frames(16)
	_press("jump")
	var landed_y := 0.0
	for i in 120:
		await get_tree().physics_frame
		if kleo.is_on_floor() and kleo.global_position.x > 33 * TILE:
			landed_y = kleo.global_position.y
			break
		if kleo.state == Kleo.State.LEDGE_CLIMB or kleo.state == Kleo.State.LEDGE_HANG:
			landed_y = -1.0
	_release_all()
	lines.append("terrace to island: %s" % ("landed on it" if absf(landed_y - 21 * TILE) < 1.0 else ("caught the ledge" if landed_y < 0 else "missed (y %.0f)" % landed_y)))
	var text := "\n".join(lines)
	print(text)
	var f := FileAccess.open(out_dir + "/measure.txt", FileAccess.WRITE)
	f.store_string(text + "\n")
