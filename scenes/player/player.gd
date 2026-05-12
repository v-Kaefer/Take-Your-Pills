extends CharacterBody2D
class_name Player

@export var primary_action_name: StringName = &"player_primary"

enum RunState { RUNNING, PAUSED, DEAD }

signal primary_action_requested

var current_state: RunState = RunState.PAUSED


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


func _physics_process(_delta: float) -> void:
	velocity.x = 0.0
	move_and_slide()
