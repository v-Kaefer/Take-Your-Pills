extends Control

const EMPTY_NAME_PLACEHOLDER := "---"

@onready var ranking_list: VBoxContainer = $Panel/VBoxContainer/RankingList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var _highlight_position: int = -1


func _ready() -> void:
	RunSignals.ranking_updated.connect(_refresh)
	close_button.pressed.connect(_on_close_pressed)
	hide()


func show_ranking(highlight_pos: int = -1) -> void:
	_highlight_position = highlight_pos
	_refresh()
	show()


func _refresh() -> void:
	for child in ranking_list.get_children():
		child.queue_free()

	var entries := SaveManager.get_ranking()
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Sem recordes ainda. Jogue uma partida!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ranking_list.add_child(empty_label)
		return

	for i in entries.size():
		var entry: Dictionary = entries[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var pos_label := Label.new()
		pos_label.text = "#%d" % (i + 1)
		pos_label.custom_minimum_size.x = 36

		var name_label := Label.new()
		name_label.text = _format_name(entry.get("name", ""))
		name_label.custom_minimum_size.x = 56

		var score_label := Label.new()
		score_label.text = "%06d" % entry["score"]
		score_label.custom_minimum_size.x = 72

		var dist_label := Label.new()
		dist_label.text = "%dm" % entry["distance"]
		dist_label.custom_minimum_size.x = 56

		var date_label := Label.new()
		date_label.text = _format_date(entry.get("date", ""))
		date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		row.add_child(pos_label)
		row.add_child(name_label)
		row.add_child(score_label)
		row.add_child(dist_label)
		row.add_child(date_label)

		if i == _highlight_position:
			var gold := Color(1.0, 0.85, 0.0)
			pos_label.add_theme_color_override("font_color", gold)
			name_label.add_theme_color_override("font_color", gold)
			score_label.add_theme_color_override("font_color", gold)
			dist_label.add_theme_color_override("font_color", gold)
			date_label.add_theme_color_override("font_color", gold)

		ranking_list.add_child(row)


func _format_date(iso_date: String) -> String:
	if iso_date.length() >= 16:
		var day := iso_date.substr(8, 2)
		var month := iso_date.substr(5, 2)
		var time_str := iso_date.substr(11, 5)
		return "%s/%s %s" % [day, month, time_str]
	return iso_date


func _format_name(player_name: Variant) -> String:
	var trimmed := str(player_name).strip_edges()
	if trimmed.is_empty():
		return EMPTY_NAME_PLACEHOLDER
	return trimmed


func _on_close_pressed() -> void:
	hide()
