extends Control

signal exit_requested
signal playback_finished

@export var hold_seconds: float = 3.0
@export var bus: String = "Video"

@onready var player: VideoStreamPlayer = $Video
@onready var hint: Label = $Hint

var holding: bool = false
var hold_time: float = 0.0

func _ready() -> void:
	visible = false
	set_process(false)
	hint.visible = false
	
	player.bus = bus
	player.finished.connect(_on_video_finished)

func play(stream: VideoStream) -> void:
	player.stream = stream
	player.bus = bus
	visible = true
	set_process(true)
	hint.visible = false
	hold_time = 0.0
	holding = false
	player.play()

func stop_and_hide() -> void:
	player.stop()
	set_process(false)
	hint.visible = false
	visible = false

func _process(delta: float) -> void:
	# Hold-to-cancel using the existing "back" action
	if Input.is_action_pressed("back"):
		if not holding:
			holding = true
			hold_time = 0.0
			hint.visible = true
		hold_time += delta
		if hold_time >= hold_seconds:
			holding = false
			hint.visible = false
			set_process(false)
			exit_requested.emit()
	else:
		if holding:
			holding = false
			hold_time = 0.0
			hint.visible = false

func _on_video_finished() -> void:
	playback_finished.emit()
