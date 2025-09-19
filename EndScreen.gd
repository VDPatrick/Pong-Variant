extends Control

@onready var winner_label: Label = $VBox/Winner
@onready var hint_label: Label   = $VBox/Hint

func show_winner(text: String) -> void:
	winner_label.text = text
	visible = true

func hide_screen() -> void:
	visible = false
