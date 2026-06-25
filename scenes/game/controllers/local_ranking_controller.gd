extends Node

var score_controller = null


func _ready() -> void:
	RunSignals.run_game_over.connect(_on_run_game_over)


func _on_run_game_over() -> void:
	if score_controller == null:
		return
	var final_score: int = score_controller.score
	var final_distance: int = int(score_controller.distance)
	var position := SaveManager.add_entry(final_score, final_distance)
	var entry := {
		"score": final_score,
		"distance": final_distance,
	}
	RunSignals.ranking_entry_added.emit(position, entry)
	RunSignals.ranking_updated.emit()
