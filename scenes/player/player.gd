extends CharacterBody2D
class_name Player

@export var base_run_speed: float = 240.0
@export var primary_action_name: StringName = &"player_primary"

enum RunState { RUNNING, PAUSED, DEAD }

signal primary_action_requested

var current_state: RunState = RunState.PAUSED
var run_speed: float = 240.0


func _ready() -> void:
	run_speed = base_run_speed


func start_run() -> void:
	current_state = RunState.RUNNING


func pause_run() -> void:
	current_state = RunState.PAUSED
	velocity.x = 0.0


func end_run() -> void:
	current_state = RunState.DEAD
	velocity.x = 0.0


func request_primary_action() -> bool:
	if current_state != RunState.RUNNING:
		return false

	primary_action_requested.emit()
	return true


func set_run_speed(value: float) -> void:
	run_speed = maxf(value, 0.0)


func _physics_process(_delta: float) -> void:
	if current_state == RunState.RUNNING:
		velocity.x = run_speed
	else:
		velocity.x = 0.0

	move_and_slide()
