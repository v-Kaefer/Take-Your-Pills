extends Node
class_name RunPacingController

var session_controller = null

var _opening_base_speed: float = 220.0
var _mid_base_speed: float = 235.0
var _transition_base_speed: float = 255.0
var _late_base_speed: float = 270.0
var _mid_score_threshold: int = 8000
var _transition_score_threshold: int = 20000
var _late_score_threshold: int = 32000


func _ready() -> void:
	_opening_base_speed = Balance.config.default_scroll_speed
	_mid_base_speed = Balance.config.mid_scroll_speed
	_transition_base_speed = Balance.config.transition_scroll_speed
	_late_base_speed = Balance.config.late_scroll_speed
	_mid_score_threshold = Balance.config.mid_score_threshold
	_transition_score_threshold = Balance.config.transition_score
	_late_score_threshold = Balance.config.late_score_threshold
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.score_changed.connect(_on_score_changed)


func _on_run_booted() -> void:
	_apply_curve_for_score(0)


func _on_score_changed(score: int) -> void:
	_apply_curve_for_score(score)


func _apply_curve_for_score(score: int) -> void:
	var base_scroll_speed := _opening_base_speed
	if score >= _late_score_threshold:
		base_scroll_speed = _late_base_speed
	elif score >= _transition_score_threshold:
		base_scroll_speed = _transition_base_speed
	elif score >= _mid_score_threshold:
		base_scroll_speed = _mid_base_speed

	if session_controller != null:
		session_controller.set_base_scroll_speed(base_scroll_speed)
