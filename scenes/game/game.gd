extends Node2D
class_name Game

const DEFAULT_SCROLL_SPEED := 220.0

enum GameState { MAIN_MENU, RUNNING, PAUSED, GAME_OVER }

@onready var player: Player = $World/Player
@onready var chunks: ChunkManager = $World/Chunks
@onready var hud: GameHUD = $HUD
@onready var collect_sfx_player: AudioStreamPlayer = $CollectSfxPlayer
@onready var session_controller = $Controllers/RunSessionController
@onready var score_controller = $Controllers/RunScoreController
@onready var audio_controller = $Controllers/CollectableAudioController
@onready var pacing_controller = $Controllers/RunPacingController
@onready var speed_up_controller := $Controllers/SpeedUpBoostController
@onready var speed_down_controller := $Controllers/SpeedDownBoostController
@onready var ranking_controller = $Controllers/LocalRankingController
@onready var scenario_transition_controller = $Controllers/ScenarioTransitionController
@onready var speed_up_row := $HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedUpContainer
@onready var speed_down_row := $HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedDownContainer

var current_state: GameState:
	get:
		return _get_current_state()

var score: int:
	get:
		return _get_score()

var distance: float:
	get:
		return _get_distance()


func _ready() -> void:
	_ensure_input_actions()
	hud.connect_start(_on_start_button_pressed)
	hud.connect_resume(_on_resume_button_pressed)
	hud.connect_restart(_on_restart_button_pressed)
	session_controller.player = player
	session_controller.chunks = chunks
	session_controller.default_scroll_speed = DEFAULT_SCROLL_SPEED
	score_controller.chunks = chunks
	audio_controller.audio_player = collect_sfx_player
	pacing_controller.session_controller = session_controller
	scenario_transition_controller.chunks = chunks
	speed_up_controller.bar_step.connect(speed_up_row.apply_charge)
	speed_up_controller.bar_reset.connect(speed_up_row.reset_bar)
	speed_down_controller.bar_step.connect(speed_down_row.apply_charge)
	speed_down_controller.bar_reset.connect(speed_down_row.reset_bar)
	speed_up_controller.boost_state_changed.connect(hud.update_boost_timer)
	speed_up_controller.boost_state_changed.connect(session_controller.on_speed_up_boost_state_changed)
	speed_up_controller.boost_state_changed.connect(speed_down_controller.on_speed_up_boost_state_changed)
	speed_down_controller.slow_state_changed.connect(session_controller.on_speed_down_state_changed)
	ranking_controller.score_controller = score_controller
	hud.name_submitted.connect(ranking_controller.save_record)
	session_controller.boot()


func _process(_delta: float) -> void:
	if speed_up_controller != null:
		speed_up_controller.tick(_delta)
	if score_controller != null:
		score_controller.tick(_delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("game_over_debug"):
		if current_state == GameState.RUNNING:
			_set_game_over()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(player.jump_action_name):
		if current_state == GameState.MAIN_MENU:
			get_viewport().set_input_as_handled()
			_start_run()
			return
		if current_state == GameState.GAME_OVER:
			get_viewport().set_input_as_handled()
			_restart_run()
			return
		elif current_state == GameState.RUNNING:
			player.request_jump()
		get_viewport().set_input_as_handled()
		return


func _toggle_pause() -> void:
	session_controller.toggle_pause()


func _start_run() -> void:
	session_controller.start_run()


func _resume_run() -> void:
	session_controller.resume_run()


func _set_game_over() -> void:
	session_controller.end_run()


func _on_start_button_pressed() -> void:
	_start_run()


func _on_resume_button_pressed() -> void:
	_resume_run()


func _on_restart_button_pressed() -> void:
	_restart_run()


func _restart_run() -> void:
	get_tree().reload_current_scene()


func _ensure_input_actions() -> void:
	_register_key_action(player.jump_action_name, [KEY_SPACE, KEY_UP])
	_register_key_action("game_pause", [KEY_ESCAPE])
	_register_key_action("game_over_debug", [KEY_BACKSPACE])


func _register_key_action(action_name: StringName, keycodes: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	InputMap.action_erase_events(action_name)

	for keycode in keycodes:
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)


func _get_current_state() -> GameState:
	if session_controller == null:
		return GameState.MAIN_MENU

	return _map_session_state(session_controller.current_state)


func _map_session_state(session_state: int) -> GameState:
	match session_state:
		GameState.RUNNING:
			return GameState.RUNNING
		GameState.PAUSED:
			return GameState.PAUSED
		GameState.GAME_OVER:
			return GameState.GAME_OVER
		_:
			return GameState.MAIN_MENU


func _get_score() -> int:
	if score_controller == null:
		return 0

	return score_controller.score


func _get_distance() -> float:
	if score_controller == null:
		return 0.0

	return score_controller.distance
