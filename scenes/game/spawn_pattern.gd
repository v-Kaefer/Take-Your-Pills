extends Resource
class_name SpawnPattern

@export var pattern_id: StringName = &"pattern"
@export var scenario_id: StringName = &"default"
@export var min_score: int = 0
@export var max_score: int = -1
@export_range(1, 10, 1) var weight: int = 1
@export_range(0, 10, 1) var difficulty: int = 0
@export var entries: Array = []


func matches(target_scenario_id: StringName, target_score: int) -> bool:
	if scenario_id != target_scenario_id:
		return false
	if target_score < min_score:
		return false
	if max_score >= 0 and target_score > max_score:
		return false
	return true
