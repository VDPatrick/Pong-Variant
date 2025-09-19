extends Control

signal play_selected
signal reset_selected
signal options_selected
signal video_selected

@onready var play: Label    = $VBoxContainer/Play
@onready var reset: Label   = $VBoxContainer/Reset
@onready var options: Label = $VBoxContainer/Options
@onready var video: Label   = $VBoxContainer/Video
@onready var items: Array[Label] = [play, reset, options, video]

var index: int = 0

func _ready() -> void:
	visible = true
	_update_visuals()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("p1_up"):
		index = (index - 1 + items.size()) % items.size()
		_update_visuals()
	elif Input.is_action_just_pressed("p1_down"):
		index = (index + 1) % items.size()
		_update_visuals()
	elif Input.is_action_just_pressed("confirm"):
		match index:
			0: play_selected.emit()
			1: reset_selected.emit()
			2: options_selected.emit()
			3: video_selected.emit()

func _update_visuals() -> void:
	for i in items.size():
		var lbl: Label = items[i]
		var selected: bool = (i == index)
		lbl.add_theme_color_override("font_color", Color(1, 1, 0) if selected else Color(1, 1, 1))
		lbl.add_theme_font_size_override("font_size", 42 if selected else 36)

# Called from Main.gd to change "Play Game" ↔ "Resume"
func set_play_label(text: String) -> void:
	play.text = text
