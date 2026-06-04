extends Node

enum RunState { MAIN_MENU, RUNNING, PAUSED, GAME_OVER }

var player: Player = null
var chunks: ChunkManager = null
var default_scroll_speed: float = 240.0
var current_state: RunState = RunState.MAIN_MENU


func _ready() -> void:
	RunSignals.player_hit_obstacle.connect(_on_player_hit_obstacle)
	RunSignals.speed_too_slow.connect(_on_speed_too_slow)


func boot() -> void:
	current_state = RunState.MAIN_MENU
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
