extends CanvasItem
## Slowly pulses this item's alpha: for glints and other things that should
## catch the eye without being explained.

@export var period := 2.6
@export var low := 0.0
@export var high := 1.0

var _t := randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	var k := 0.5 + 0.5 * sin(_t * TAU / period)
	modulate.a = lerp(low, high, k * k)
