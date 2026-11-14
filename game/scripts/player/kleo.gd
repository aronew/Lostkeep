class_name Kleo
extends CharacterBody2D
## Kleo of the Ironbark Guard.
##
## Base kit: run, a variable-height jump with coyote time and buffering, a ledge
## grab that climbs through a handstand, and a four-hit sword combo that steps
## her forward with every swing, plus up, air and down strikes. All numbers are
## in pixels; one tile is 16 px. The measured envelope is in design/pillars.md.

enum State { NORMAL, ATTACK, LEDGE_HANG, LEDGE_CLIMB, HURT, REST, LOCKED }

const TILE := 16.0
const HALF_W := 5.0
## Where her node sits while hanging, relative to the ledge corner: her hands
## grip the corner in the hang frames.
const HANG := Vector2(6.0, 50.0)

@export_group("Run")
@export var run_speed := 140.0
@export var ground_accel := 1700.0
@export var ground_decel := 2100.0
@export var air_accel := 1200.0
@export var air_decel := 650.0

@export_group("Jump")
@export var jump_velocity := 312.0
@export var gravity_up := 864.0
@export var gravity_down := 1150.0
## Near the top of a held jump gravity eases, for a moment of hang time.
@export var apex_speed := 40.0
@export var apex_gravity := 0.55
## Releasing jump early keeps this share of the upward speed.
@export var jump_cut := 0.45
@export var max_fall := 330.0
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12
## Falls longer than this (px) end in a hard landing.
@export var hard_landing := 120.0

@export_group("Ledge")
## A ledge can be caught when its top is between these heights above her feet.
@export var ledge_reach_low := 12.0
@export var ledge_reach_high := 30.0

@export_group("Combat")
@export var attack_buffer_time := 0.22

## Each attack: hit windows (animation frames), the hitbox (facing right, origin
## at her feet), forward lunges {frame: speed}, the frame from which the next hit
## can chain, the frame from which moving cancels it, and how hard it lands.
const ATTACKS := {
	"attack_1": {"hits": [[3, 5]], "box": Rect2(0, -34, 38, 30), "lunge": {3: 190.0, 6: 0.0},
		"chain": 6, "cancel": 8, "stop": 0.045, "shake": 0.10, "power": 1},
	"attack_2": {"hits": [[3, 4]], "box": Rect2(0, -40, 38, 36), "lunge": {3: 190.0, 5: 0.0},
		"chain": 6, "cancel": 8, "stop": 0.05, "shake": 0.12, "power": 1},
	"attack_3": {"hits": [[5, 6]], "box": Rect2(-2, -46, 38, 46), "lunge": {5: 240.0, 7: 0.0},
		"chain": 8, "cancel": 9, "stop": 0.07, "shake": 0.22, "power": 2},
	"attack_4": {"hits": [[2, 2], [7, 9], [12, 12]], "box": Rect2(-16, -46, 58, 48),
		"lunge": {1: 110.0, 7: 150.0, 11: 0.0}, "chain": -1, "cancel": 14, "stop": 0.11, "shake": 0.45, "power": 3},
	"attack_up": {"hits": [[1, 2]], "box": Rect2(-14, -62, 28, 42), "lunge": {},
		"chain": -1, "cancel": 3, "stop": 0.04, "shake": 0.08, "power": 1},
	"attack_air": {"hits": [[1, 1]], "box": Rect2(0, -32, 36, 26), "lunge": {},
		"chain": -1, "cancel": 3, "stop": 0.04, "shake": 0.08, "power": 1},
	"attack_down": {"hits": [[1, 2]], "box": Rect2(-10, -8, 20, 30), "lunge": {},
		"chain": -1, "cancel": 3, "stop": 0.04, "shake": 0.08, "power": 1},
}
const COMBO := ["attack_1", "attack_2", "attack_3", "attack_4"]

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Shape
@onready var interact_area: Area2D = $Interact

var state := State.NORMAL
var facing := 1
var solid: TileMapLayer  # the rock; shares its grid with the mass layer
var _solids: Array[TileMapLayer] = []
var last_safe := Vector2.ZERO

var _input_x := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _attack_buffer := 0.0
var _jump_held := false
var _jumping := false  # rising from a jump that can still be cut short
var _air_top := 0.0
var _was_on_floor := true
var _lock := 0.0
var _idle_time := 0.0
var _turning := false
var _attack := ""
var _combo := -1
var _hit_window := -1
var _hit_done := {}
var _drop := 0.0  # dropping through a one-way platform
var _queued := false  # the next combo hit, pressed during this one
var _kb_flew := false  # the knockback has left the ground
var _ledge_corner := Vector2.ZERO
var _ledge_dir := 1
var _toward_time := 0.0
var _invuln := 0.0
var _rest_shrine: Node = null
var _safe_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	sprite.frame_changed.connect(_on_frame)
	sprite.animation_finished.connect(_on_animation_finished)
	for layer in get_tree().get_nodes_in_group("solid_tiles"):
		_solids.append(layer)
	if not _solids.is_empty():
		solid = _solids[0]
	last_safe = global_position
	_air_top = global_position.y
	_play("idle")


# --- Frame loop -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_input_x = Input.get_axis("move_left", "move_right")
	_coyote = max(_coyote - delta, 0.0)
	_jump_buffer = max(_jump_buffer - delta, 0.0)
	_attack_buffer = max(_attack_buffer - delta, 0.0)
	_lock = max(_lock - delta, 0.0)
	if _drop > 0.0:
		_drop -= delta
		if _drop <= 0.0:
			set_collision_mask_value(7, true)
	_invuln = max(_invuln - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	if Input.is_action_just_pressed("attack"):
		_attack_buffer = attack_buffer_time
		if state == State.ATTACK and sprite.frame >= 1:
			_queued = true  # mashing through a long wind-up still chains
	_jump_held = Input.is_action_pressed("jump")
	sprite.modulate.a = 0.45 if _invuln > 0.0 and int(_invuln * 20.0) % 2 == 0 else 1.0

	match state:
		State.NORMAL:
			_normal(delta)
		State.ATTACK:
			_attacking(delta)
		State.LEDGE_HANG:
			_hanging(delta)
		State.LEDGE_CLIMB:
			pass  # the animation drives it
		State.HURT:
			_hurting(delta)
		State.REST:
			_resting()
		State.LOCKED:
			velocity = Vector2.ZERO

	sprite.flip_h = facing < 0


func _gravity(delta: float, scale := 1.0) -> void:
	var g := gravity_down if velocity.y > 0.0 else gravity_up
	if _jump_held and absf(velocity.y) < apex_speed and state == State.NORMAL:
		g *= apex_gravity
	velocity.y = min(velocity.y + g * scale * delta, max_fall)


func _horizontal(delta: float, control := 1.0) -> void:
	var target := _input_x * run_speed
	var on_floor := is_on_floor()
	var accel := (ground_accel if on_floor else air_accel) if _input_x != 0.0 else (ground_decel if on_floor else air_decel)
	velocity.x = move_toward(velocity.x, target, accel * control * delta)


func _normal(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		_coyote = coyote_time
	# Facing and the turn on the run.
	if _input_x != 0.0 and _lock <= 0.0:
		var dir := int(signf(_input_x))
		if dir != facing:
			if on_floor and absf(velocity.x) > 90.0 and sprite.animation == "run":
				_turning = true
				_play("turn")
			elif not _turning:
				facing = dir
	_horizontal(delta, 0.0 if _lock > 0.0 else (0.35 if _turning else 1.0))
	if _turning:
		velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)

	# Drop through a one-way platform: hold down and jump.
	if on_floor and _jump_buffer > 0.0 and Input.is_action_pressed("move_down") and _on_one_way():
		_jump_buffer = 0.0
		_coyote = 0.0
		_drop = 0.22
		set_collision_mask_value(7, false)
		global_position.y += 2.0
		_air_top = global_position.y
	# Jump.
	if _jump_buffer > 0.0 and _coyote > 0.0 and _lock <= 0.0:
		_jump_buffer = 0.0
		_coyote = 0.0
		velocity.y = -jump_velocity
		_jumping = true
		_turning = false
		_play("jump", true)
		Fx.dust(self, global_position, Fx.JUMP, facing)
	# Letting go early cuts the rise, once.
	if _jumping and not _jump_held and velocity.y < -100.0:
		velocity.y *= jump_cut
		_jumping = false
	if velocity.y >= 0.0:
		_jumping = false
	_gravity(delta)

	# Attack.
	if _attack_buffer > 0.0 and _lock <= 0.0:
		_attack_buffer = 0.0
		if Input.is_action_pressed("move_up"):
			_start_attack("attack_up")
			return
		if not on_floor and Input.is_action_pressed("move_down"):
			_start_attack("attack_down")
			return
		if not on_floor:
			_start_attack("attack_air")
			return
		_combo = 0
		_start_attack(COMBO[0])
		return

	# Interact.
	if on_floor and _lock <= 0.0 and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("move_up")):
		if _try_interact():
			return

	if not on_floor and velocity.y > -60.0 and _try_ledge():
		return

	move_and_slide()
	_after_move()
	_choose_animation()


func _after_move() -> void:
	var on_floor := is_on_floor()
	if not on_floor:
		_air_top = min(_air_top, global_position.y)
	if on_floor and not _was_on_floor:
		var fall := global_position.y - _air_top
		if fall > hard_landing:
			_play("land_hard", true)
			_lock = 0.34
			velocity.x = 0.0
			Game.shake(0.28)
			Fx.dust(self, global_position, Fx.HARD_LANDING, facing)
		else:
			_play("land", true)
			Fx.dust(self, global_position, Fx.LANDING, facing)
	if on_floor:
		_air_top = global_position.y
		_safe_timer -= get_physics_process_delta_time()
		if _safe_timer <= 0.0 and _standing_on_tiles():
			last_safe = global_position
			_safe_timer = 0.2
	_was_on_floor = on_floor


func _on_one_way() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var body := c.get_collider() as CollisionObject2D
		if body and c.get_normal().y < -0.5 and body.get_collision_layer_value(7):
			return true
	return false


func _standing_on_tiles() -> bool:
	if not solid:
		return true
	return _solid_at(solid.local_to_map(solid.to_local(global_position + Vector2(0, 2))))


func _choose_animation() -> void:
	var a := sprite.animation
	var busy := sprite.is_playing() and a in ["land", "land_hard", "run_stop", "run_start", "turn", "idle_yawn", "jump", "interact"]
	if is_on_floor():
		var moving := absf(velocity.x) > 12.0 or _input_x != 0.0
		if a == "land_hard" and busy:
			return
		if moving:
			_idle_time = 0.0
			if _turning or (a == "turn" and busy):
				return
			if a in ["idle", "idle_yawn", "run_stop"] and _input_x != 0.0:
				_play("run_start")
			elif not (a == "run_start" and busy):
				_play("run")  # landing while moving goes straight into the run
		else:
			if a == "run" and absf(velocity.x) <= 12.0 and _input_x == 0.0:
				_play("run_stop")
				Fx.dust(self, global_position, Fx.SKID, facing)
				return
			if busy and a != "jump":
				return
			_idle_time += get_physics_process_delta_time()
			if _idle_time > 8.0 and a == "idle":
				_play("idle_yawn")
				_idle_time = -14.0
			elif a != "idle_yawn":
				_play("idle")
	else:
		_idle_time = 0.0
		if velocity.y < 0.0:
			if a != "jump" and a != "jump_apex":
				_play("jump", true)
				sprite.frame = 2
			if absf(velocity.y) < 70.0 and a == "jump" and not busy:
				_play("jump_apex")
		elif a not in ["jump_apex"] or not sprite.is_playing():
			_play("fall")


# --- Attacks ----------------------------------------------------------------------

func _start_attack(name: String, from_frame := 0) -> void:
	state = State.ATTACK
	_attack = name
	_queued = false
	_hit_window = -1
	_hit_done.clear()
	_turning = false
	if _input_x != 0.0 and from_frame == 0:
		facing = int(signf(_input_x))
	var box: Rect2 = ATTACKS[name]["box"]
	(hitbox_shape.shape as RectangleShape2D).size = box.size
	_place_hitbox()
	_play(name, true)
	sprite.frame = from_frame
	_on_frame()
	if name == "attack_up":
		Fx.arc(self, global_position + Vector2(facing * 2, -30), Fx.ARC_UP, facing)
	elif name == "attack_air":
		Fx.arc(self, global_position + Vector2(facing * 16, -18), Fx.ARC_AIR, facing)
	elif name == "attack_down":
		Fx.arc(self, global_position + Vector2(0, 4), Fx.ARC_DOWN, facing)


func _place_hitbox() -> void:
	if _attack == "":
		return
	var box: Rect2 = ATTACKS[_attack]["box"]
	hitbox_shape.position = Vector2((box.position.x + box.size.x * 0.5) * facing, box.position.y + box.size.y * 0.5)


func _attacking(delta: float) -> void:
	var data: Dictionary = ATTACKS[_attack]
	var frame := sprite.frame
	var on_floor := is_on_floor()
	# Ground attacks lunge and then brake; air attacks keep a little control.
	if _attack.begins_with("attack_") and _attack in COMBO:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	else:
		_horizontal(delta, 0.6)
	if _attack == "attack_4":
		_finisher_motion(frame, delta)
	else:
		_gravity(delta, 1.0)
	move_and_slide()
	# Air attacks end when she lands.
	if _attack in ["attack_air", "attack_down", "attack_up"] and is_on_floor() and not _was_on_floor:
		_was_on_floor = true
		_end_attack()
		_play("land", true)
		return
	_was_on_floor = is_on_floor()
	_check_hits(data, frame)
	# Chain the combo.
	if _combo >= 0 and data["chain"] >= 0 and frame >= data["chain"] and (_attack_buffer > 0.0 or _queued) and on_floor:
		_attack_buffer = 0.0
		_queued = false
		_combo += 1
		if _combo < COMBO.size():
			_start_attack(COMBO[_combo], 1)
			return
	# Cancel the recovery into movement or a jump.
	if frame >= data["cancel"] and (_input_x != 0.0 or _jump_buffer > 0.0):
		_end_attack()


func _finisher_motion(frame: int, delta: float) -> void:
	if frame <= 0:
		_gravity(delta)
	elif frame <= 6:
		_gravity(delta, 0.32)  # the spin floats
	elif frame <= 10:
		velocity.y = max(velocity.y, 380.0)  # the dive
		if is_on_floor() and frame < 11:
			sprite.frame = 11
	else:
		_gravity(delta)
		if not is_on_floor() and frame == 11:
			sprite.frame = 10


func _on_frame() -> void:
	if state != State.ATTACK or _attack == "":
		_frame_fx()
		return
	var data: Dictionary = ATTACKS[_attack]
	var frame := sprite.frame
	var lunge: Dictionary = data["lunge"]
	if lunge.has(frame):
		velocity.x = facing * float(lunge[frame])
	if _attack == "attack_4":
		match frame:
			1:
				velocity.y = -250.0
				Fx.dust(self, global_position, Fx.JUMP, facing)
			2:
				Fx.arc(self, global_position + Vector2(facing * 4, -22), Fx.ARC_SPIN, facing)
			7:
				Fx.arc(self, global_position + Vector2(facing * 14, -10), Fx.ARC_SLAM, facing)
			12:
				Game.shake(data["shake"])
				Fx.dust(self, global_position + Vector2(facing * 14, 0), Fx.HARD_LANDING, facing)
				Fx.dust(self, global_position + Vector2(facing * 14, 0), Fx.BASH, facing)
	elif _attack == "attack_3" and frame == 6:
		Fx.dust(self, global_position + Vector2(facing * 18, 0), Fx.LANDING, facing)
	elif _attack in COMBO and frame == 3:
		Fx.dust(self, global_position, Fx.RUN, facing)


func _check_hits(data: Dictionary, frame: int) -> void:
	var windows: Array = data["hits"]
	var window := -1
	for i in windows.size():
		if frame >= windows[i][0] and frame <= windows[i][1]:
			window = i
	if window < 0:
		return
	if window != _hit_window:
		_hit_window = window
		_hit_done.clear()
	_place_hitbox()
	for area in hitbox.get_overlapping_areas():
		var target := area.get_parent()
		if _hit_done.has(target) or not target.has_method("take_hit"):
			continue
		_hit_done[target] = true
		var hit := {"dir": facing, "power": data["power"], "attack": _attack,
			"pos": area.global_position.lerp(global_position + Vector2(facing * 14, -16), 0.5)}
		if target.take_hit(hit):
			# Props ask for a lighter impact than things that fight back.
			var weight: float = target.get("hit_weight") if "hit_weight" in target else 1.0
			Game.hitstop(data["stop"] * weight)
			Game.shake(data["shake"] * 0.6 * weight)
			Fx.spark(self, hit["pos"])
			if _attack == "attack_down":
				velocity.y = -280.0  # pogo
				_end_attack()
				_play("jump", true)
				sprite.frame = 2
				return


func _end_attack() -> void:
	state = State.NORMAL
	_queued = false
	_attack = ""
	_combo = -1
	_hit_window = -1


# --- Ledges -----------------------------------------------------------------------

func _solid_at(c: Vector2i) -> bool:
	for layer in _solids:
		if layer.get_cell_source_id(c) != -1:
			return true
	return false


func _cell(p: Vector2) -> Vector2i:
	return solid.local_to_map(solid.to_local(p)) if solid else Vector2i.ZERO


func _try_ledge() -> bool:
	if solid == null or Input.is_action_pressed("move_down"):
		return false
	var dir := 0
	if _input_x != 0.0:
		dir = int(signf(_input_x))
	elif absf(velocity.x) > 40.0:
		dir = int(signf(velocity.x))
	if dir == 0:
		return false
	var feet := global_position.y
	var front := _cell(global_position + Vector2(dir * (HALF_W + 2.0), 0.0))
	var own := _cell(global_position)
	for row in range(_cell(Vector2(0, feet - ledge_reach_high)).y, _cell(Vector2(0, feet - ledge_reach_low)).y + 1):
		var top := solid.to_global(solid.map_to_local(Vector2i(0, row))).y - TILE * 0.5
		if top < feet - ledge_reach_high or top > feet - ledge_reach_low:
			continue
		var ledge := Vector2i(front.x, row)
		if not _solid_at(ledge) or _solid_at(ledge + Vector2i.UP) or _solid_at(ledge + Vector2i(0, -2)):
			continue
		# Room to hang below the ledge and to climb past it.
		var clear := true
		for r in range(row - 2, row + 4):
			if _solid_at(Vector2i(own.x, r)):
				clear = false
		if not clear:
			continue
		var edge_x := solid.to_global(solid.map_to_local(ledge)).x - dir * TILE * 0.5
		_grab(Vector2(edge_x, top), dir)
		return true
	return false


func _grab(corner: Vector2, dir: int) -> void:
	state = State.LEDGE_HANG
	_ledge_corner = corner
	_ledge_dir = dir
	facing = dir
	velocity = Vector2.ZERO
	global_position = corner + Vector2(-dir * HANG.x, HANG.y)
	_toward_time = 0.0
	_play("ledge_grab", true)


func _hanging(delta: float) -> void:
	velocity = Vector2.ZERO
	var toward := _input_x * _ledge_dir > 0.0
	_toward_time = _toward_time + delta if toward else 0.0
	if _jump_buffer > 0.0 or Input.is_action_just_pressed("move_up") or _toward_time > 0.16:
		_jump_buffer = 0.0
		state = State.LEDGE_CLIMB
		_play("ledge_climb", true)
	elif Input.is_action_just_pressed("move_down") or _input_x * _ledge_dir < 0.0:
		state = State.NORMAL
		global_position.x -= _ledge_dir * 3.0
		_air_top = global_position.y
		_play("fall")


# --- Being hit, resting, water ------------------------------------------------------

## Take a blow that pushes her in `push_dir` (-1 left, 1 right).
func hurt(push_dir: int, heavy := false) -> void:
	if _invuln > 0.0 or state in [State.LOCKED, State.REST]:
		return
	if push_dir == 0:
		push_dir = -facing
	_end_attack()
	state = State.HURT
	facing = -push_dir
	_invuln = 0.9
	_kb_flew = false
	if heavy:
		velocity = Vector2(push_dir * 120.0, -170.0)
		_play("knockback", true)
		Game.hitstop(0.08)
		Game.shake(0.4)
	else:
		velocity = Vector2(push_dir * 90.0, -40.0)
		_play("hurt", true)
		Game.hitstop(0.05)
		Game.shake(0.18)


func _hurting(delta: float) -> void:
	_gravity(delta)
	var knock := sprite.animation == "knockback"
	var f := sprite.frame
	if is_on_floor() and (_kb_flew or not knock):
		var slide := knock and f >= 4 and f <= 7
		velocity.x = move_toward(velocity.x, 0.0, (380.0 if slide else 1400.0) * delta)
		if slide and Engine.get_physics_frames() % 4 == 0:
			Fx.dust(self, global_position, Fx.SKID, facing)
	move_and_slide()
	if not is_on_floor():
		_kb_flew = true
		if knock and f == 3:
			sprite.frame = 3  # hold the flight pose until she comes down
			sprite.frame_progress = 0.0
	elif knock and _kb_flew and f < 4:
		sprite.frame = 4  # touch down: into the slide
		Fx.dust(self, global_position, Fx.LANDING, facing)
	_was_on_floor = is_on_floor()


func _try_interact() -> bool:
	for area in interact_area.get_overlapping_areas():
		if area.has_method("interact") and area.call("can_interact", self):
			area.call("interact", self)
			return true
	return false


## Reach out and work something: a winch, a lever, a door.
func use_object() -> void:
	_lock = 0.4
	velocity.x = 0.0
	_play("interact", true)


## Kneel at a Prism shrine until the player moves.
func rest_at(shrine: Node) -> void:
	state = State.REST
	_rest_shrine = shrine
	velocity = Vector2.ZERO
	last_safe = global_position
	_play("rest", true)


func _resting() -> void:
	if sprite.animation == "rest" and (_input_x != 0.0 or _jump_buffer > 0.0 or _attack_buffer > 0.0):
		_jump_buffer = 0.0
		_attack_buffer = 0.0
		_play("rest_rise", true)


## Deep water: she can't swim yet, so she is lifted back to safe ground.
func enter_water() -> void:
	if state == State.LOCKED:
		return
	state = State.LOCKED
	velocity = Vector2.ZERO
	Fx.dust(self, global_position + Vector2(0, -2), Fx.LANDING, facing)
	await Game.fade_to(1.0, 0.25)
	global_position = last_safe
	_air_top = global_position.y
	_was_on_floor = true
	_play("idle", true)
	await get_tree().create_timer(0.15).timeout
	await Game.fade_to(0.0, 0.3)
	state = State.NORMAL


# --- Animation ---------------------------------------------------------------------

func _play(anim: String, restart := false) -> void:
	if sprite.animation == anim and sprite.is_playing() and not restart:
		return
	sprite.play(anim)
	if restart:
		sprite.frame = 0
		sprite.frame_progress = 0.0


func _on_animation_finished() -> void:
	match sprite.animation:
		"turn":
			_turning = false
			facing = -facing
			_play("run")
		"ledge_climb":
			state = State.NORMAL
			velocity = Vector2.ZERO
			_was_on_floor = true
			_play("idle")
		"rest_rise":
			state = State.NORMAL
			_play("idle")
		"knockback", "hurt":
			state = State.NORMAL
			_play("idle")
		"idle_yawn":
			_play("idle")
		_:
			if state == State.ATTACK and sprite.animation == _attack:
				_end_attack()


func _frame_fx() -> void:
	var a := sprite.animation
	var f := sprite.frame
	if a == "run" and (f == 1 or f == 7):
		Fx.dust(self, global_position + Vector2(-facing * 6, 0), Fx.RUN, facing)
	elif a == "ledge_climb" and f == 2:
		# The view moves up with her: from now on she is on top of the ledge.
		global_position = _ledge_corner + Vector2(_ledge_dir * 9.0, 0.0)
	elif a == "ledge_climb" and f == 9:
		Fx.dust(self, global_position, Fx.LANDING, facing)


func debug_text() -> String:
	return "%s  %s:%d  v(%d,%d)  floor %s" % [State.keys()[state], sprite.animation, sprite.frame,
		int(velocity.x), int(velocity.y), is_on_floor()]
