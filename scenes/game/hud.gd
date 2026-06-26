extends CanvasLayer
class_name GameHUD

@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var distance_label: Label = $MarginContainer/VBoxContainer/DistanceLabel
@onready var boost_timer_label: Label = $BoostTimerLabel
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var start_button: Button = $MainMenu/Panel/VBoxContainer/StartButton
@onready var resume_button: Button = $PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var pause_restart_button: Button = $PauseMenu/Panel/VBoxContainer/RestartButton
@onready var final_score_label: Label = $GameOverMenu/Panel/VBoxContainer/FinalScoreLabel
@onready var game_over_restart_button: Button = $GameOverMenu/Panel/VBoxContainer/RestartButton
@onready var best_score_label: Label = $GameOverMenu/Panel/VBoxContainer/BestScoreLabel
@onready var new_record_label: Label = $GameOverMenu/Panel/VBoxContainer/NewRecordLabel
@onready var name_input_container: HBoxContainer = $GameOverMenu/Panel/VBoxContainer/NameInputContainer
@onready var name_input: LineEdit = $GameOverMenu/Panel/VBoxContainer/NameInputContainer/NameInput
@onready var save_button: Button = $GameOverMenu/Panel/VBoxContainer/NameInputContainer/SaveButton

signal name_submitted(player_name: String)

var _boost_timer: float = 0.0
var _boost_active: bool = false
var _last_score: int = 0


func _ready() -> void:
	hide_menus()
	update_state("MENU", "Start: button / Space / Up")
	update_score(0)
	update_distance(0.0)
	show_main_menu()
	_refresh_boost_timer_display()
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.run_running.connect(_on_run_running)
	RunSignals.run_paused.connect(_on_run_paused)
	RunSignals.run_game_over.connect(_on_run_game_over)
	RunSignals.score_changed.connect(update_score)
	RunSignals.distance_changed.connect(update_distance)
	RunSignals.highscore_checked.connect(_on_highscore_checked)
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


func _on_run_booted() -> void:
	show_main_menu()
	update_state("MENU", "Start: button / Space / Up")


func _on_run_running() -> void:
	hide_menus()
	update_state("RUNNING", "Jump: Space / Up | Esc: pause | Backspace: game over")


func _on_run_paused() -> void:
	show_pause_menu()
	update_state("PAUSED", "Resume: button / Esc | Restart: button")


func _on_run_game_over() -> void:
	show_game_over(_last_score)
	update_state("GAME OVER", "Jump: restart | Restart: button")


func _on_highscore_checked(current_score: int, best_score: int, best_name: String, is_new_record: bool) -> void:
	if is_new_record:
		best_score_label.text = "Previous best: %s - %06d" % [best_name if not best_name.is_empty() else "---", best_score]
		new_record_label.show()
		name_input_container.show()
		name_input.text = ""
		name_input.grab_focus()
	else:
		best_score_label.text = "Best: %s - %06d" % [best_name if not best_name.is_empty() else "---", best_score]
		new_record_label.hide()
		name_input_container.hide()


func _on_save_pressed() -> void:
	_submit_name()


func _on_name_text_submitted(_text: String) -> void:
	_submit_name()


func _submit_name() -> void:
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		return
	name_submitted.emit(player_name)
	name_input_container.hide()
	new_record_label.text = "RECORD SAVED!"
