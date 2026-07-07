extends Node

enum RunState { MAIN_MENU, RUNNING, PAUSED, GAME_OVER }

var player: Player = null
var chunks: ChunkManager = null
var default_scroll_speed: float = 220.0
var current_state: RunState = RunState.MAIN_MENU
var _speed_up_active: bool = false
var _speed_up_multiplier: float = 1.0
var _speed_down_multiplier: float = 1.0


func _ready() -> void:
	RunSignals.player_hit_obstacle.connect(_on_player_hit_obstacle)
	RunSignals.speed_too_slow.connect(_on_speed_too_slow)


func boot() -> void:
	current_state = RunState.MAIN_MENU
	_reset_scroll_speed_state()
	_apply_idle_run_state()
	RunSignals.run_booted.emit()


func start_run() -> bool:
	if current_state != RunState.MAIN_MENU:
		return false

	current_state = RunState.RUNNING
	if chunks != null:
		chunks.start_run()
	if player != null:
		player.start_run()
	_apply_scroll_speed()
	RunSignals.run_running.emit()
	return true


func resume_run() -> bool:
	if current_state != RunState.PAUSED:
		return false

	current_state = RunState.RUNNING
	if chunks != null:
		chunks.start_run()
	if player != null:
		player.start_run()
	_apply_scroll_speed()
	RunSignals.run_running.emit()
	return true


func pause_run() -> bool:
	if current_state != RunState.RUNNING:
		return false

	current_state = RunState.PAUSED
	if chunks != null:
		chunks.pause_run()
	if player != null:
		player.pause_run()
	RunSignals.run_paused.emit()
	return true


func toggle_pause() -> bool:
	if current_state == RunState.RUNNING:
		return pause_run()
	if current_state == RunState.PAUSED:
		return resume_run()

	return false


func end_run() -> bool:
	if current_state == RunState.GAME_OVER:
		return false

	current_state = RunState.GAME_OVER
	_reset_scroll_speed_state()
	if chunks != null:
		chunks.end_run()
	if player != null:
		player.end_run()
	RunSignals.run_game_over.emit()
	return true


func is_main_menu() -> bool:
	return current_state == RunState.MAIN_MENU


func is_running() -> bool:
	return current_state == RunState.RUNNING


func is_paused() -> bool:
	return current_state == RunState.PAUSED


func is_game_over() -> bool:
	return current_state == RunState.GAME_OVER


func on_speed_up_boost_state_changed(active: bool, _remaining: float, speed_multiplier: float) -> void:
	_speed_up_active = active
	_speed_up_multiplier = maxf(speed_multiplier, 0.0)
	_apply_scroll_speed()


func on_speed_down_state_changed(speed_multiplier: float) -> void:
	_speed_down_multiplier = maxf(speed_multiplier, 0.0)
	_apply_scroll_speed()


func set_base_scroll_speed(value: float) -> void:
	default_scroll_speed = maxf(value, 0.0)
	_apply_scroll_speed()


func _on_player_hit_obstacle(_obstacle: Node, _body: Node) -> void:
	if is_running():
		end_run()


func _on_speed_too_slow() -> void:
	if is_running():
		end_run()


func _apply_idle_run_state() -> void:
	if chunks != null:
		chunks.set_scroll_speed(default_scroll_speed)
		chunks.pause_run()
	if player != null:
		player.pause_run()


func _apply_scroll_speed() -> void:
	if chunks == null:
		return

	var speed_multiplier := _speed_down_multiplier
	if _speed_up_active:
		speed_multiplier = _speed_up_multiplier

	chunks.set_scroll_speed(default_scroll_speed * speed_multiplier)


func _reset_scroll_speed_state() -> void:
	_speed_up_active = false
	_speed_up_multiplier = 1.0
	_speed_down_multiplier = 1.0
	_apply_scroll_speed()
