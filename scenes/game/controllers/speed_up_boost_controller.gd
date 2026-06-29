extends Node
class_name SpeedUpBoostController

const SPEED_THRESHOLD: int = 3
const BOOST_DURATION: float = 8.0
const BOOST_TIMER_MULTIPLIER: float = 1.25
const BOOST_MULTIPLIERS: Array[float] = [1.0, 1.5, 2.0]

signal bar_step(charge: int)
signal bar_reset
signal boost_state_changed(active: bool, remaining: float, speed_multiplier: float)

var _speed_up_charge: int = 0
var _boost_active: bool = false
var _boost_tier: int = 0
var _boost_timer: float = 0.0
var _boost_max_timer: float = 0.0


func _ready() -> void:
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
	_speed_up_charge = clampi(_speed_up_charge + 1, 0, SPEED_THRESHOLD)
	if _speed_up_charge < SPEED_THRESHOLD:
		bar_step.emit(_speed_up_charge)
		return

	_speed_up_charge = 0
	bar_reset.emit()
	_apply_speed_up_stack()


func _apply_speed_up_stack() -> void:
	_boost_active = true
	_boost_tier = min(_boost_tier + 1, BOOST_MULTIPLIERS.size() - 1)

	if _boost_max_timer <= 0.0:
		_boost_max_timer = BOOST_DURATION
	else:
		_boost_max_timer *= BOOST_TIMER_MULTIPLIER

	_boost_timer = maxf(_boost_timer, _boost_max_timer)
	_emit_boost_state()


func _end_boost() -> void:
	_boost_active = false
	_boost_tier = 0
	_boost_timer = 0.0
	_boost_max_timer = 0.0
	_emit_boost_state()


func _reset_state() -> void:
	_speed_up_charge = 0
	_boost_active = false
	_boost_tier = 0
	_boost_timer = 0.0
	_boost_max_timer = 0.0
	bar_reset.emit()
	_emit_boost_state()


func _emit_boost_state() -> void:
	boost_state_changed.emit(_boost_active, _boost_timer, BOOST_MULTIPLIERS[min(_boost_tier, BOOST_MULTIPLIERS.size() - 1)])
