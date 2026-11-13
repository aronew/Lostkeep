@tool
class_name BackWall
extends Node2D
## The far wall of an enclosed space (a crypt, a hall, a shaft), drawn behind
## the playfield so the sky and forest don't show through underground rooms.
##
## Each region is a rectangle in tiles. The wall is the material's fill, dimmed,
## with an optional decorative course running along it and a shadow under the
## ceiling.

const TILE := 16

@export var regions: Array[Rect2i] = []:
	set(v):
		regions = v
		queue_redraw()
@export var fill: Texture2D:
	set(v):
		fill = v
		queue_redraw()
@export var brightness := 0.42:
	set(v):
		brightness = v
		queue_redraw()
## A horizontal strip (carved masonry) laid along each region.
@export var course: Texture2D:
	set(v):
		course = v
		queue_redraw()
## How far above each region's floor the course's bottom sits, in pixels.
@export var course_height := 6:
	set(v):
		course_height = v
		queue_redraw()
@export var course_brightness := 0.62:
	set(v):
		course_brightness = v
		queue_redraw()
## Regions shorter than this (in tiles) get no course.
@export var course_min_tiles := 5
## Regions narrower than this (in tiles) get no course: a shaft is bare rock.
@export var course_min_width := 8


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_to_group("box_view")


func set_box_view(on: bool) -> void:
	visible = not on


func _draw() -> void:
	if not fill:
		return
	# Cooler and darker than the playfield, so floors and ledges stand in front.
	var tint := Color(brightness * 0.84, brightness * 0.9, brightness * 1.14)
	for r in regions:
		var px := Rect2(Vector2(r.position * TILE), Vector2(r.size * TILE))
		draw_texture_rect_region(fill, px, px, tint)
		if course and r.size.y >= course_min_tiles and r.size.x >= course_min_width:
			var h := course.get_height()
			var y := px.end.y - course_height - h
			var cr := Rect2(px.position.x, y, px.size.x, h)
			var ct := Color(course_brightness * 0.86, course_brightness * 0.9, course_brightness * 1.12)
			draw_texture_rect_region(course, cr, Rect2(px.position.x, 0, px.size.x, h), ct)
		# A soft shadow under the ceiling and above the floor, in pixel bands.
		for i in range(4):
			var a := 0.34 - i * 0.08
			draw_rect(Rect2(px.position.x, px.position.y + i * 4, px.size.x, 4), Color(0.02, 0.01, 0.04, a))
			draw_rect(Rect2(px.position.x, px.end.y - (i + 1) * 3, px.size.x, 3), Color(0.02, 0.01, 0.04, a * 0.7))
