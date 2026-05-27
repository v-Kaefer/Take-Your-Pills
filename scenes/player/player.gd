extends CharacterBody2D
class_name Player

@export var jump_action_name: StringName = &"player_jump"
@export var jump_velocity: float = -420.0
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 1200.0
@export var ground_snap_length: float = 8.0

enum RunState { RUNNING, PAUSED, DEAD }

var current_state: RunState = RunState.PAUSED
var _jump_requested: bool = false
var _grounded: bool = true


func _ready() -> void:
	floor_snap_length = ground_snap_length


func start_run() -> void:
	current_state = RunState.RUNNING


func pause_run() -> void:
	current_state = RunState.PAUSED
	velocity.x = 0.0
	_jump_requested = false


func end_run() -> void:
	current_state = RunState.DEAD
	velocity.x = 0.0
	_jump_requested = false


func request_jump() -> bool:
	if current_state != RunState.RUNNING:
		return false

	_jump_requested = true
	return true


func _physics_process(_delta: float) -> void:
	if current_state != RunState.RUNNING:
		return

	velocity.x = 0.0

	if _jump_requested and _grounded:
		velocity.y = jump_velocity
		_grounded = false
	elif not _grounded:
		velocity.y = minf(velocity.y + (gravity * _delta), max_fall_speed)
	elif velocity.y > 0.0:
		velocity.y = 0.0

	move_and_slide()

	_grounded = is_on_floor()
	if _grounded and velocity.y > 0.0:
		velocity.y = 0.0

	_jump_requested = false
