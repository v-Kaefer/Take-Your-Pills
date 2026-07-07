extends CanvasLayer
class_name GameHUD

signal name_submitted(player_name: String)

@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var distance_label: Label = $MarginContainer/VBoxContainer/DistanceLabel
@onready var scenario_label: Label = $MarginContainer/VBoxContainer/ScenarioLabel
@onready var boost_timer_label: Label = $BoostTimerLabel
@onready var slow_timer_label: Label = $SlowTimerLabel
@onready var defeat_flash: ColorRect = $DefeatFlash
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var start_button: Button = $MainMenu/Panel/VBoxContainer/StartButton
@onready var menu_highscore_label: Label = $MainMenu/Panel/VBoxContainer/HighscoreLabel
@onready var resume_button: Button = $PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var pause_restart_button: Button = $PauseMenu/Panel/VBoxContainer/RestartButton
@onready var final_score_label: Label = $GameOverMenu/Panel/VBoxContainer/FinalScoreLabel
@onready var new_record_label: Label = $GameOverMenu/Panel/VBoxContainer/NewRecordLabel
@onready var game_over_restart_button: Button = $GameOverMenu/Panel/VBoxContainer/RestartButton
@onready var name_prompt_label: Label = $GameOverMenu/Panel/VBoxContainer/NamePromptLabel
@onready var name_input_container: HBoxContainer = $GameOverMenu/Panel/VBoxContainer/NameInputContainer
@onready var name_input: LineEdit = $GameOverMenu/Panel/VBoxContainer/NameInputContainer/NameInput
@onready var save_button: Button = $GameOverMenu/Panel/VBoxContainer/NameInputContainer/SaveButton
@onready var main_menu_ranking_button: Button = $MainMenu/Panel/VBoxContainer/RankingButton
@onready var game_over_ranking_button: Button = $GameOverMenu/Panel/VBoxContainer/RankingButton
@onready var local_ranking_menu: Control = $LocalRankingMenu

var _boost_timer: float = 0.0
var _boost_active: bool = false
var _slow_active: bool = false
var _last_score: int = 0
var _last_ranking_position: int = -1
var _pickup_flash_tween: Tween = null
var _slow_flash_tween: Tween = null
var _defeat_flash_tween: Tween = null


func _ready() -> void:
	hide_menus()
	update_state("MENU", "Start: button / Space / Up")
	update_score(0)
	update_distance(0.0)
	_on_scenario_changed(&"laboratory")
	show_main_menu()
	_refresh_boost_timer_display()
	update_slow_state(1.0)
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.run_running.connect(_on_run_running)
	RunSignals.run_paused.connect(_on_run_paused)
	RunSignals.run_game_over.connect(_on_run_game_over)
	RunSignals.score_changed.connect(update_score)
	RunSignals.distance_changed.connect(update_distance)
	RunSignals.collectable_collected.connect(_on_collectable_collected)
	RunSignals.scenario_changed.connect(_on_scenario_changed)
	RunSignals.ranking_entry_added.connect(_on_ranking_entry_added)
	RunSignals.ranking_updated.connect(_refresh_menu_highscore)
	RunSignals.highscore_name_requested.connect(_on_highscore_name_requested)
	main_menu_ranking_button.pressed.connect(_on_main_menu_ranking_pressed)
	game_over_ranking_button.pressed.connect(_on_game_over_ranking_pressed)
	save_button.pressed.connect(_on_save_pressed)
	name_input.text_submitted.connect(_on_name_text_submitted)


func update_state(state_text: String, control_note: String, extra_note: String = "") -> void:
	if extra_note.is_empty():
		state_label.text = "State: %s\nControls: %s" % [state_text, control_note]
	else:
		state_label.text = "State: %s\nNote: %s\nControls: %s" % [state_text, extra_note, control_note]


func update_score(score: int) -> void:
	_last_score = score
	score_label.text = "Score: %06d" % score


func update_distance(distance: float) -> void:
	distance_label.text = "Distance: %d m" % int(distance)


func show_main_menu() -> void:
	hide_menus()
	_refresh_menu_highscore()
	main_menu.show()


func show_pause_menu() -> void:
	hide_menus()
	pause_menu.show()


func show_game_over(score: int) -> void:
	hide_menus()
	final_score_label.text = "Final score: %06d" % score
	game_over_menu.show()


func hide_menus() -> void:
	main_menu.hide()
	pause_menu.hide()
	game_over_menu.hide()


func connect_start(callable: Callable) -> void:
	start_button.pressed.connect(callable)


func connect_resume(callable: Callable) -> void:
	resume_button.pressed.connect(callable)


func connect_restart(callable: Callable) -> void:
	pause_restart_button.pressed.connect(callable)
	game_over_restart_button.pressed.connect(callable)


func update_boost_timer(boost_active: bool, boost_timer: float, _speed_multiplier: float) -> void:
	_boost_timer = boost_timer
	_boost_active = boost_active
	_refresh_boost_timer_display()


func _refresh_boost_timer_display() -> void:
	if _boost_active and _boost_timer > 0.0:
		boost_timer_label.visible = true
		boost_timer_label.text = "Boost: %.1fs" % maxf(0.0, _boost_timer)
	else:
		boost_timer_label.visible = false
		boost_timer_label.text = ""


func update_slow_state(speed_multiplier: float) -> void:
	var is_slow := speed_multiplier < 1.0
	if is_slow:
		slow_timer_label.visible = true
		slow_timer_label.text = "Slow: x%.2f" % speed_multiplier
	else:
		slow_timer_label.visible = false
		slow_timer_label.text = ""

	# Only pulse when the run just entered (or deepened) a slowdown, so the
	# adverse event is reinforced without looping while the state persists.
	if is_slow and not _slow_active:
		_flash_slow_feedback()
	_slow_active = is_slow


func _flash_slow_feedback() -> void:
	if _slow_flash_tween != null and _slow_flash_tween.is_valid():
		_slow_flash_tween.kill()

	var warn_color := Color(1.0, 0.42, 0.2, 1.0)
	distance_label.modulate = warn_color
	slow_timer_label.modulate = warn_color
	_slow_flash_tween = create_tween()
	_slow_flash_tween.set_parallel(true)
	_slow_flash_tween.tween_property(distance_label, "modulate", Color.WHITE, 0.18)
	_slow_flash_tween.tween_property(slow_timer_label, "modulate", Color.WHITE, 0.18)


func _flash_defeat_feedback() -> void:
	if _defeat_flash_tween != null and _defeat_flash_tween.is_valid():
		_defeat_flash_tween.kill()

	defeat_flash.color = Color(0.85, 0.12, 0.12, 0.42)
	_defeat_flash_tween = create_tween()
	_defeat_flash_tween.tween_property(defeat_flash, "color:a", 0.0, 0.24)


func _on_run_booted() -> void:
	show_main_menu()
	update_state("MENU", "Start: button / Space / Up")


func _on_run_running() -> void:
	hide_menus()
	_last_ranking_position = -1
	new_record_label.hide()
	name_prompt_label.hide()
	name_input_container.hide()
	name_input.text = ""
	name_input.release_focus()
	update_slow_state(1.0)
	update_state("RUNNING", "Jump: Space / Up | Esc: pause | Backspace: game over")


func _on_run_paused() -> void:
	show_pause_menu()
	update_state("PAUSED", "Resume: button / Esc | Restart: button")


func _on_run_game_over() -> void:
	update_slow_state(1.0)
	_flash_defeat_feedback()
	show_game_over(_last_score)
	update_state("GAME OVER", "Jump: restart | Restart: button")


func _on_ranking_entry_added(position: int, _entry: Dictionary) -> void:
	_last_ranking_position = position
	if position >= 0 and position < SaveManager.MAX_RANKING_ENTRIES:
		new_record_label.text = "Novo Recorde! #%d" % (position + 1)
		new_record_label.show()


func _on_collectable_collected(_collectable: Node, _body: Node, _score_value: int) -> void:
	_flash_pickup_feedback()


func _flash_pickup_feedback() -> void:
	if _pickup_flash_tween != null and _pickup_flash_tween.is_valid():
		_pickup_flash_tween.kill()

	var flash_color := Color(1.0, 0.92, 0.55, 1.0)
	score_label.modulate = flash_color
	distance_label.modulate = flash_color
	_pickup_flash_tween = create_tween()
	_pickup_flash_tween.set_parallel(true)
	_pickup_flash_tween.tween_property(score_label, "modulate", Color.WHITE, 0.12)
	_pickup_flash_tween.tween_property(distance_label, "modulate", Color.WHITE, 0.12)


func _on_scenario_changed(scenario_id: StringName) -> void:
	if scenario_id == &"laboratory":
		scenario_label.text = "Scenario: LAB SECTOR"
		scenario_label.add_theme_color_override("font_color", Color(0.34, 0.84, 0.93, 1.0))
		return

	scenario_label.text = "Scenario: CITY LOOP"
	scenario_label.add_theme_color_override("font_color", Color(0.95, 0.76, 0.26, 1.0))


func _on_highscore_name_requested(_position: int, _score: int) -> void:
	name_prompt_label.text = "Name (max 5):"
	name_prompt_label.show()
	name_input_container.show()
	name_input.text = ""


func _on_save_pressed() -> void:
	_submit_name()


func _on_name_text_submitted(_text: String) -> void:
	_submit_name()


func _submit_name() -> void:
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		return

	name_submitted.emit(player_name)
	name_input.text = ""
	name_input.release_focus()
	name_input_container.hide()
	name_prompt_label.hide()


func _refresh_menu_highscore() -> void:
	var best_entry := SaveManager.get_best_entry()
	if best_entry.is_empty():
		menu_highscore_label.text = ""
		return

	var best_score := int(best_entry.get("score", 0))
	var best_name := str(best_entry.get("name", "")).strip_edges()
	if best_name.is_empty():
		best_name = "---"

	menu_highscore_label.text = "Best: %s - %06d" % [best_name, best_score]


func _on_main_menu_ranking_pressed() -> void:
	local_ranking_menu.show_ranking(-1)


func _on_game_over_ranking_pressed() -> void:
	local_ranking_menu.show_ranking(_last_ranking_position)
