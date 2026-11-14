extends Node
## Test harness: plays the room with scripted input and captures what it sees.
##
##   xvfb-run -a godot --path game --fixed-fps 60 --audio-driver Dummy res://tests/playtest.tscn -- mode=shots
##
## `room=ib02` plays another room (default ib01); its output goes to
## tests/out/<room>/<mode>/. Room IB-02's own modes: tour (the main line), west
## (the upper line, the cave and the secret vault), and doors (IB-01's hall door
## into IB-02 and back). Room IB-03 (`room=ib03`): tour (the main line down the
## hill and out the East door), upper (island, branch, the long drop, the brook)
## and doors (IB-01's terrace into IB-03 and back).
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
	"ib03": "res://scenes/rooms/ironbark_03_guard_post.tscn",
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
	if room_id == "ib03":
		match mode:
			"shots":
				await _shots()
			"map":
				await _map()
			"tour":
				await _tour_ib03()
			"upper":
				await _upper_ib03()
			"doors":
				await _doors_ib03()
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


## IB-01's hall door into IB-02 and straight back.
func _doors() -> void:
	var lines := []
	await _swap_room(ROOMS["ib01"])
	await _frames(2)
	_place(6.0, 37, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return room.name == "IronbarkOldCrypt", 300)
	await _wait(40)
	lines.append("IB-01 hall door leads to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	await _hold_until(["move_right"], func(): return room.name == "IronbarkTestRoom", 300)
	await _wait(40)
	lines.append("and back to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	_release_all()
	_report(lines, "doors")


# --- Room IB-03, the Guard Post -------------------------------------------------------------------

const SHOTS_IB03 := [
	["01_hilltop_start", 14.0, 25, 1],
	["02_hill_brink", 28.0, 25, 1],
	["03_upper_terrace", 38.0, 29, 1],
	["04_well_terrace", 51.0, 33, 1],
	["05_yard_brook", 72.0, 37, 1],
	["06_east_road", 100.0, 37, 1],
	["07_ruin_island", 40.0, 22, 1],
	["08_branch_walk", 62.0, 21, 1],
	["09_branch_end_far_island", 83.0, 21, 1],
	["10_west_road_cut", 8.0, 25, -1],
]


## The main line: from the guardhouse down the three terraces, over the well's
## lid, across the brook, and out the East door into IB-01.
func _tour_ib03() -> void:
	var lines := []
	_start_tour()
	await _wait(30)
	await _hold_until(["move_right"], func(): return _floor_at(29), 400)
	lines.append("hilltop down to the upper terrace: %s" % _floor_at(29))
	await _hold_until(["move_right"], func(): return _floor_at(33), 400)
	lines.append("down to the well terrace: %s" % _floor_at(33))
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 51 * TILE, 200)
	await _wait(20)
	lines.append("the well's lid holds: %s (y %.0f)" % [_floor_at(33), kleo.global_position.y])
	await _hold_until(["move_right"], func(): return _floor_at(37), 400)
	lines.append("down to the yard: %s" % _floor_at(37))
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 75.2 * TILE, 300)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(37) and kleo.global_position.x > 80 * TILE, 200)
	lines.append("jumped the brook: %s (x %.0f)" % [_floor_at(37) and kleo.global_position.x > 80 * TILE, kleo.global_position.x])
	await _hold_until(["move_right"], func(): return room.name != "IronbarkGuardPost", 600)
	await _wait(50)
	lines.append("out the East door into: %s, standing at x %.0f, y %.0f" % [room.name, kleo.global_position.x, kleo.global_position.y])
	_release_all()
	_report(lines, "tour")


## The upper line: back up a terrace (a ledge catch), the hilltop's brink to the
## ruin island, the island to the great branch, along it to its end (the far
## island stays out of reach), and the long drop to the yard. Then the brook.
func _upper_ib03() -> void:
	var lines := []
	_place(38.0, 29, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 31.5 * TILE, 200)
	await _hold_until(["move_left", "jump"], func(): return _floor_at(25), 300)
	lines.append("upper terrace back up to the hilltop (4 tiles, a ledge catch): %s" % _floor_at(25))
	await _hold_until(["move_left"], func(): return kleo.global_position.x < 25 * TILE, 200)
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 29.0 * TILE, 200)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(22), 300)
	lines.append("hilltop to the ruin island (3 across, 3 up): %s (x %.0f)" % [_floor_at(22), kleo.global_position.x])
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 46.2 * TILE, 300)
	await _hold_until(["move_right", "jump"], func(): return _floor_at(21), 300)
	lines.append("island to the great branch (4 across, 1 up): %s (x %.0f)" % [_floor_at(21), kleo.global_position.x])
	await _hold_until(["move_right"], func(): return kleo.global_position.x > 83.5 * TILE, 500)
	await _wait(40)
	await _hold_until(["move_right", "jump"], func(): return kleo.is_on_floor() and kleo.global_position.y > 22 * TILE, 400)
	lines.append("leapt for the far island from the branch's end: landed at x %.0f, y %.0f (the island is x 1552 to 1712, y 288; the yard is y 592)" %
		[kleo.global_position.x, kleo.global_position.y])
	await _wait(40)
	await _hold_until(["move_left"], func(): return kleo.global_position.y > 37 * TILE + 8 or kleo.global_position.x < 70 * TILE, 400)
	await _wait(90)
	lines.append("walked into the brook, returned to safe ground: %s (x %.0f, y %.0f)" % [kleo.is_on_floor(), kleo.global_position.x, kleo.global_position.y])
	_release_all()
	_report(lines, "upper")


## IB-01's terrace west into the Guard Post and straight back.
func _doors_ib03() -> void:
	var lines := []
	await _swap_room(ROOMS["ib01"])
	await _frames(2)
	_place(6.0, 24, -1)
	await _frames(10)
	_start_tour()
	await _hold_until(["move_left"], func(): return room.name == "IronbarkGuardPost", 300)
	await _wait(40)
	lines.append("IB-01 terrace leads to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
		[room.name, kleo.global_position.x, kleo.global_position.y, kleo.facing, kleo.is_on_floor()])
	await _hold_until(["move_right"], func(): return room.name == "IronbarkTestRoom", 300)
	await _wait(40)
	lines.append("and back to: %s; she stands at x %.0f, y %.0f, facing %d, on the floor: %s" %
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
const MAP_HIDDEN := ["Sky", "Far", "FogFar", "Mid", "FogMid", "Ruins", "Foreground", "Screen", "Kleo"]


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
