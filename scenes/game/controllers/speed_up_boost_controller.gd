extends Node
class_name SpeedUpBoostController

signal bar_step(charge: int)
signal bar_reset
signal boost_state_changed(active: bool, remaining: float, speed_multiplier: float)

var _speed_threshold: int = 3
var _boost_duration: float = 8.0
var _boost_timer_multiplier: float = 1.25
var _boost_multipliers: Array[float] = [1.0, 1.35, 1.6]
var _boost_stack_decay: float = 0.75

var _speed_up_charge: int = 0
var _boost_active: bool = false
var _boost_stacks: int = 0
var _boost_timer: float = 0.0
var _boost_max_timer: float = 0.0


func _ready() -> void:
	_speed_threshold = Balance.config.speed_up_threshold
	_boost_duration = Balance.config.speed_up_boost_duration
	_boost_timer_multiplier = Balance.config.speed_up_timer_multiplier
	_boost_multipliers = Balance.config.speed_up_multipliers
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.run_game_over.connect(_on_run_game_over)
	RunSignals.speed_up_collected.connect(_on_speed_up_collected)


func tick(delta: float) -> void:
	if not _boost_active:
		return

	_boost_timer -= delta
	if _boost_timer <= 0.0:
		_end_boost()
		return

	_emit_boost_state()


func _on_run_booted() -> void:
	_reset_state()


func _on_run_game_over() -> void:
	_reset_state()


func _on_speed_up_collected() -> void:
	_speed_up_charge = clampi(_speed_up_charge + 1, 0, _speed_threshold)
	if _speed_up_charge < _speed_threshold:
		bar_step.emit(_speed_up_charge)
		return

	_speed_up_charge = 0
	bar_reset.emit()
	_apply_speed_up_stack()


func _apply_speed_up_stack() -> void:
	_boost_active = true
	_boost_stacks += 1

	if _boost_max_timer <= 0.0:
		_boost_max_timer = _boost_duration
	else:
		_boost_max_timer *= _boost_timer_multiplier

	_boost_timer = maxf(_boost_timer, _boost_max_timer)
	_emit_boost_state()


func _end_boost() -> void:
	_boost_active = false
	_boost_stacks = 0
	_boost_timer = 0.0
	_boost_max_timer = 0.0
	_emit_boost_state()


func _reset_state() -> void:
	_speed_up_charge = 0
	_boost_active = false
	_boost_stacks = 0
	_boost_timer = 0.0
	_boost_max_timer = 0.0
	bar_reset.emit()
	_emit_boost_state()


func _emit_boost_state() -> void:
	boost_state_changed.emit(_boost_active, _boost_timer, _get_speed_multiplier_for_stacks(_boost_stacks))


func _get_speed_multiplier_for_stacks(boost_stacks: int) -> float:
	if _boost_multipliers.is_empty():
		return 1.0

	if boost_stacks < _boost_multipliers.size():
		return maxf(_boost_multipliers[boost_stacks], 1.0)

	var last_index := _boost_multipliers.size() - 1
	var multiplier := maxf(_boost_multipliers[last_index], 1.0)
	var previous := 1.0
	if last_index > 0:
		previous = maxf(_boost_multipliers[last_index - 1], 1.0)

	var increment := multiplier - previous
	for _stack_index in range(last_index + 1, boost_stacks + 1):
		increment *= _boost_stack_decay
		multiplier += increment

	return multiplier
