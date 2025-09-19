extends Control

signal back_requested
signal points_to_win_changed(value: int)

@onready var rows: Array[HBoxContainer] = [
	$VBox/MasterRow,
	$VBox/VideoRow,
	$VBox/MusicRow,
	$VBox/SfxRow,
	$VBox/PointsRow
]

@onready var master_slider: HSlider = $VBox/MasterRow/Slider
@onready var music_slider:  HSlider = $VBox/MusicRow/Slider
@onready var sfx_slider:    HSlider = $VBox/SfxRow/Slider
@onready var points_slider: HSlider = $VBox/PointsRow/Slider

@onready var master_name: Label = $VBox/MasterRow/Name
@onready var music_name:  Label = $VBox/MusicRow/Name
@onready var sfx_name:    Label = $VBox/SfxRow/Name
@onready var points_name: Label = $VBox/PointsRow/Name

@onready var master_value: Label = $VBox/MasterRow/Value
@onready var music_value:  Label = $VBox/MusicRow/Value
@onready var sfx_value:    Label = $VBox/SfxRow/Value
@onready var points_value: Label = $VBox/PointsRow/Value

@onready var video_slider: HSlider = $VBox/VideoRow/Slider
@onready var video_name:   Label   = $VBox/VideoRow/Name
@onready var video_value:  Label   = $VBox/VideoRow/Value

var index: int = 0
var _points_to_win: int = 5

func _ready() -> void:
	visible = false
	_init_from_buses()
	# hook up sliders
	master_slider.value_changed.connect(func(v: float) -> void: _apply_bus("Master", v))
	video_slider.value_changed.connect(func(v: float) -> void: _apply_bus("Video", v))
	music_slider.value_changed.connect(func(v: float) -> void: _apply_bus("Music", v))
	sfx_slider.value_changed.connect(func(v: float) -> void: _apply_bus("SFX", v))
	points_slider.value_changed.connect(func(v: float) -> void:
		_points_to_win = int(v)
		points_value.text = str(_points_to_win)
		points_to_win_changed.emit(_points_to_win)
	)
	# initial UI
	points_slider.value = _points_to_win
	points_value.text = str(_points_to_win)
	_update_visuals()

func open() -> void:
	visible = true
	_update_visuals()

func close() -> void:
	visible = false

# allow Main.gd to push its current value into the panel
func set_points_to_win(v: int) -> void:
	_points_to_win = clampi(v, 1, 10)
	points_slider.value = _points_to_win
	points_value.text = str(_points_to_win)

func _unhandled_input(_event: InputEvent) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed("p1_up"):
		index = (index - 1 + rows.size()) % rows.size()
		_update_visuals()
	elif Input.is_action_just_pressed("p1_down"):
		index = (index + 1) % rows.size()
		_update_visuals()
	elif Input.is_action_pressed("p1_left"):
		_nudge(-1.0)
	elif Input.is_action_pressed("p1_right"):
		_nudge(1.0)
	elif Input.is_action_just_pressed("back"):
		back_requested.emit()

func _nudge(delta_value: float) -> void:
	var slider: HSlider = rows[index].get_node("Slider") as HSlider
	slider.value = clampf(slider.value + delta_value, slider.min_value, slider.max_value)

func _init_from_buses() -> void:
	_set_slider_from_bus(master_slider, "Master")
	_set_slider_from_bus(video_slider, "Video")
	_set_slider_from_bus(music_slider, "Music")
	_set_slider_from_bus(sfx_slider, "SFX")
	_update_value_labels()

func _set_slider_from_bus(slider: HSlider, bus_name: String) -> void:
	var i: int = AudioServer.get_bus_index(bus_name)
	if i == -1:
		return
	var db: float = AudioServer.get_bus_volume_db(i)
	var lin: float = db_to_linear(db)
	slider.value = roundf(lin * 100.0)

func _apply_bus(bus_name: String, percent: float) -> void:
	var i: int = AudioServer.get_bus_index(bus_name)
	if i == -1:
		return
	var lin: float = clampf(percent / 100.0, 0.0, 1.0)
	var db: float = linear_to_db(max(lin, 0.0001))
	AudioServer.set_bus_volume_db(i, db)
	_update_value_labels()

func _update_value_labels() -> void:
	master_value.text = str(int(master_slider.value)) + "%"
	video_value.text = str(int(video_slider.value)) + "%"
	music_value.text  = str(int(music_slider.value)) + "%"
	sfx_value.text    = str(int(sfx_slider.value)) + "%"

func _update_visuals() -> void:
	var names: Array[Label] = [master_name, video_name, music_name, sfx_name, points_name]
	for i in names.size():
		var selected: bool = (i == index)
		var lbl: Label = names[i]
		lbl.add_theme_color_override("font_color", Color(1, 1, 0) if selected else Color(1, 1, 1))
		lbl.add_theme_font_size_override("font_size", 16 if selected else 16)
