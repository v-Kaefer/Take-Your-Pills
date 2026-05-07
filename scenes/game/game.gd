extends Node2D
class_name Game

const DEFAULT_RUN_SPEED := 240.0

enum GameState { RUNNING, PAUSED, GAME_OVER }

@onready var player: Player = $Player
@onready var state_label: Label = $HUD/StateLabel
@onready var restart_button: Button = $HUD/RestartButton

var current_state: GameState = GameState.RUNNING


func _ready() -> void:
	_ensure_input_actions()
	restart_button.pressed.connect(_on_restart_button_pressed)
	player.set_run_speed(DEFAULT_RUN_SPEED)
	player.start_run()
	player.primary_action_requested.connect(_on_player_primary_action_requested)
	_update_state_label()


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

	_update_state_label()


func _set_game_over() -> void:
	current_state = GameState.GAME_OVER
	player.end_run()
	_update_state_label()


func _on_player_primary_action_requested() -> void:
	_update_state_label("Primary action accepted")


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


func _update_state_label(extra_note: String = "") -> void:
	var state_text := "RUNNING"
	if current_state == GameState.PAUSED:
		state_text = "PAUSED"
	elif current_state == GameState.GAME_OVER:
		state_text = "GAME OVER"

	var control_note := "%s: primary | Esc: pause | Backspace: game over" % [player.primary_action_name]
	if extra_note.is_empty():
		state_label.text = "%s\n%s\nRestart: button" % [state_text, control_note]
	else:
		state_label.text = "%s\n%s\n%s\nRestart: button" % [state_text, extra_note, control_note]


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
