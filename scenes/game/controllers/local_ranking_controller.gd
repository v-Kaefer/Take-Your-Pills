extends Node
class_name LocalRankingController

var score_controller = null
var _pending_highscore_position := -1


func _ready() -> void:
	RunSignals.run_game_over.connect(_on_run_game_over)


func _on_run_game_over() -> void:
	if score_controller == null:
		return

	var final_score: int = score_controller.score
	var final_distance: int = int(score_controller.distance)
	var should_prompt_name := SaveManager.is_new_highscore(final_score)
	var position := SaveManager.add_entry(final_score, final_distance)
	var entry := {
		"score": final_score,
		"distance": final_distance,
		"name": "",
	}

	_pending_highscore_position = -1
	RunSignals.ranking_entry_added.emit(position, entry)
	RunSignals.ranking_updated.emit()

	if should_prompt_name and position >= 0:
		_pending_highscore_position = position
		RunSignals.highscore_name_requested.emit(position, final_score)


func save_record(player_name: String) -> void:
	if not SaveManager.update_entry_name(_pending_highscore_position, player_name):
		return

	_pending_highscore_position = -1
	RunSignals.ranking_updated.emit()
