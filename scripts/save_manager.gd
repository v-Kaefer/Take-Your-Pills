extends Node

const RANKING_PATH := "user://ranking.json"
const MAX_RANKING_ENTRIES := 10
const MAX_NAME_LENGTH := 5

var _ranking: Array[Dictionary] = []


func _ready() -> void:
	load_ranking()


func get_ranking() -> Array[Dictionary]:
	return _ranking.duplicate(true)


func get_best_entry() -> Dictionary:
	if _ranking.is_empty():
		return {}

	return _ranking[0].duplicate(true)


func is_new_highscore(score: int) -> bool:
	if _ranking.is_empty():
		return true

	return score > int(_ranking[0].get("score", 0))


func add_entry(score: int, distance: int) -> int:
	var entry := {
		"score": score,
		"distance": distance,
		"date": Time.get_datetime_string_from_system(false, true),
		"name": "",
	}
	_ranking.append(entry)
	_sort_ranking()
	var position := _ranking.find(entry)
	if _ranking.size() > MAX_RANKING_ENTRIES:
		_ranking.resize(MAX_RANKING_ENTRIES)
	if position >= MAX_RANKING_ENTRIES:
		return -1
	save_ranking()
	return position


func update_entry_name(position: int, player_name: String) -> bool:
	if position < 0 or position >= _ranking.size():
		return false

	var trimmed := player_name.strip_edges().left(MAX_NAME_LENGTH)
	if trimmed.is_empty():
		return false

	_ranking[position]["name"] = trimmed
	save_ranking()
	return true


func save_ranking() -> void:
	var file := FileAccess.open(RANKING_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_ranking, "\t"))


func load_ranking() -> void:
	if not FileAccess.file_exists(RANKING_PATH):
		_ranking = []
		return
	var file := FileAccess.open(RANKING_PATH, FileAccess.READ)
	if file == null:
		_ranking = []
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		_ranking = []
		return
	if json.data is Array:
		_ranking = []
		for item in json.data:
			if item is Dictionary and item.has("score") and item.has("distance") and item.has("date"):
				_ranking.append({
					"score": int(item["score"]),
					"distance": int(item["distance"]),
					"date": str(item["date"]),
					"name": str(item.get("name", "")).left(MAX_NAME_LENGTH),
				})
		_sort_ranking()
		if _ranking.size() > MAX_RANKING_ENTRIES:
			_ranking.resize(MAX_RANKING_ENTRIES)
	else:
		_ranking = []


func _sort_ranking() -> void:
	_ranking.sort_custom(_compare_entries)


static func _compare_entries(a: Dictionary, b: Dictionary) -> bool:
	if a["score"] != b["score"]:
		return a["score"] > b["score"]
	if a["distance"] != b["distance"]:
		return a["distance"] > b["distance"]
	return a["date"] < b["date"]
