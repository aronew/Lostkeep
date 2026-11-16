class_name Stranger
extends Interactable
## The hooded stranger at the outpost (the Keep's foundations): a wanderer who
## trades in rumours and maps for Resin. Talk (interact) to open: a greeting,
## then a small menu. Up and down choose, interact or jump confirms, attack
## leaves. Rumours are cheap; the map of Ironbark is dear (the creative lead:
## "the map should be expensive ... lore is cheaper").

const PRICE_RUMOUR := 5
const PRICE_MAP := 60

const GREETING_FIRST := "Another one of the Guard, still walking. Most of yours went down, little guard. Few came back up.\nI trade in what I've seen. Resin will do."
const GREETING := "Back again. The dark keeps its secrets; I sell a few."
const RUMOURS := [
	"Some walls down here are only shadow. Watch for dust drifting into the stone, and walk on through.",
	"Smash what your people left behind. Pots and crates still hold a little Resin.",
	"Those cracked bark plates? A heavy shield blow breaks them. Your captain kept such a shield, in the armory under the Keep.",
	"Your people didn't wander off. Something carried them, and it went down, not out.",
	"The lantern at your hip is older than you think. Keep it lit in the deep places.",
]
const NO_MORE := "That's all I'll say for now. Come back when the dark has moved."

var _open := false
var _opened_frame := -1
var _kleo: Node = null
var _choice := 0
var _layer: CanvasLayer
var _panel: PanelContainer
var _text: Label
var _options: Array[Label] = []


func interact(kleo: Node) -> void:
	if _open:
		return
	_kleo = kleo
	kleo.call("freeze")
	_build_ui()
	var first := not Game.flags.has("stranger_met")
	Game.flags["stranger_met"] = true
	_say(GREETING_FIRST if first else GREETING)
	_open = true
	_opened_frame = Engine.get_physics_frames()
	_choice = 0
	_show_choice()


func can_interact(_k: Node) -> bool:
	return not _open


## Keys are read on the physics tick, as Kleo's are, so a quick tap is never
## lost between frames.
func _physics_process(_delta: float) -> void:
	if not _open or Engine.get_physics_frames() == _opened_frame:
		return
	if Input.is_action_just_pressed("move_up"):
		_choice = (_choice + _options.size() - 1) % _options.size()
		_show_choice()
	elif Input.is_action_just_pressed("move_down"):
		_choice = (_choice + 1) % _options.size()
		_show_choice()
	elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
		_confirm()
	elif Input.is_action_just_pressed("attack"):
		_close()


func _confirm() -> void:
	match _choice:
		0:
			var told: int = Game.flags.get("stranger_rumours", 0)
			if told >= RUMOURS.size():
				_say(NO_MORE)
			elif Game.currency < PRICE_RUMOUR:
				_say("A rumour costs %d Resin. You haven't got it." % PRICE_RUMOUR)
			else:
				Game.add_currency(-PRICE_RUMOUR)
				Game.flags["stranger_rumours"] = told + 1
				_say(RUMOURS[told])
		1:
			if Game.flags.has("ironbark_map"):
				_say("You already carry my map. Mind its dark corners.")
			elif Game.currency < PRICE_MAP:
				_say("My map of Ironbark is dear, little guard: %d Resin. Come back richer." % PRICE_MAP)
			else:
				Game.add_currency(-PRICE_MAP)
				Game.flags["ironbark_map"] = true
				_say("Ironbark, as I've walked it. Every room I found, and a few I'd rather not have.")
		2:
			_close()


func _close() -> void:
	_open = false
	if _layer:
		_layer.queue_free()
		_layer = null
	if _kleo:
		_kleo.call("release")
	_kleo = null


func _say(text: String) -> void:
	_text.text = text


func _show_choice() -> void:
	var labels := ["A rumour  (%d Resin)" % PRICE_RUMOUR, "The map of Ironbark  (%d Resin)" % PRICE_MAP, "Farewell"]
	for i in _options.size():
		_options[i].text = ("> " if i == _choice else "   ") + labels[i]
		_options[i].modulate = Color(1.0, 0.85, 0.5) if i == _choice else Color(0.75, 0.72, 0.8)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 85
	add_child(_layer)
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.04, 0.09, 0.92)
	box.border_color = Color(0.55, 0.42, 0.24)
	box.set_border_width_all(1)
	box.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.position = Vector2(80, 230)
	_panel.custom_minimum_size = Vector2(480, 112)
	_layer.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	_panel.add_child(col)
	var name_label := _label("The Hooded Stranger", Color(0.95, 0.69, 0.29))
	col.add_child(name_label)
	_text = _label("", Color(0.92, 0.9, 0.95))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(464, 34)
	col.add_child(_text)
	_options.clear()
	for i in 3:
		var o := _label("", Color.WHITE)
		col.add_child(o)
		_options.append(o)


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.04))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l
