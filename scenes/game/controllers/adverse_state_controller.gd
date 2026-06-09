extends Node

const SPEED_THRESHOLD: int = 3
const BOOST_DURATION: float = 8.0
const BOOST_MULTIPLIER: float = 1.5
const SLOW_SPEED_MULTIPLIERS: Array[float] = [1.0, 0.75, 0.5]

var chunk_manager: ChunkManager = null
var base_speed: float = 240.0

var _speed_up_charge: int = 0
var _speed_down_charge: int = 0
var _slow_state: int = 0
var _boost_active: bool = false
var _boost_timer: float = 0.0
# Slowdowns completed during a boost wait here until the boost expires.
var _queued_slow_steps: int = 0


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
	_speed_up_charge = clampi(_speed_up_charge + 1, 0, SPEED_THRESHOLD)
	if _speed_up_charge < SPEED_THRESHOLD:
		_emit_speed_state()
		return

	_speed_up_charge = 0
	_boost_active = true
	_boost_timer = BOOST_DURATION
	_apply_current_speed()
	_emit_speed_state()


func _on_speed_down_collected() -> void:
	_speed_down_charge = clampi(_speed_down_charge + 1, 0, SPEED_THRESHOLD)
	if _speed_down_charge < SPEED_THRESHOLD:
		_emit_speed_state()
		return

	_speed_down_charge = 0
	if _boost_active:
		_queued_slow_steps += 1
		_emit_speed_state()
		return

	if _apply_speed_down_step():
		return

	_emit_speed_state()


func _end_boost() -> void:
	_boost_active = false
	_boost_timer = 0.0

	if _queued_slow_steps > 0:
		var queued_steps := _queued_slow_steps
		_queued_slow_steps = 0
		for _step in range(queued_steps):
			if _apply_speed_down_step():
				return
		_emit_speed_state()
		return

	_apply_current_speed()
	_emit_speed_state()


func _reset_state() -> void:
	_speed_up_charge = 0
	_speed_down_charge = 0
	_slow_state = 0
	_boost_active = false
	_boost_timer = 0.0
	_queued_slow_steps = 0
	_apply_current_speed()
	_emit_speed_state()


func _apply_speed_down_step() -> bool:
	if _slow_state >= SLOW_SPEED_MULTIPLIERS.size() - 1:
		RunSignals.speed_too_slow.emit()
		return true

	_slow_state += 1
	_apply_current_speed()
	return false


func _apply_current_speed() -> void:
	var speed := base_speed * SLOW_SPEED_MULTIPLIERS[min(_slow_state, SLOW_SPEED_MULTIPLIERS.size() - 1)]
	if _boost_active:
		speed = base_speed * BOOST_MULTIPLIER

	if chunk_manager != null:
		chunk_manager.set_scroll_speed(speed)


func _emit_speed_state() -> void:
	RunSignals.speed_state_changed.emit(_speed_up_charge, _speed_down_charge, SPEED_THRESHOLD, _boost_active)
