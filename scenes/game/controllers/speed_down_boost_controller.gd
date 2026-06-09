extends Node
class_name SpeedDownBoostController

const SPEED_THRESHOLD: int = 3
const SLOW_SPEED_MULTIPLIERS: Array[float] = [1.0, 0.75, 0.5]

signal bar_step(charge: int)
signal bar_reset
signal slow_state_changed(speed_multiplier: float)
signal speed_too_slow

var _speed_down_charge: int = 0
var _slow_state: int = 0
var _boost_active: bool = false
var _queued_slow_steps: int = 0


func _ready() -> void:
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.run_game_over.connect(_on_run_game_over)
	RunSignals.speed_down_collected.connect(_on_speed_down_collected)


func on_speed_up_boost_state_changed(active: bool, _remaining: float, _speed_multiplier: float) -> void:
	var was_active := _boost_active
	_boost_active = active

	if was_active and not _boost_active:
		_flush_queued_slow_steps()


func _on_run_booted() -> void:
	_reset_state()


func _on_run_game_over() -> void:
	_reset_state()


func _on_speed_down_collected() -> void:
	_speed_down_charge = clampi(_speed_down_charge + 1, 0, SPEED_THRESHOLD)
	if _speed_down_charge < SPEED_THRESHOLD:
		bar_step.emit(_speed_down_charge)
		return

	_speed_down_charge = 0
	bar_reset.emit()

	if _boost_active:
		_queued_slow_steps += 1
		return

	if _apply_speed_down_step():
		return

	_emit_slow_state()


func _flush_queued_slow_steps() -> void:
	if _queued_slow_steps <= 0:
		return

	var queued_steps := _queued_slow_steps
	_queued_slow_steps = 0

	for _step in range(queued_steps):
		if _apply_speed_down_step():
			return


func _apply_speed_down_step() -> bool:
	if _slow_state >= SLOW_SPEED_MULTIPLIERS.size() - 1:
		speed_too_slow.emit()
		return true

	_slow_state += 1
	_emit_slow_state()
	return false


func _reset_state() -> void:
	_speed_down_charge = 0
	_slow_state = 0
	_boost_active = false
	_queued_slow_steps = 0
	bar_reset.emit()
	_emit_slow_state()


func _emit_slow_state() -> void:
	slow_state_changed.emit(SLOW_SPEED_MULTIPLIERS[min(_slow_state, SLOW_SPEED_MULTIPLIERS.size() - 1)])
