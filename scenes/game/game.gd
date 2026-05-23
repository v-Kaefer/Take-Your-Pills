extends Node2D
class_name Game

const DEFAULT_SCROLL_SPEED := 240.0

enum GameState { RUNNING, PAUSED, GAME_OVER }

@onready var player: Player = $World/Player
@onready var chunks: ChunkManager = $World/Chunks
@onready var hud: GameHUD = $HUD
@onready var collect_sfx_player: AudioStreamPlayer = $CollectSfxPlayer

var current_state: GameState = GameState.RUNNING
var score: int = 0


func _ready() -> void:
	_ensure_input_actions()
	RunSignals.player_hit_obstacle.connect(_on_player_hit_obstacle)
	RunSignals.collectable_collected.connect(_on_collectable_collected)
	hud.connect_restart(_on_restart_button_pressed)
	chunks.set_scroll_speed(DEFAULT_SCROLL_SPEED)
	chunks.start_run()
	player.start_run()
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

	if event.is_action_pressed(player.jump_action_name):
		if current_state == GameState.GAME_OVER:
			get_viewport().set_input_as_handled()
			_restart_run()
			return
		elif current_state == GameState.RUNNING:
			player.request_jump()
		get_viewport().set_input_as_handled()
		return


func _toggle_pause() -> void:
	if current_state == GameState.GAME_OVER:
		return

	if current_state == GameState.RUNNING:
		current_state = GameState.PAUSED
		chunks.pause_run()
		player.pause_run()
	else:
		current_state = GameState.RUNNING
		chunks.start_run()
		player.start_run()

	_update_hud()


func _set_game_over() -> void:
	if current_state == GameState.GAME_OVER:
		return

	current_state = GameState.GAME_OVER
	chunks.end_run()
	player.end_run()
	hud.show_game_over()
	_update_hud()


func _on_player_hit_obstacle(_obstacle: Node, _body: Node) -> void:
	_set_game_over()


func _on_collectable_collected(_collectable: Node, _body: Node, score_value: int) -> void:
	if current_state != GameState.RUNNING:
		return

	score += score_value
	collect_sfx_player.play()
	_update_hud()


func _on_restart_button_pressed() -> void:
	_restart_run()


func _restart_run() -> void:
	get_tree().reload_current_scene()


func _update_hud() -> void:
	var state_text := "RUNNING"
	if current_state == GameState.PAUSED:
		state_text = "PAUSED"
	elif current_state == GameState.GAME_OVER:
		state_text = "GAME OVER"

	var control_note := "Jump: %s | Esc: pause | Backspace: game over" % _action_hints(player.jump_action_name)
	if current_state == GameState.GAME_OVER:
		control_note = "Jump: restart | Restart: button"

	hud.update_state(state_text, control_note)
	hud.update_score(score)


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


func _action_hints(action_name: StringName) -> String:
	var labels: Array[String] = []
	for event in InputMap.action_get_events(action_name):
		var key_event := event as InputEventKey
		if key_event == null:
			continue

		var key_label := key_event.as_text_keycode()
		if not key_label.is_empty() and not labels.has(key_label):
			labels.append(key_label)

	if labels.is_empty():
		return "Space"

	return " / ".join(labels)
