extends Node2D
class_name Game

const DEFAULT_SCROLL_SPEED := 240.0

enum GameState { MAIN_MENU, RUNNING, PAUSED, GAME_OVER }

@onready var player: Player = $World/Player
@onready var chunks: ChunkManager = $World/Chunks
@onready var hud: GameHUD = $HUD
@onready var collect_sfx_player: AudioStreamPlayer = $CollectSfxPlayer
@onready var run_session_controller = $Controllers/RunSessionController
@onready var run_score_controller = $Controllers/RunScoreController
@onready var adverse_state_controller = $Controllers/AdverseStateController
@onready var collectable_audio_controller = $Controllers/CollectableAudioController

var current_state: int:
	get:
		if run_session_controller == null:
			return GameState.MAIN_MENU

		return int(run_session_controller.current_state)

var score: int:
	get:
		if run_score_controller == null:
			return 0

		return run_score_controller.score

var distance: float:
	get:
		if run_score_controller == null:
			return 0.0

		return run_score_controller.distance


func _ready() -> void:
	_ensure_input_actions()

	run_session_controller.player = player
	run_session_controller.chunks = chunks
	run_session_controller.default_scroll_speed = DEFAULT_SCROLL_SPEED

	run_score_controller.chunks = chunks

	adverse_state_controller.chunk_manager = chunks
	adverse_state_controller.base_speed = DEFAULT_SCROLL_SPEED

	collectable_audio_controller.audio_player = collect_sfx_player

	hud.connect_start(run_session_controller.start_run)
	hud.connect_resume(run_session_controller.resume_run)
	hud.connect_restart(_restart_run)

	run_session_controller.boot()


func _process(delta: float) -> void:
	if adverse_state_controller != null:
		adverse_state_controller.tick(delta)
	if run_score_controller != null:
		run_score_controller.tick(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		run_session_controller.toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("game_over_debug"):
		if run_session_controller.is_running():
			run_session_controller.end_run()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(player.jump_action_name):
		if run_session_controller.is_main_menu():
			run_session_controller.start_run()
		elif run_session_controller.is_game_over():
			_restart_run()
		elif run_session_controller.is_running():
			player.request_jump()
		get_viewport().set_input_as_handled()
		return


func _start_run() -> void:
	run_session_controller.start_run()


func _toggle_pause() -> void:
	run_session_controller.toggle_pause()


func _set_game_over() -> void:
	run_session_controller.end_run()


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
