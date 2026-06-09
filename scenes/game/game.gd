extends Node2D
class_name Game

const DEFAULT_SCROLL_SPEED := 240.0
const SCORE_DISTANCE_DIVISOR := 10.0

enum GameState { MAIN_MENU, RUNNING, PAUSED, GAME_OVER }

@onready var player: Player = $World/Player
@onready var chunks: ChunkManager = $World/Chunks
@onready var hud: GameHUD = $HUD
@onready var collect_sfx_player: AudioStreamPlayer = $CollectSfxPlayer
@onready var speed_up_controller := $Controllers/SpeedUpBoostController
@onready var speed_down_controller := $Controllers/SpeedDownBoostController
@onready var speed_up_row := $HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedUpContainer
@onready var speed_down_row := $HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedDownContainer

var current_state: GameState = GameState.MAIN_MENU
var score: int = 0
var distance: float = 0.0
var bonus_score: int = 0
var score_accumulator: float = 0.0
var _last_displayed_distance: int = -1
var _speed_up_active: bool = false
var _speed_up_multiplier: float = 1.0
var _speed_down_multiplier: float = 1.0

const BASE_SCORE_PER_METER := 10.0
var current_scenario_multiplier: float = 1.0
var current_speed_multiplier: float = 1.0


func _ready() -> void:
	_ensure_input_actions()
	RunSignals.player_hit_obstacle.connect(_on_player_hit_obstacle)
	RunSignals.collectable_collected.connect(_on_collectable_collected)
	hud.connect_start(_on_start_button_pressed)
	hud.connect_resume(_on_resume_button_pressed)
	hud.connect_restart(_on_restart_button_pressed)
	speed_up_controller.bar_step.connect(speed_up_row.apply_charge)
	speed_up_controller.bar_reset.connect(speed_up_row.reset_bar)
	speed_down_controller.bar_step.connect(speed_down_row.apply_charge)
	speed_down_controller.bar_reset.connect(speed_down_row.reset_bar)
	speed_up_controller.boost_state_changed.connect(_on_speed_up_boost_state_changed)
	speed_up_controller.boost_state_changed.connect(hud.update_boost_timer)
	speed_up_controller.boost_state_changed.connect(speed_down_controller.on_speed_up_boost_state_changed)
	speed_down_controller.slow_state_changed.connect(_on_speed_down_state_changed)
	speed_down_controller.speed_too_slow.connect(_on_speed_too_slow)
	chunks.pause_run()
	player.pause_run()
	hud.show_main_menu()
	RunSignals.run_booted.emit()
	_apply_scroll_speed()
	_update_hud()


func _process(_delta: float) -> void:
	if speed_up_controller != null:
		speed_up_controller.tick(_delta)
		if current_state == GameState.RUNNING:
			var meters_scrolled := (chunks.scroll_speed * _delta) / SCORE_DISTANCE_DIVISOR
			distance += meters_scrolled

			# Gained points this frame based on distance scrolled and current multipliers
			var points_gained := meters_scrolled * BASE_SCORE_PER_METER * current_scenario_multiplier * current_speed_multiplier
			score_accumulator += points_gained

			var current_dist_int := int(distance)
			var new_score := int(score_accumulator) + bonus_score

			if new_score != score or current_dist_int != _last_displayed_distance:
				score = new_score
				_last_displayed_distance = current_dist_int
			_update_hud()


func add_score(amount: int) -> void:
	bonus_score += amount
	score = int(score_accumulator) + bonus_score
	_update_hud()


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
	if current_state == GameState.MAIN_MENU or current_state == GameState.GAME_OVER:
		return

	if current_state == GameState.RUNNING:
		current_state = GameState.PAUSED
		chunks.pause_run()
		player.pause_run()
		hud.show_pause_menu()
	else:
		_resume_run()

	_update_hud()


func _start_run() -> void:
	if current_state != GameState.MAIN_MENU:
		return

	current_state = GameState.RUNNING
	hud.hide_menus()
	chunks.start_run()
	player.start_run()
	_update_hud()


func _resume_run() -> void:
	if current_state != GameState.PAUSED:
		return

	current_state = GameState.RUNNING
	hud.hide_menus()
	chunks.start_run()
	player.start_run()
	_update_hud()


func _set_game_over() -> void:
	if current_state == GameState.GAME_OVER:
		return

	current_state = GameState.GAME_OVER
	chunks.end_run()
	player.end_run()
	hud.show_game_over(score)
	RunSignals.run_game_over.emit()
	_update_hud()


func _on_player_hit_obstacle(_obstacle: Node, _body: Node) -> void:
	_set_game_over()


func _on_speed_too_slow() -> void:
	_set_game_over()


func _on_speed_up_boost_state_changed(active: bool, _remaining: float, speed_multiplier: float) -> void:
	_speed_up_active = active
	_speed_up_multiplier = speed_multiplier
	_apply_scroll_speed()


func _on_speed_down_state_changed(speed_multiplier: float) -> void:
	_speed_down_multiplier = speed_multiplier
	_apply_scroll_speed()


func _on_collectable_collected(_collectable: Node, _body: Node, score_value: int) -> void:
	if current_state != GameState.RUNNING:
		return

	add_score(score_value)
	collect_sfx_player.play()
	_update_hud()


func _on_start_button_pressed() -> void:
	_start_run()


func _on_resume_button_pressed() -> void:
	_resume_run()


func _on_restart_button_pressed() -> void:
	_restart_run()


func _restart_run() -> void:
	get_tree().reload_current_scene()


func _update_hud() -> void:
	var state_text := "MENU"
	if current_state == GameState.RUNNING:
		state_text = "RUNNING"
	elif current_state == GameState.PAUSED:
		state_text = "PAUSED"
	elif current_state == GameState.GAME_OVER:
		state_text = "GAME OVER"

	var control_note := "Start: button / %s" % _action_hints(player.jump_action_name)
	if current_state == GameState.RUNNING:
		control_note = "Jump: %s | Esc: pause | Backspace: game over" % _action_hints(player.jump_action_name)
	elif current_state == GameState.PAUSED:
		control_note = "Resume: button / Esc | Restart: button"
	elif current_state == GameState.GAME_OVER:
		control_note = "Jump: restart | Restart: button"

	hud.update_state(state_text, control_note)
	hud.update_score(score)
	hud.update_distance(distance)


func _apply_scroll_speed() -> void:
	var speed_multiplier := _speed_down_multiplier
	if _speed_up_active:
		speed_multiplier = _speed_up_multiplier

	current_speed_multiplier = speed_multiplier
	chunks.set_scroll_speed(DEFAULT_SCROLL_SPEED * speed_multiplier)


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
