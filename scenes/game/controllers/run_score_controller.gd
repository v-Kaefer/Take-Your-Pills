extends Node

const BASE_SCORE_PER_METER: float = 10.0
const SCORE_DISTANCE_DIVISOR: float = 10.0

var chunks: ChunkManager = null
var score: int = 0
var distance: float = 0.0

var _bonus_score: int = 0
var _score_accumulator: float = 0.0
var _last_displayed_distance: int = -1
var _running: bool = false


func _ready() -> void:
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.run_running.connect(_on_run_running)
	RunSignals.run_paused.connect(_on_run_paused)
	RunSignals.run_game_over.connect(_on_run_game_over)
	RunSignals.collectable_collected.connect(_on_collectable_collected)


func tick(delta: float) -> void:
	if not _running or chunks == null:
		return

	var meters_scrolled := (chunks.scroll_speed * delta) / SCORE_DISTANCE_DIVISOR
	distance += meters_scrolled
	_score_accumulator += meters_scrolled * BASE_SCORE_PER_METER

	var current_dist_int := int(distance)
	var new_score := int(_score_accumulator) + _bonus_score

	if new_score != score:
		score = new_score
		RunSignals.score_changed.emit(score)

	if current_dist_int != _last_displayed_distance:
		_last_displayed_distance = current_dist_int
		RunSignals.distance_changed.emit(distance)


func _on_run_booted() -> void:
	_reset_progress()


func _on_run_running() -> void:
	_running = true


func _on_run_paused() -> void:
	_running = false


func _on_run_game_over() -> void:
	_running = false


func _on_collectable_collected(_collectable: Node, _body: Node, score_value: int) -> void:
	if not _running:
		return

	_bonus_score += score_value
	var new_score := int(_score_accumulator) + _bonus_score
	if new_score != score:
		score = new_score
		RunSignals.score_changed.emit(score)


func _reset_progress() -> void:
	_running = false
	score = 0
	distance = 0.0
	_bonus_score = 0
	_score_accumulator = 0.0
	_last_displayed_distance = -1
	RunSignals.score_changed.emit(score)
	RunSignals.distance_changed.emit(distance)
