class_name LanternLight
extends PointLight2D
## A lantern's warm light, breathing with a slow, irregular flicker.

@export var flicker := 0.12
@export var speed := 1.0

var _base := 1.0
var _noise := FastNoiseLite.new()
var _t := 0.0


func _ready() -> void:
	_base = energy
	_noise.seed = randi()
	_noise.frequency = 1.6
	_t = randf() * 100.0


func _process(delta: float) -> void:
	_t += delta * speed
	energy = _base * (1.0 + _noise.get_noise_1d(_t) * flicker)
