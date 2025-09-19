extends Node2D

var score_left: int = 0
var score_right: int = 0

@onready var ball := $Ball
@onready var score_left_label: Label = $CanvasLayer/Score/Left
@onready var score_right_label: Label = $CanvasLayer/Score/Right

func _ready() -> void:
	$GoalLeft.body_entered.connect(_on_goal_left)
	$GoalRight.body_entered.connect(_on_goal_right)
	_update_score()

func _on_goal_left(body: Node) -> void:
	if body == ball:
		score_right += 1
		_update_score()
		ball.reset_ball(true)

func _on_goal_right(body: Node) -> void:
	if body == ball:
		score_left += 1
		_update_score()
		ball.reset_ball(true)

func _update_score() -> void:
	score_left_label.text = str(score_left)
	score_right_label.text = str(score_right)
