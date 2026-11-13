class_name Fx
extends RefCounted
## One-shot effects cut from Kleo's FX strips: dust, sword arcs and hit sparks.
## Each is a single frame that fades and drifts; arcs and sparks glow (additive,
## unaffected by the room's darkness).

const SMALL := preload("res://assets/characters/kleo/fx_small.png")
const SLASHES := preload("res://assets/characters/kleo/fx_slashes.png")
const PIXEL := preload("res://assets/fx/pixel.png")

# fx_small cells
const SPARK_STAR := 0
const SPARK_RING := 1
const RUN := 2
const SKID := 3
const LANDING := 4
const HARD_LANDING := 5
const JUMP := 6
const BASH := 7
# fx_slashes cells
const ARC_1 := 0
const ARC_2 := 1
const ARC_3 := 2
const ARC_SPIN := 3
const ARC_SLAM := 4
const ARC_UP := 5
const ARC_AIR := 6
const ARC_DOWN := 7

## How far above the feet each dust cell's centre sits (the cells are centred).
const DUST_LIFT := {RUN: 4.0, SKID: 4.0, LANDING: 4.0, HARD_LANDING: 6.0, JUMP: 5.0, BASH: 8.0}


static func _host(from: Node) -> Node:
	var scene := from.get_tree().current_scene
	return scene if scene else from.get_tree().root


static func _cell(from: Node, tex: Texture2D, index: int, pos: Vector2, flip: bool, life: float,
		drift: Vector2, glow: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = Rect2(index * 64, 0, 64, 64)
	s.flip_h = flip
	s.z_index = 15
	if glow:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		s.material = m
	_host(from).add_child(s)
	s.global_position = pos.round()
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "modulate:a", 0.0, life).set_ease(Tween.EASE_IN)
	tw.tween_property(s, "position", s.position + drift, life).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(s.queue_free)
	return s


## Dust at a pair of feet.
static func dust(from: Node, feet: Vector2, kind: int, facing: int) -> void:
	var drift := Vector2(-facing * 6.0, -3.0)
	if kind == SKID:
		drift = Vector2(facing * 8.0, -2.0)
	elif kind in [LANDING, HARD_LANDING]:
		drift = Vector2(0, -2.0)
	_cell(from, SMALL, kind, feet - Vector2(0, DUST_LIFT.get(kind, 4.0)), facing < 0, 0.35, drift, false)


## A sword arc that flashes and fades.
static func arc(from: Node, pos: Vector2, index: int, facing: int) -> void:
	_cell(from, SLASHES, index, pos, facing < 0, 0.16, Vector2(facing * 4.0, 0), true)


## The flash where a hit lands, with a burst of sparks.
static func spark(from: Node, pos: Vector2) -> void:
	_cell(from, SMALL, SPARK_STAR, pos, false, 0.14, Vector2.ZERO, true)
	_cell(from, SMALL, SPARK_RING, pos, false, 0.22, Vector2.ZERO, true)
	burst(from, pos, Color(1.0, 0.86, 0.55), 10, 120.0)


## A one-shot burst of pixel particles (sparks, wood chips).
static func burst(from: Node, pos: Vector2, color: Color, amount: int, speed: float) -> void:
	var p := CPUParticles2D.new()
	p.texture = PIXEL
	p.emitting = false
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 420)
	p.color = color
	p.z_index = 16
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = m
	_host(from).add_child(p)
	p.global_position = pos.round()
	p.emitting = true
	p.finished.connect(p.queue_free)
