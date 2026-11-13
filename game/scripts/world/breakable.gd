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

@onready var art: Sprite2D = $Art
@onready var hurtbox: Area2D = $Hurtbox

var _hits := 0
var _broken := false

static var _images := {}  # texture path -> Image, to skip empty pieces


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
	art.position.x += 1.0
	tw.parallel().tween_property(art, "position:x", art.position.x - 1.0, 0.1)


func _break(dir: int, power: int) -> void:
	_broken = true
	hurtbox.set_deferred("monitorable", false)
	var r := art.region_rect
	var cols := 3 if r.size.x >= 26.0 else 2
	var rows := 3 if r.size.y >= 26.0 else 2
	var pw := floorf(r.size.x / cols)
	var ph := floorf(r.size.y / rows)
	var img := _image()
	var host := get_parent()
	for i in cols:
		for j in rows:
			var region := Rect2(r.position.x + i * pw, r.position.y + j * ph, pw, ph)
			if img and not _has_pixels(img, region):
				continue
			var piece := Debris.new()
			piece.texture = art.texture
			piece.region_enabled = true
			piece.region_rect = region
			piece.z_index = z_index
			piece.life = randf_range(1.3, 1.9)
			var spread: float = (float(i) - (cols - 1) * 0.5) / maxf(1.0, cols - 1.0)
			var height: float = float(rows - 1 - j) / maxf(1.0, rows - 1.0)  # top pieces fly highest
			piece.velocity = Vector2(
				dir * randf_range(35.0, 95.0) * (0.8 + power * 0.2) + spread * 70.0,
				-randf_range(110.0, 170.0) - height * 90.0)
			host.add_child(piece)
			piece.global_position = (art.global_position + Vector2(i * pw + pw * 0.5, j * ph + ph * 0.5)).round()
	var centre := global_position + Vector2(0, -r.size.y * 0.5)
	Fx.burst(self, centre, chip_color, 10 + power * 3, 110.0)
	Fx.dust(self, global_position, Fx.LANDING, dir)
	queue_free()


func _image() -> Image:
	var tex := art.texture
	if not tex:
		return null
	var key := tex.resource_path
	if not _images.has(key):
		_images[key] = tex.get_image()
	return _images[key]


func _has_pixels(img: Image, region: Rect2) -> bool:
	var count := 0
	for x in range(int(region.position.x), int(region.end.x), 2):
		for y in range(int(region.position.y), int(region.end.y), 2):
			if img.get_pixel(x, y).a > 0.5:
				count += 1
				if count >= 3:
					return true
	return false
