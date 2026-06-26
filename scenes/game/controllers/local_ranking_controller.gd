extends Node
class_name LocalRankingController

var _last_score: int = 0


func _ready() -> void:
	RunSignals.score_changed.connect(_on_score_changed)
	RunSignals.run_game_over.connect(_on_run_game_over)


func _on_score_changed(score: int) -> void:
	_last_score = score


func _on_run_game_over() -> void:
	var best_score := SaveManager.get_best_score()
	var best_name := SaveManager.get_best_name()
	var is_new := SaveManager.is_new_record(_last_score)
	RunSignals.highscore_checked.emit.call_deferred(_last_score, best_score, best_name, is_new)


func save_record(player_name: String) -> void:
	SaveManager.save_highscore(player_name, _last_score)
