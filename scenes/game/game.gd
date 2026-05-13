extends Node2D
class_name Game

const DEFAULT_RUN_SPEED := 240.0

enum GameState { RUNNING, PAUSED, GAME_OVER }

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD

var current_state: GameState = GameState.RUNNING
var score: int = 0
var active_note: String = ""


func _ready() -> void:
	_ensure_input_actions()
	hud.connect_restart(_on_restart_button_pressed)
	player.set_run_speed(DEFAULT_RUN_SPEED)
	player.start_run()
	player.primary_action_requested.connect(_on_player_primary_action_requested)
	_update_hud()


func _process(_delta: float) -> void:
	if current_state == GameState.RUNNING:
		# Simple score based on distance
		var new_score = int(player.position.x / 10.0)
		if new_score != score:
			score = new_score
			_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("game_over_debug"):
		_set_game_over()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(player.primary_action_name):
		player.request_primary_action()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if current_state == GameState.GAME_OVER:
		return

	if current_state == GameState.RUNNING:
		current_state = GameState.PAUSED
		player.pause_run()
	else:
		current_state = GameState.RUNNING
		player.start_run()

	_update_hud()


func _set_game_over() -> void:
	current_state = GameState.GAME_OVER
	player.end_run()
	hud.show_game_over()
	_update_hud()


func _on_player_primary_action_requested() -> void:
	active_note = "Primary action accepted"
	_update_hud()
	# Clear note after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if active_note == "Primary action accepted":
		active_note = ""
		_update_hud()


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


func _update_hud() -> void:
	var state_text := "RUNNING"
	if current_state == GameState.PAUSED:
		state_text = "PAUSED"
	elif current_state == GameState.GAME_OVER:
		state_text = "GAME OVER"

	var control_note := "Space: primary | Esc: pause | Backspace: game over"
	hud.update_state(state_text, control_note, active_note)
	hud.update_score(score)


func _ensure_input_actions() -> void:
	_register_key_action(player.primary_action_name, KEY_SPACE)
	_register_key_action("game_pause", KEY_ESCAPE)
	_register_key_action("game_over_debug", KEY_BACKSPACE)


func _register_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	InputMap.action_erase_events(action_name)

	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)
