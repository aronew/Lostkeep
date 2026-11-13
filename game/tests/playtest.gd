extends Node
## Test harness: plays the room with scripted input and captures what it sees.
##
##   xvfb-run -a godot --path game --fixed-fps 60 --audio-driver Dummy res://tests/playtest.tscn -- mode=shots
##
## Modes:
##   shots    screenshots of the room's key places, with art and as the black box
##   tour     the main line, scripted, every second frame saved (for a video)
##   upper    the upper line: island, ledge climb, hard landing, knockback
##   map      the whole room in screen-sized tiles, with art and as the black box
##            (stitch with tools/stitch_map.py)
##   measure  measures the jump, running jump and ledge reach; prints the numbers
## Output: tests/out/<mode>/

const ROOM := "res://scenes/rooms/ironbark_test_room.tscn"
const TILE := 16.0

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
	out_dir = "res://tests/out/" + mode
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	room = load(ROOM).instantiate()
	add_child(room)
	kleo = room.get_node("Kleo")
	cam = room.get_node("Camera")
	await _frames(2)
	match mode:
		"shots":
			await _shots()
		"tour":
			await _tour()
		"upper":
			await _upper()
		"map":
			await _map()
		"measure":
			await _measure()
	get_tree().quit()


# --- Helpers ----------------------------------------------------------------------------------

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


func _step() -> void:
	await get_tree().physics_frame
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


# --- Map ---------------------------------------------------------------------------------------

func _map() -> void:
	for n in ["Sky", "Far", "FogFar", "Mid", "FogMid", "Ruins", "Screen", "Kleo"]:
		var node := room.get_node_or_null(n)
		if node:
			node.visible = false
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
		for cx in xs:
			for cy in ys:
				cam.global_position = Vector2(cx, cy)
				await _frames(4)
				var name := "%s_%d_%d" % [view, int(cx - 320.0), int(cy - 180.0)]
				await _capture(name)
				lines.append(name)
	# The collision cells, for tools/check_room.py.
	var solid: TileMapLayer = room.get_node("Solid")
	var cells := []
	for c in solid.get_used_cells():
		cells.append([c.x, c.y, solid.get_cell_atlas_coords(c).x])
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
