extends Node
class_name RunPacingController

@export var opening_base_speed: float = 220.0
@export var mid_base_speed: float = 235.0
@export var transition_base_speed: float = 255.0
@export var late_base_speed: float = 270.0
@export var mid_score_threshold: int = 8000
@export var transition_score_threshold: int = 20000
@export var late_score_threshold: int = 32000

var session_controller: Node = null
var current_base_scroll_speed: float = 0.0


func _ready() -> void:
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.score_changed.connect(_on_score_changed)


func _on_run_booted() -> void:
	_apply_curve_for_score(0, true)


func _on_score_changed(score: int) -> void:
	_apply_curve_for_score(score, false)


func _apply_curve_for_score(score: int, force_apply: bool) -> void:
	var target_speed := opening_base_speed
	if score >= late_score_threshold:
		target_speed = late_base_speed
	elif score >= transition_score_threshold:
		target_speed = transition_base_speed
	elif score >= mid_score_threshold:
		target_speed = mid_base_speed

	if not force_apply and is_equal_approx(current_base_scroll_speed, target_speed):
		return

	current_base_scroll_speed = target_speed
	if session_controller != null:
		session_controller.call("set_base_scroll_speed", current_base_scroll_speed)
