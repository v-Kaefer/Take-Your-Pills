extends Node

const SPEED_THRESHOLD: int = 3
const BOOST_DURATION: float = 8.0
const BOOST_MULTIPLIER: float = 1.5

var chunk_manager: ChunkManager = null
var base_speed: float = 240.0

var _speed_level: int = 0
var _boost_active: bool = false
var _boost_timer: float = 0.0


func _ready() -> void:
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.run_game_over.connect(_on_run_game_over)
	RunSignals.speed_up_collected.connect(_on_speed_up_collected)
	RunSignals.speed_down_collected.connect(_on_speed_down_collected)


func reset(base_speed_value: float) -> void:
	base_speed = base_speed_value
	_reset_state()


func tick(delta: float) -> void:
	if not _boost_active:
		return

	_boost_timer -= delta
	if _boost_timer <= 0.0:
		_end_boost()


func _on_run_booted() -> void:
	_reset_state()


func _on_run_game_over() -> void:
	_reset_state()


func _on_speed_up_collected() -> void:
	if _boost_active:
		return

	_speed_level = clampi(_speed_level + 1, -SPEED_THRESHOLD, SPEED_THRESHOLD)
	if _speed_level >= SPEED_THRESHOLD:
		_activate_boost()
		return

	_apply_current_speed()
	_emit_speed_state()


func _on_speed_down_collected() -> void:
	if _boost_active:
		return

	_speed_level = clampi(_speed_level - 1, -SPEED_THRESHOLD, SPEED_THRESHOLD)
	_apply_current_speed()
	_emit_speed_state()

	if _speed_level <= -SPEED_THRESHOLD:
		RunSignals.speed_too_slow.emit()


func _activate_boost() -> void:
	_boost_active = true
	_boost_timer = BOOST_DURATION
	_apply_current_speed()
	_emit_speed_state()


func _end_boost() -> void:
	_boost_active = false
	_boost_timer = 0.0
	_speed_level = 0
	_apply_current_speed()
	_emit_speed_state()


func _reset_state() -> void:
	_speed_level = 0
	_boost_active = false
	_boost_timer = 0.0
	_apply_current_speed()
	_emit_speed_state()


func _apply_current_speed() -> void:
	var speed := base_speed
	if _boost_active:
		speed = base_speed * BOOST_MULTIPLIER
	elif _speed_level < 0:
		speed = base_speed * maxf(0.0, 1.0 + (float(_speed_level) / float(SPEED_THRESHOLD)))

	if chunk_manager != null:
		chunk_manager.set_scroll_speed(speed)


func _emit_speed_state() -> void:
	RunSignals.speed_state_changed.emit(_speed_level, SPEED_THRESHOLD, _boost_active)
