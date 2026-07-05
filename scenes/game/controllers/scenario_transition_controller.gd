extends Node
class_name ScenarioTransitionController

@export var transition_score: int = 20000
@export var starting_scenario_id: StringName = &"laboratory"
@export var destination_scenario_id: StringName = &"default"

var chunks: ChunkManager = null
var _transition_done: bool = false


func _ready() -> void:
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.score_changed.connect(_on_score_changed)


func _on_run_booted() -> void:
	_transition_done = false
	if chunks != null:
		chunks.switch_to_scenario(starting_scenario_id)


func _on_score_changed(score: int) -> void:
	if _transition_done or score < transition_score:
		return

	_transition_done = true
	if chunks != null:
		chunks.switch_to_scenario(destination_scenario_id)

