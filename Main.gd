extends Node2D

enum GameState { MENU, PLAYING }

var state: int = GameState.MENU
var has_active_match: bool = false

var score_left: int = 0
var score_right: int = 0

@onready var ball: CharacterBody2D = $Ball
@onready var paddle_left: CharacterBody2D = $PaddleLeft
@onready var paddle_right: CharacterBody2D = $PaddleRight

@onready var score_left_label: Label = $CanvasLayer/Score/Left
@onready var score_right_label: Label = $CanvasLayer/Score/Right
@onready var score_ui: Control = $CanvasLayer/Score

@onready var menu: Control = $CanvasLayer/Menu

@onready var music: AudioStreamPlayer2D = $Music
@onready var sfx_paddle: AudioStreamPlayer2D = $SfxPaddle
@onready var sfx_wall: AudioStreamPlayer2D = $SfxWall
@onready var sfx_goal: AudioStreamPlayer2D = $SfxGoal

# Remember starting positions so "Reset Game" can restore them
var start_ball_pos: Vector2
var start_left_pos: Vector2
var start_right_pos: Vector2

func _ready() -> void:
	# Capture initial transforms for a clean reset later
	await get_tree().process_frame
	start_ball_pos  = ball.global_position
	start_left_pos  = paddle_left.global_position
	start_right_pos = paddle_right.global_position

	# Goals
	$GoalLeft.body_entered.connect(_on_goal_left)
	$GoalRight.body_entered.connect(_on_goal_right)
	_update_score()

	# Menu signals
	menu.play_selected.connect(_on_menu_play)
	menu.reset_selected.connect(_on_menu_reset)
	menu.options_selected.connect(_on_menu_options)
	menu.video_selected.connect(_on_menu_video)

	_enter_menu()
	
	ball.paddle_hit.connect(_on_ball_paddle_hit)
	ball.wall_hit.connect(_on_ball_wall_hit)

	# Start music once (keeps playing across menu/game)
	if music.stream and not music.playing:
		music.play()

func _process(_delta: float) -> void:
	if state == GameState.PLAYING and Input.is_action_just_pressed("back"):
		_enter_menu()

func _on_goal_left(body: Node) -> void:
	if body == ball and state == GameState.PLAYING:
		score_right += 1
		_update_score()
		sfx_goal.play()
		ball.reset_ball(true)

func _on_goal_right(body: Node) -> void:
	if body == ball and state == GameState.PLAYING:
		score_left += 1
		_update_score()
		sfx_goal.play()
		ball.reset_ball(true)

func _update_score() -> void:
	score_left_label.text = str(score_left)
	score_right_label.text = str(score_right)

# --- State / Menu ---

func _enter_menu() -> void:
	state = GameState.MENU
	_set_game_active(false)        # freeze paddles + ball in place
	menu.visible = true
	score_ui.visible = false
	if menu.has_method("set_play_label"):
		menu.call("set_play_label", ("Resume" if has_active_match else "Play Game"))

func _start_game() -> void:
	state = GameState.PLAYING
	menu.visible = false
	score_ui.visible = true
	_set_game_active(true)

	if has_active_match:
		# RESUME existing match: do not touch scores or ball
		return

	# NEW MATCH
	score_left = 0
	score_right = 0
	_update_score()
	ball.reset_ball(true)
	has_active_match = true

func _set_game_active(active: bool) -> void:
	ball.set_physics_process(active)
	paddle_left.set_physics_process(active)
	paddle_right.set_physics_process(active)

# --- Menu callbacks ---

func _on_menu_play() -> void:
	_start_game()

func _on_menu_reset() -> void:
	# Reset everything back to startup state and stay in the menu.
	has_active_match = false
	_set_game_active(false)

	# Scores
	score_left = 0
	score_right = 0
	_update_score()

	# Restore positions and stop motion
	ball.global_position = start_ball_pos
	ball.velocity = Vector2.ZERO
	paddle_left.global_position = start_left_pos
	paddle_right.global_position = start_right_pos

	# Ensure we're in MENU and label shows "Play Game"
	_enter_menu()

func _on_menu_options() -> void:
	print("Options selected (TODO)")

func _on_menu_video() -> void:
	print("Play Video selected (TODO)")

func _on_ball_paddle_hit() -> void:
	if state == GameState.PLAYING:
		sfx_paddle.play()

func _on_ball_wall_hit() -> void:
	if state == GameState.PLAYING:
		sfx_wall.play()
