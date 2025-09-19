extends Node2D

@export var video_stream: VideoStream

enum GameState { MENU, PLAYING, END, VIDEO, COUNTDOWN }

var state: int = GameState.MENU
var has_active_match: bool = false

var score_left: int = 0
var score_right: int = 0
var points_to_win: int = 5

@onready var ball: CharacterBody2D = $Ball
@onready var paddle_left: CharacterBody2D = $PaddleLeft
@onready var paddle_right: CharacterBody2D = $PaddleRight

@onready var score_left_label: Label = $CanvasLayer/Score/Left
@onready var score_right_label: Label = $CanvasLayer/Score/Right
@onready var score_ui: Control = $CanvasLayer/Score

@onready var menu: Control = $CanvasLayer/Menu
@onready var settings_panel: Control = $CanvasLayer/SettingsPanel
@onready var end_screen: Control = $CanvasLayer/EndScreen

# Audio (keep your existing 2D players)
@onready var music: AudioStreamPlayer2D = $Music
@onready var sfx_paddle: AudioStreamPlayer2D = $SfxPaddle
@onready var sfx_wall: AudioStreamPlayer2D = $SfxWall
@onready var sfx_goal: AudioStreamPlayer2D = $SfxGoal

@onready var video_screen: Control = $CanvasLayer/VideoScreen

@onready var countdown_label: Label = $CanvasLayer/Countdown

# Remember starting positions so Reset can restore them
var start_ball_pos: Vector2
var start_left_pos: Vector2
var start_right_pos: Vector2

func _ready() -> void:
	ball.center_ball()   # or the force-center snippet from Option A
	await get_tree().process_frame
	start_ball_pos  = ball.global_position
	start_left_pos  = paddle_left.global_position
	start_right_pos = paddle_right.global_position
	
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
	# renamed to Settings in your UI
	if menu.has_signal("settings_selected"):
		menu.connect("settings_selected", Callable(self, "_on_menu_settings"))
	else:
		if menu.has_signal("options_selected"):
			menu.connect("options_selected", Callable(self, "_on_menu_settings"))
	menu.video_selected.connect(_on_menu_video)

	# Settings panel: back + points_to_win (if present)
	if settings_panel.has_signal("back_requested"):
		settings_panel.connect("back_requested", Callable(self, "_on_settings_back"))
	if settings_panel.has_method("set_points_to_win"):
		settings_panel.call("set_points_to_win", points_to_win)
	if settings_panel.has_signal("points_to_win_changed"):
		settings_panel.connect("points_to_win_changed", Callable(self, "_on_points_to_win_changed"))

	# Ball SFX
	ball.paddle_hit.connect(_on_ball_paddle_hit)
	ball.wall_hit.connect(_on_ball_wall_hit)

	# Start music once (keeps playing across menu/game)
	if music.stream and not music.playing:
		music.play()

	_enter_menu()
	
	if video_screen.has_signal("exit_requested"):
		video_screen.connect("exit_requested", Callable(self, "_on_video_exit"))
	
	if video_screen.has_signal("playback_finished"):
		video_screen.connect("playback_finished", Callable(self, "_on_video_finished"))

func _process(_delta: float) -> void:
	if state == GameState.PLAYING and Input.is_action_just_pressed("back"):
		_enter_menu()
	elif state == GameState.END and Input.is_action_just_pressed("confirm"):
		_return_to_menu_initial()

func _on_points_to_win_changed(v: int) -> void:
	points_to_win = max(1, v)

func _on_goal_left(body: Node) -> void:
	if body == ball and state == GameState.PLAYING:
		score_right += 1
		_update_score()
		sfx_goal.play()
		if _check_win():
			return
		ball.reset_ball(true)

func _on_goal_right(body: Node) -> void:
	if body == ball and state == GameState.PLAYING:
		score_left += 1
		_update_score()
		sfx_goal.play()
		if _check_win():
			return
		ball.reset_ball(true)

func _check_win() -> bool:
	if score_left >= points_to_win:
		_end_game(1)
		return true
	elif score_right >= points_to_win:
		_end_game(2)
		return true
	return false

func _end_game(winner: int) -> void:
	state = GameState.END
	has_active_match = false
	_set_game_active(false)
	score_ui.visible = false
	menu.visible = false
	if end_screen and end_screen.has_method("show_winner"):
		var text: String = ("Player 1 wins!" if winner == 1 else "Player 2 wins!")
		end_screen.call("show_winner", text)

func _return_to_menu_initial() -> void:
	# Hide end screen
	if end_screen and end_screen.has_method("hide_screen"):
		end_screen.call("hide_screen")

	has_active_match = false
	
	# Hard reset positions and scores
	score_left = 0
	score_right = 0
	_update_score()

	ball.global_position = start_ball_pos
	ball.velocity = Vector2.ZERO
	paddle_left.global_position = start_left_pos
	paddle_right.global_position = start_right_pos

	# Back to initial menu (Play Game)
	_enter_menu()

func _update_score() -> void:
	score_left_label.text = str(score_left)
	score_right_label.text = str(score_right)

# --- State / Menu ---

func _enter_menu() -> void:
	state = GameState.MENU
	_set_game_active(false)   # freeze paddles + ball in place
	menu.visible = true
	if music.stream and not music.playing:
		music.play()
	if settings_panel and settings_panel.has_method("close"):
		settings_panel.call("close")
	if end_screen and end_screen.has_method("hide_screen"):
		end_screen.call("hide_screen")
	if menu.has_method("set_play_label"):
		menu.call("set_play_label", ("Resume" if has_active_match else "Play Game"))

func _start_game() -> void:
	# Hide menu, show score UI
	menu.visible = false
	score_ui.visible = true

	# If resuming an active match, skip countdown
	if has_active_match:
		state = GameState.PLAYING
		_set_game_active(true)
		return

	# New match: reset scores and positions, freeze gameplay, then run countdown
	state = GameState.COUNTDOWN
	score_left = 0
	score_right = 0
	_update_score()

	# Reset positions to the saved starting transforms
	ball.global_position = start_ball_pos
	ball.velocity = Vector2.ZERO
	paddle_left.global_position = start_left_pos
	paddle_right.global_position = start_right_pos

	_set_game_active(false)  # freeze paddles + ball during countdown

	# Fire the countdown coroutine
	_do_countdown(3)


func _set_game_active(active: bool) -> void:
	ball.set_physics_process(active)
	paddle_left.set_physics_process(active)
	paddle_right.set_physics_process(active)

# --- Menu callbacks ---

func _on_menu_play() -> void:
	if state == GameState.END:
		_return_to_menu_initial()
		_start_game()
	else:
		_start_game()

func _on_menu_reset() -> void:
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

	_enter_menu()

func _on_menu_settings() -> void:
	menu.visible = false
	if settings_panel:
		settings_panel.call("open")

func _on_settings_back() -> void:
	if settings_panel:
		settings_panel.call("close")
	menu.visible = true

func _on_menu_video() -> void:
	# Enter a dedicated video state (or reuse MENU/PLAYING if you prefer)
	state = GameState.VIDEO  # or a VIDEO state if you have one
	_set_game_active(false)

	# Hide UI
	menu.visible = false
	score_ui.visible = false
	if settings_panel and settings_panel.has_method("close"):
		settings_panel.call("close")
	if end_screen and end_screen.has_method("hide_screen"):
		end_screen.call("hide_screen")

	# Stop menu music during playback
	if music.playing:
		music.stop()

	# Resolve a stream: exported var OR the VideoStreamPlayer's current stream
	var stream: VideoStream = null
	if Engine.is_editor_hint():
		# (optional: avoid editor null spam)
		pass
	if video_stream != null:
		stream = video_stream
	else:
		var player := $CanvasLayer/VideoScreen/Video as VideoStreamPlayer
		if player and player.stream != null:
			stream = player.stream

	# Play (or bail gracefully)
	if stream != null and video_screen and video_screen.has_method("play"):
		video_screen.call("play", stream)
	else:
		push_warning("No video stream found. Assign Main.video_stream or set the VideoStreamPlayer's Stream.")
		# Return to menu and resume music so you're not stuck
		_enter_menu()
		if music.stream and not music.playing:
			music.play()


# --- Ball SFX ---

func _on_ball_paddle_hit() -> void:
	if state == GameState.PLAYING:
		sfx_paddle.play()

func _on_ball_wall_hit() -> void:
	if state == GameState.PLAYING:
		sfx_wall.play()

func _on_video_exit() -> void:
	# Stop video overlay & return to initial menu
	if video_screen and video_screen.has_method("stop_and_hide"):
		video_screen.call("stop_and_hide")
	_return_to_menu_initial()
	# Ensure menu music resumes at the menu
	if music.stream and not music.playing:
		music.play()

func _on_video_finished() -> void:
	# Same behavior as cancel: return to initial menu
	_on_video_exit()

func _do_countdown(seconds: int) -> void:
	countdown_label.visible = true
	for i: int in range(seconds, 0, -1):
		countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false

	# Start actual play
	has_active_match = true
	state = GameState.PLAYING
	_set_game_active(true)
	ball.reset_ball(true)
