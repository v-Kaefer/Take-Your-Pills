extends Node

const SAVE_PATH := "user://highscore.cfg"
const MAX_NAME_LENGTH := 5

var _best_name: String = ""
var _best_score: int = 0


func _ready() -> void:
	_load()


func get_best_score() -> int:
	return _best_score


func get_best_name() -> String:
	return _best_name


func is_new_record(score: int) -> bool:
	return score > _best_score


func save_highscore(player_name: String, score: int) -> void:
	if player_name.is_empty():
		return
	var trimmed := player_name.left(MAX_NAME_LENGTH)
	_best_name = trimmed
	_best_score = score
	var config := ConfigFile.new()
	config.set_value("highscore", "name", _best_name)
	config.set_value("highscore", "score", _best_score)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	_best_name = config.get_value("highscore", "name", "")
	_best_score = config.get_value("highscore", "score", 0)
