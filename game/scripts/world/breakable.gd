class_name Breakable
extends Node2D
## A pot, barrel or crate. Kleo's sword breaks it into pieces that tumble,
## bounce and settle, with a puff of dust and a spray of chips.
##
## The node sits at the prop's base (its floor line). `Art` is the sprite;
## `Hurtbox` is the area the sword hits.

@export var hits_to_break := 1
## The colour of the chips: wood for crates and barrels, clay for pots.
@export var chip_color := Color(0.62, 0.44, 0.3)
## Which pieces of the sprite have pixels in them (bit i * rows + j), worked out
## when the room is built so breaking never reads the texture. 0: all of them.
@export var piece_mask := 0
## Props land lighter than things that fight back: Kleo scales her hit-stop and
## screen shake by this.
@export var hit_weight := 0.35

@onready var art: Sprite2D = $Art
@onready var hurtbox: Area2D = $Hurtbox

var _hits := 0
var _broken := false


func _ready() -> void:
	add_to_group("breakable")


func take_hit(hit: Dictionary) -> bool:
	if _broken:
		return false
	_hits += 1
	if _hits < hits_to_break:
		_flash()
		return true
	_break(int(hit.get("dir", 1)), int(hit.get("power", 1)))
	return true


func _flash() -> void:
	var tw := create_tween()
	art.modulate = Color(2.2, 2.2, 2.2)
	tw.tween_property(art, "modulate", Color.WHITE, 0.1)


## How a sprite of this size is cut into pieces (columns, rows).
static func grid_for(size: Vector2) -> Vector2i:
	return Vector2i(3 if size.x >= 26.0 else 2, 3 if size.y >= 26.0 else 2)


func _break(dir: int, power: int) -> void:
	_broken = true
	hurtbox.set_deferred("monitorable", false)
	var r := art.region_rect
	var grid := grid_for(r.size)
	var pw := floorf(r.size.x / grid.x)
	var ph := floorf(r.size.y / grid.y)
	var host := get_parent()
	for i in grid.x:
		for j in grid.y:
			if piece_mask != 0 and not (piece_mask & (1 << (i * grid.y + j))):
				continue
			var piece := Debris.new()
			piece.texture = art.texture
			piece.region_enabled = true
			piece.region_rect = Rect2(r.position.x + i * pw, r.position.y + j * ph, pw, ph)
			piece.z_index = z_index
			piece.life = randf_range(1.3, 1.9)
			var spread: float = (float(i) - (grid.x - 1) * 0.5) / maxf(1.0, grid.x - 1.0)
			var height: float = float(grid.y - 1 - j) / maxf(1.0, grid.y - 1.0)  # top pieces fly highest
			piece.velocity = Vector2(
				dir * randf_range(35.0, 95.0) * (0.8 + power * 0.2) + spread * 70.0,
				-randf_range(110.0, 170.0) - height * 90.0)
			host.add_child(piece)
			piece.global_position = (art.global_position + Vector2(i * pw + pw * 0.5, j * ph + ph * 0.5)).round()
	var centre := global_position + Vector2(0, -r.size.y * 0.5)
	Fx.burst(self, centre, chip_color, 10 + power * 3, 110.0)
	Fx.dust(self, global_position, Fx.LANDING, dir)
	queue_free()
